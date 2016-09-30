using System.Threading;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace j6.BuildTools.MsBuildTasks
{
    public class ConditionJunctionedFiles :Task
    {
        [Required]
        public string ProjectFile { get; set; }

        public string WorkingDirectory { get; set; }

        private bool HasErrors { get; set; }

        public override bool Execute()
        {
            var projectFile = File.Exists(ProjectFile) ? new FileInfo(ProjectFile) : new FileInfo(Path.Combine(WorkingDirectory, ProjectFile));
            if (!projectFile.Exists)
            {
                throw new FileNotFoundException("File not found", ProjectFile);
            }

            var projectDirectory = projectFile.Directory;
            
            if(projectDirectory == null || !projectDirectory.Exists)
                throw new DirectoryNotFoundException(string.Format("Directory not found: {0}", projectFile.DirectoryName));

            XDocument projectDocument;
            using (var inputStream = projectFile.OpenRead())
                projectDocument = XDocument.Load(inputStream);
            
            if(projectDocument.Root == null)
                throw new FieldAccessException(string.Format("Can't read root of file {0}", projectFile.FullName));
            
            var defaultNamespace = projectDocument.Root.GetDefaultNamespace();
            
            var allItemGroups = projectDocument.Root.Elements()
                                               .Where(
                                                   e =>
                                                   e.Name.LocalName.Equals("ItemGroup",
                                                                           StringComparison.InvariantCultureIgnoreCase))
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

            var contentNames = new[] {"Compile", "Content", "None", "ProjectReference", "Reference"};
            
            var content =
                itemGroups.Elements()
                          .Where(e => contentNames.Contains(e.Name.LocalName, StringComparer.InvariantCultureIgnoreCase))
                          .Select(e => new { Key = e.Attributes().Select(a => new { Name = a.Name.LocalName, a.Value })
                              .Where(a => a.Name.Equals("Include")).Select(a => a.Value).SingleOrDefault(), Element = e })
                          .Where(e => !string.IsNullOrWhiteSpace(e.Key))
                          .Select(e => new { Key = ResolvePath(projectDirectory.FullName, e.Key), e.Element})
                          .OrderBy(e => e.Key);

            var junctions = FindJunctions(projectDirectory);

            var referencedJunctions =
                junctions.Join(content, j => true, c => true, (j, c) => new {Junction = j, Element = c})
                         .Where(
                             jc =>
                             jc.Element.Key
                                 .StartsWith(jc.Junction.FullName, StringComparison.InvariantCultureIgnoreCase))
                         .GroupBy(jc => jc.Junction)
                         .Select(jc => new {jc.Key, Elements = jc.Select(j => j.Element.Element)})
                         .OrderBy(jc => jc.Key.FullName);
            
            var changesMade = false;

            foreach (var referencedJunction in referencedJunctions)
            {
                var relativePath = referencedJunction.Key.FullName.Substring(projectDirectory.FullName.Length).Trim(new [] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar });
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
                                ig => ig.Condition.Equals(conditionString, StringComparison.InvariantCultureIgnoreCase));
                        
                        if (conditionalItemGroup == null)
                        {
                            conditionalItemGroup =
                                new
                                    {
                                        itemGroup = new XElement(defaultNamespace + "ItemGroup", new XAttribute("Condition", conditionString)),
                                        Condition = conditionString
                                    };
                            if(firstItemGroup != null)
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
            
            if(changesMade)
                using (var outputStream = projectFile.OpenWrite())
                {
                    projectDocument.Save(outputStream);
                }

            return !HasErrors;
        }

        private static string ResolvePath(string root, string relativePath)
        {
            var fullPath = Path.Combine(root, relativePath);
            var directories = new List<string>();
            foreach (var dir in fullPath.Split(new[] {Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar},
                                               StringSplitOptions.RemoveEmptyEntries))
            {
                if (dir.Equals(".."))
                {
                    var count = directories.Count;
                    if(count > 0)
                        directories.RemoveAt(count - 1);
                }
                else
                {
                    directories.Add(dir);
                }
            }
            return Path.Combine(directories.ToArray());
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
                    continue;
                }

                foreach (var subJunction in FindJunctions(subdir))
                    yield return subJunction;
            }
        }
    }
}
