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

        private bool HasErrors { get; set; }
        private StringComparer Comparer { get { return CaseSensitivePaths ? StringComparer.InvariantCulture : StringComparer.InvariantCultureIgnoreCase; } }
        private StringComparison Comparison { get { return CaseSensitivePaths ? StringComparison.InvariantCulture : StringComparison.InvariantCultureIgnoreCase; } }


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

            var contentNames = new[] { "Compile", "Content", "None", "ProjectReference" };
            var referenceNames = new[] {"Reference"};
            
            var elements =
                itemGroups.Elements()
                .Select(e => new { ElementType = contentNames.Contains(e.Name.LocalName, Comparer) ? ElementType.Content : referenceNames.Contains(e.Name.LocalName, Comparer) ? ElementType.Reference : ElementType.Other, Element = e})
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
                          .OrderBy(e => e.Key);

            var junctions = FindJunctions(elements.Select(c => c.Key));

            var referencedJunctions =
                junctions.Join(elements, j => true, c => true, (j, c) => new { Junction = j, Element = c })
                         .Where(
                             jc =>
                             jc.Element.Key
                                 .StartsWith(jc.Junction.FullName, Comparison))
                         .GroupBy(jc => jc.Junction)
                         .Select(jc => new { jc.Key, Elements = jc.Select(j => j.Element.Element) })
                         .OrderBy(jc => jc.Key.FullName);

            var changesMade = false;

            foreach (var referencedJunction in referencedJunctions)
            {
                var relativePath = GetRelativePath(projectDirectory, referencedJunction.Key);
                if(string.IsNullOrWhiteSpace(relativePath))
                    continue;
                
                var conditionalItemGroup =
                    conditionalItemGroups.FirstOrDefault(
                        ig => ig.Condition.Equals(string.Format("Exists('{0}')", relativePath)));

                if (conditionalItemGroup == null)
                {
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
                                        itemGroup = new XElement(defaultNamespace + "ItemGroup", new XAttribute("Condition", conditionString)),
                                        Condition = conditionString
                                    };
                                if (firstItemGroup != null)
                                    firstItemGroup.AddBeforeSelf(conditionalItemGroup.itemGroup);
                                else
                                    projectDocument.Root.AddFirst(conditionalItemGroup.itemGroup);

                                conditionalItemGroups.Add(conditionalItemGroup);
                            }
                        }
                }

                foreach (var element in referencedJunction.Elements)
                {
                    changesMade = true;
                    element.Remove();
                    conditionalItemGroup.itemGroup.Add(element);
                }
            }

            if (changesMade && false)
                using (var outputStream = projectFile.OpenWrite())
                {
                    projectDocument.Save(outputStream);
                }

            return !HasErrors;
        }
        private enum ElementType
        {
            Content,
            Reference,
            Other
        }
        private string GetRelativePath(DirectoryInfo source, DirectoryInfo target)
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

        private IEnumerable<DirectoryInfo> FindJunctions(IEnumerable<string> paths)
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

            var root =
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
