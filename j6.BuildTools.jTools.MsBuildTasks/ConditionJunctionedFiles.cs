using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace j6.BuildTools.MsBuildTasks
{
    public class ConditionJunctionedFiles : Task
    {
        [Required]
        public string ProjectFile { get; set; }

        public string WorkingDirectory { get; set; }

        public bool CaseSensitivePaths { get; set; }

        private Dictionary<DirectoryInfo, DirectoryInfo> _preferredJunctions;

        public string[] PreferredJunctions { get; set; }

        private bool HasErrors { get; set; }
        
        private StringComparer Comparer { get { return CaseSensitivePaths ? StringComparer.InvariantCulture : StringComparer.InvariantCultureIgnoreCase; } }
        private StringComparison Comparison { get { return CaseSensitivePaths ? StringComparison.InvariantCulture : StringComparison.InvariantCultureIgnoreCase; } }

        private Dictionary<DirectoryInfo, DirectoryInfo> GetPreferredJunctions(DirectoryInfo deepestRoot)
        {
            if (_preferredJunctions != null)
                return _preferredJunctions;

            var newPreferred =
                new DirectoryInfo(WorkingDirectory ?? Environment.CurrentDirectory).GetDirectories()
                                                                                   .Where(
                                                                                       d =>
                                                                                       d.Attributes.HasFlag(
                                                                                           FileAttributes
                                                                                               .ReparsePoint))
                                                                                   .Select(f => f.FullName)
                                                                                   .ToDictionary(f =>
                                                                                                 GetActualLocation(
                                                                                                     new DirectoryInfo(f),
                                                                                                     deepestRoot),
                                                                                                     f => new DirectoryInfo(f));
            return _preferredJunctions = newPreferred;
        }
        public override bool Execute()
        {
            var projectFile = File.Exists(ProjectFile) ? new FileInfo(ProjectFile) : new FileInfo(Path.Combine(WorkingDirectory, ProjectFile));
            if (!projectFile.Exists)
            {
                throw new FileNotFoundException("File not found", ProjectFile);
            }

            var projectDirectory = projectFile.Directory;

            if (projectDirectory == null || !projectDirectory.Exists)
                throw new DirectoryNotFoundException(string.Format("Directory not found: {0}", projectFile.DirectoryName));

            XDocument projectDocument;
            using (var inputStream = projectFile.OpenRead())
                projectDocument = XDocument.Load(inputStream);

            if (projectDocument.Root == null)
                throw new FieldAccessException(string.Format("Can't read root of file {0}", projectFile.FullName));

            var defaultNamespace = projectDocument.Root.GetDefaultNamespace();

            var allItemGroups = projectDocument.Root.Elements()
                                               .Where(
                                                   e =>
                                                   e.Name.LocalName.Equals("ItemGroup",
                                                                           Comparison))
                                               .Select(
                                                   e =>
                                                   new
                                                   {
                                                       itemGroup = e,
                                                       Condition =
                                                   e.Attributes()
                                                    .Where(
                                                        a =>
                                                        a.Name.LocalName.Equals("Condition",
                                                                                StringComparison
                                                                                    .InvariantCultureIgnoreCase))
                                                    .Select(a => a.Value)
                                                    .SingleOrDefault()
                                                   }).ToArray();

            var firstItemGroup = allItemGroups.Select(ig => ig.itemGroup).FirstOrDefault();

            var itemGroups =
                allItemGroups.Where(e => e.Condition == null).Select(e => e.itemGroup).ToArray();

            var conditionalItemGroups = allItemGroups.Where(e => e.Condition != null).ToList();

            var contentNames = new[] {"Compile", "Content", "None"};
            var contentAndProjectReferenceNames = contentNames.Union(new [] { "ProjectReference" });
            var referenceNames = new[] {"Reference"};
            
            var elements =
                itemGroups.Elements()
                .Select(e => new { ElementType = contentAndProjectReferenceNames.Contains(e.Name.LocalName, Comparer) ? ElementType.Content : referenceNames.Contains(e.Name.LocalName, Comparer) ? ElementType.Reference : ElementType.Other, Element = e})
                          .Where(e => e.ElementType != ElementType.Other && !e.Element.Attributes().Any(a => a.Name.LocalName.Equals("Condition", Comparison)) )
                          .Select(e => new
                          {
                              Key = e.ElementType == ElementType.Content 
                              ? e.Element.Attributes().Select(a => new { Name = a.Name.LocalName, a.Value })
                                  .Where(a => a.Name.Equals("Include", Comparison)).Select(a => a.Value).SingleOrDefault()
                              : e.Element.Elements().Select(a => new { Name = a.Name.LocalName, a.Value })
                                   .Where(a => a.Name.Equals("HintPath", Comparison)).Select(a => a.Value).SingleOrDefault(),
                              Element = e
                          })
                          .Where(e => !string.IsNullOrWhiteSpace(e.Key))
                          .Select(e => new { Key = ResolvePath(projectDirectory.FullName, e.Key), e.Element.Element })
                          .GroupBy(e => e.Key, Comparer)
                          .ToDictionary(e => e.Key, e => e.ToArray(), Comparer);
            
            DirectoryInfo deepestRoot;
            
            var junctions = FindJunctions(elements.Select(c => c.Key), out deepestRoot).GroupBy(e => e.FullName, Comparer).ToDictionary(e => e.Key, e => e.ToArray(), Comparer);

            var referencedJunctions = new Dictionary<DirectoryInfo, XElement[]>();
            foreach (var jKey in junctions.Keys.OrderBy(k => k))
            {
                var junction = new DirectoryInfo(jKey);
                var references = elements.Where(e => e.Key.StartsWith(jKey, Comparison)).SelectMany(e => e.Value.Select(e1 => e1.Element)).ToArray();
                if(references.Length > 0)
                    referencedJunctions.Add(junction, references);
            }
            //var referencedJunctions =
            //    junctions.Join(elements, j => j.Key, e => e.Key, (j, c) => j.Value.Select(j1 => new { Junction = j1, Elements = c.Value.Select(c1 => c1.Element) })).SelectMany(j => j).ToArray();

            var changesMade = false;

            var actualProjectDirectory = GetActualLocation(projectDirectory, deepestRoot);
            var preferredJunctions = GetPreferredJunctions(deepestRoot);

            foreach (var referencedJunction in referencedJunctions)
            {
                var relativePath = GetRelativePath(projectDirectory, referencedJunction.Key);
                
                if(string.IsNullOrWhiteSpace(relativePath))
                    continue;

                var isProjectDirectory = referencedJunction.Key.FullName.Equals(projectDirectory.FullName, Comparison);

                var conditionalItemGroup = conditionalItemGroups.FirstOrDefault(
                                                       ig =>
                                                       ig.Condition.Equals(string.Format("Exists('{0}')", relativePath)));


                if (!isProjectDirectory)
                {
                    if (conditionalItemGroup == null)
                        lock (conditionalItemGroups)
                            lock (projectDocument)
                            {
                                var conditionString = string.Format("Exists('{0}')", relativePath);
                                conditionalItemGroup =
                                    conditionalItemGroups.FirstOrDefault(
                                        ig => ig.Condition.Equals(conditionString, Comparison));

                                if (conditionalItemGroup == null)
                                {
                                    conditionalItemGroup =
                                        new
                                            {
                                                itemGroup =
                                                    new XElement(defaultNamespace + "ItemGroup",
                                                                 new XAttribute("Condition", conditionString)),
                                                Condition = conditionString
                                            };
                                    if (firstItemGroup != null)
                                        firstItemGroup.AddBeforeSelf(conditionalItemGroup.itemGroup);
                                    else
                                        projectDocument.Root.AddFirst(conditionalItemGroup.itemGroup);
                                    changesMade = true;
                                    conditionalItemGroups.Add(conditionalItemGroup);
                                }
                            }
                }

                var actualLocation = GetActualLocation(referencedJunction.Key, deepestRoot);
                var preferredJunctionKey =
                    preferredJunctions.Keys.SingleOrDefault(
                        pj =>
                        actualLocation.FullName.StartsWith(string.Format("{0}{1}",
                                                                         pj.FullName.TrimEnd(new[]
                                                                             {
                                                                                 Path.DirectorySeparatorChar,
                                                                                 Path.AltDirectorySeparatorChar,
                                                                                 Path.VolumeSeparatorChar
                                                                             }),
                                                                         Path.DirectorySeparatorChar), Comparison));

                if (preferredJunctionKey != null)
                    actualLocation =
                        new DirectoryInfo(Path.Combine(preferredJunctions[preferredJunctionKey].FullName,
                                                       actualLocation.FullName.Substring(
                                                           preferredJunctionKey.FullName.Length)
                                                                     .TrimStart(new[]
                                                                         {
                                                                             Path.DirectorySeparatorChar,
                                                                             Path.AltDirectorySeparatorChar,
                                                                             Path.VolumeSeparatorChar
                                                                         })));

                foreach (var element in referencedJunction.Value)
                {
                    changesMade = true;
                    if (conditionalItemGroup != null)
                    {
                        element.Remove();
                        conditionalItemGroup.itemGroup.Add(element);
                    }
                    if (!contentNames.Contains(element.Name.LocalName, Comparer)) continue;
                    var link = element.Element(defaultNamespace + "Link");
                    if (link != null)
                        continue;
                    var includeAttribute = element.Attribute("Include");
                    var resolvedPath = new FileInfo(ResolvePath(actualLocation.FullName, includeAttribute.Value));
                    var relativeRoot =
                        actualLocation.FullName.StartsWith(actualProjectDirectory.FullName, Comparison)
                            ? actualProjectDirectory
                            : projectDirectory;
                    
                    var actualRelativeLocation = GetRelativePath(relativeRoot, resolvedPath);
                    if (actualRelativeLocation == includeAttribute.Value)
                        continue;
                    link = new XElement(defaultNamespace + "Link") { Value = actualRelativeLocation };
                    element.Add(link);
                }
            }
            var emptyItemGroups = itemGroups.Where(e => !e.Elements().Any()).ToArray();
            foreach (var ig in emptyItemGroups)
            {
                ig.Remove();
            }
            if (changesMade)
                using (var outputStream = projectFile.OpenWrite())
                {
                    projectDocument.Save(outputStream);
                }

            return !HasErrors;
        }

        private Dictionary<string, string> actualLocationCache;
        private readonly object cacheObject = new object();

        private FileInfo GetActualLocation(FileInfo junctionedLocation, DirectoryInfo deepestRoot)
        {
            if (!junctionedLocation.Exists || junctionedLocation.Directory == null)
                return null;

            var actualDirectory = GetActualLocation(junctionedLocation.Directory, deepestRoot);
            
            if (actualDirectory == null || !actualDirectory.Exists)
                return null;

            var actualFile = new FileInfo(Path.Combine(actualDirectory.FullName, junctionedLocation.Name));

            if (!actualFile.Exists)
                return null;

            return actualFile;
        }
        private DirectoryInfo GetActualLocation(DirectoryInfo junctionedLocation, DirectoryInfo deepestRoot)
        {
            if (!junctionedLocation.Exists)
                return null;

            if (actualLocationCache == null)
            {
                lock(cacheObject)
                    if (actualLocationCache == null)
                        actualLocationCache = new Dictionary<string, string>(Comparer);
            }

            var tempFileName = Guid.NewGuid().ToString();
            var cacheKey = junctionedLocation.FullName;
            
            if (!actualLocationCache.ContainsKey(cacheKey))
            {
                if (junctionedLocation.Attributes.HasFlag(FileAttributes.ReparsePoint) ||
                    junctionedLocation.Parent == null || !junctionedLocation.Parent.Exists)
                    try
                    {
                        using (new FileStream(Path.Combine(cacheKey, tempFileName),
                                              FileMode.Create,
                                              FileAccess.ReadWrite, FileShare.None, 4096, FileOptions.DeleteOnClose))
                        {
                            var actualLocation =
                                FindFile(deepestRoot, tempFileName,
                                         deepestRoot.Attributes.HasFlag(FileAttributes.ReparsePoint))
                                    .Select(f => f.Directory)
                                    .FirstOrDefault();
                            if (!actualLocationCache.ContainsKey(cacheKey) && actualLocation != null)
                            {
                                lock (cacheObject)
                                {
                                    if (!actualLocationCache.ContainsKey(cacheKey))
                                        actualLocationCache.Add(cacheKey, actualLocation.FullName);
                                    Console.WriteLine(string.Format("Found junction {0} -> {1}", cacheKey, actualLocation.FullName));
                                }
                            }
                            return actualLocation;
                        }
                    }
                    catch
                    {
                    }
                else
                {
                    var parentActualLocation = GetActualLocation(junctionedLocation.Parent, deepestRoot);
                    if (parentActualLocation != null && parentActualLocation.Exists)
                        return new DirectoryInfo(Path.Combine(parentActualLocation.FullName, junctionedLocation.Name));
                }
            }
            return actualLocationCache.ContainsKey(cacheKey) ? new DirectoryInfo(actualLocationCache[cacheKey]) : null;
        }

        private IEnumerable<FileInfo> FindFile(DirectoryInfo directory, string searchString, bool recurseJunctions = false)
        {
            var fsInfos = directory.GetFileSystemInfos();

            var foundFiles = fsInfos.OfType<FileInfo>().Where(f => searchString.Equals(f.Name, Comparison));
            var subDirectories = fsInfos.OfType<DirectoryInfo>();
            foreach (var foundFile in foundFiles)
                yield return foundFile;
            
            foreach (var subDirectory in subDirectories.Where(sd => recurseJunctions || !sd.Attributes.HasFlag(FileAttributes.ReparsePoint)))
            {
                foreach (var foundFile in FindFile(subDirectory, searchString, recurseJunctions))
                    yield return foundFile;
            }
        }

        private enum ElementType
        {
            Content,
            Reference,
            Other
        }
        private string GetRelativePath(FileSystemInfo source, FileSystemInfo target)
        {
            var sourcePath = source.FullName.Split(new[] {Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar});
            var targetPath = target.FullName.Split(new[] {Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar});

            var deepestCommonIndex = 0;

            for (; deepestCommonIndex < sourcePath.Length && deepestCommonIndex < targetPath.Length && sourcePath[deepestCommonIndex].Equals(targetPath[deepestCommonIndex], Comparison); )
                deepestCommonIndex++;
            
            var path = new List<string>();
            
            for (var index = deepestCommonIndex; index < sourcePath.Length; index++)
                path.Add("..");

            for (var index = deepestCommonIndex; index < targetPath.Length; index++)
            {
                path.Add(targetPath[index]);
            }
            return Path.Combine(path.ToArray())
                       .Replace(string.Format("{0}", Path.VolumeSeparatorChar),
                                string.Format("{0}{1}", Path.VolumeSeparatorChar, Path.DirectorySeparatorChar));
        }

        private static string ResolvePath(string root, string relativePath)
        {
            var fullPath = Path.Combine(root, relativePath);
            var directories = new List<string>();
            foreach (var dir in fullPath.Split(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar },
                                               StringSplitOptions.RemoveEmptyEntries))
            {
                if (dir.Equals(".."))
                {
                    var count = directories.Count;
                    if (count > 0)
                        directories.RemoveAt(count - 1);
                }
                else
                {
                    directories.Add(dir);
                }
            }
            return Path.Combine(directories.ToArray()).Replace(string.Format("{0}", Path.VolumeSeparatorChar),
                             string.Format("{0}{1}", Path.VolumeSeparatorChar, Path.DirectorySeparatorChar));
        }

        private IEnumerable<DirectoryInfo> FindJunctions(IEnumerable<string> paths, out DirectoryInfo root)
        {
            var distinctPaths = paths.Distinct();
            var deepestPath = new string[0];
            
            var directoryComponents =
                distinctPaths.Select(p =>
                {
                    var rv = p.Split(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar });
                    if (rv.Length > deepestPath.Length)
                        deepestPath = rv;
                    return rv;
                }).ToArray();
            
            var deepestCommonIndex = 0;

            for (;
                directoryComponents.All(
                    dc => dc[deepestCommonIndex].Equals(deepestPath[deepestCommonIndex], Comparison));
                )
            {
                deepestCommonIndex++;
            }

            root =
                new DirectoryInfo(Path.Combine(deepestPath.Take(deepestCommonIndex).ToArray())
                    .Replace(string.Format("{0}", Path.VolumeSeparatorChar),
                             string.Format("{0}{1}", Path.VolumeSeparatorChar, Path.DirectorySeparatorChar)));
            return FindJunctions(root);
        }

        private IEnumerable<DirectoryInfo> FindJunctions(DirectoryInfo dir)
        {
            DirectoryInfo[] subdirs;

            try
            {
                subdirs = dir.GetDirectories();
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("{0}: {1}", dir.FullName, ex.Message);
                HasErrors = true;
                subdirs = new DirectoryInfo[0];
            }

            foreach (var subdir in subdirs.Where(d => !d.Name.StartsWith(".hg")))
            {
                var isJunction = subdir.Attributes.HasFlag(FileAttributes.ReparsePoint);
                if (isJunction)
                {
                    yield return subdir;
                }

                foreach (var subJunction in FindJunctions(subdir))
                    yield return subJunction;
            }
        }
    }
}
