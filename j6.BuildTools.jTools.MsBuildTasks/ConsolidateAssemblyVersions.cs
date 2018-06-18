using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Build.Framework;
using System.Xml.Linq;
using Task = Microsoft.Build.Utilities.Task;

namespace j6.BuildTools.MsBuildTasks
{
    public class ConsolidateAssemblyVersions : Task
    {
        [Required]
        public string Root { get; set; }

        public override bool Execute()
        {
            var root = new DirectoryInfo(Root);
            var csProjectFiles = root.GetFiles("*.csproj", SearchOption.AllDirectories);
            var projectXmls =
                csProjectFiles.Select(pf => pf.FullName)
                            .Distinct(StringComparer.InvariantCultureIgnoreCase)
                            .ToDictionary(fn => fn, fn =>
                                {
                                    try
                                    {
                                        return XDocument.Load(fn);
                                    }
                                    catch
                                    {
                                        return null;
                                    }
                                },
            StringComparer.InvariantCultureIgnoreCase).Where(px => px.Value != null).ToArray();

            var versionComparer = new VersionComparer();
            
            var references =
                projectXmls.SelectMany(
                    projectXmlPair =>
                    GetReferences(projectXmlPair.Value)
                        .Select(r => new { FileName = projectXmlPair.Key, XmlDocument = projectXmlPair.Value, Xml = r.Item1, AssemblyName = r.Item2, VersionString = r.Item3})).ToArray();
            var assemblyVersions = new Dictionary<string, Tuple<string, XElement>>(StringComparer.InvariantCultureIgnoreCase);
            
            foreach (var reference in references)
            {
                if (assemblyVersions.ContainsKey(reference.AssemblyName))
                {
                    if (
                        versionComparer.Compare(reference.VersionString,
                                                assemblyVersions[reference.AssemblyName].Item1) > 0)
                        assemblyVersions[reference.AssemblyName] = new Tuple<string, XElement>(reference.VersionString,
                                                                                               reference.Xml);
                }
                else
                    assemblyVersions.Add(reference.AssemblyName,
                                         new Tuple<string, XElement>(reference.VersionString, reference.Xml));
            }

            foreach (var referenceAndDocument in references.GroupBy(r => new { r.FileName, r.XmlDocument }))
            {
                var documentChanged = false;

                foreach (var reference in referenceAndDocument)
                {
                    if (!assemblyVersions.ContainsKey(reference.AssemblyName))
                        continue;
                    var latestVersionTuple = assemblyVersions[reference.AssemblyName];
                    var latestVersion = new { VersionString = latestVersionTuple.Item1, Xml = latestVersionTuple.Item2 };
                    
                    if(latestVersion.VersionString.Equals("0.0.0.0"))
                        continue;

                    if (reference.VersionString.Equals(latestVersion.VersionString)) continue;
                    
                    var includeAttribute = reference.Xml.Attribute("Include");
                    var desiredIncludeValue = latestVersion.Xml.Attribute("Include").Value;
                    
                    if (includeAttribute.Value != desiredIncludeValue)
                    {
                        includeAttribute.Value = desiredIncludeValue;
                        documentChanged = true;
                    }

                    var specificVersionElement =
                        reference.Xml.Elements()
                                 .SingleOrDefault(
                                     e =>
                                     e.Name.LocalName.Equals("SpecificVersion",
                                                             StringComparison.InvariantCultureIgnoreCase));

                    if (specificVersionElement == null)
                    {
                        specificVersionElement = new XElement(XName.Get("SpecificVersion", reference.Xml.GetDefaultNamespace().NamespaceName)) { Value = "True" };
                        reference.Xml.Add(specificVersionElement);
                        documentChanged = true;
                    }
                    else if (!bool.Parse(specificVersionElement.Value))
                    {
                        specificVersionElement.Value = "True";
                        documentChanged = true;
                    }
                    //var desiredHintPath =
                    //    latestVersion.Xml.Elements().SingleOrDefault(e => e.Name.LocalName.Equals("HintPath"));
                    //if(desiredHintPath == null)
                    //    continue;

                    //var hintPathElement =
                    //    reference.Xml.Elements().SingleOrDefault(e => e.Name.LocalName.Equals("HintPath"));

                    //if (hintPathElement == null)
                    //{
                    //    hintPathElement = new XElement(XName.Get("HintPath", reference.Xml.GetDefaultNamespace().NamespaceName)) { Value = desiredHintPath.Value };
                    //    reference.Xml.Add(hintPathElement);
                    //    documentChanged = true;
                    //}
                    //else if (hintPathElement.Value != desiredHintPath.Value)
                    //{
                    //    hintPathElement.Value = desiredHintPath.Value;
                    //    documentChanged = true;
                    //}
                }
                if(!documentChanged)
                    continue;
                
                referenceAndDocument.Key.XmlDocument.Save(referenceAndDocument.Key.FileName);
            }
            return true;
        }

        private IEnumerable<Tuple<XElement, string, string>> GetReferences(XDocument xml)
        {
            if (xml == null)
                return new Tuple<XElement, string, string>[0];
            var xmlRoot = xml.Root;
            if (xmlRoot == null)
                return new Tuple<XElement, string, string>[0];

            var references =
                xmlRoot.Elements()
                       .Where(e => e.Name.LocalName.Equals("ItemGroup"))
                       .SelectMany(igs => igs.Elements().Where(ig => ig.Name.LocalName.Equals("Reference")));

            return references.Select(r =>
                {
                    var infos = GetVersionInfo(r);
                    return infos == null ? null : new Tuple<XElement, string, string>(r, infos.Item1, infos.Item2);
                }).Where(i => i != null);
        }

        private Tuple<string, string> GetVersionInfo(XElement reference)
        {
            var includeAttribute = reference.Attribute("Include");
            if (includeAttribute == null)
                return null;
            var includeParts =
                includeAttribute.Value.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries)
                                .Where(s => !string.IsNullOrWhiteSpace(s))
                                .ToArray();
            var referencedAssemblyName = includeParts.First();
            if (includeParts.Length < 2)
                return new Tuple<string, string>(referencedAssemblyName, "0.0.0.0");

            var referenceProperties = includeParts.Skip(1)
                                                  .Select(
                                                      s =>
                                                      s.Split(new[] {'='}, StringSplitOptions.RemoveEmptyEntries)
                ).Where(kv =>
                        kv.Length == 2).Select(kv =>
                                               new
                                                   {
                                                       Key = kv[0].Trim(),
                                                       Value = kv[1].Trim()
                                                   })
                                                  .ToDictionary(kv => kv.Key, kv => kv.Value,
                                                                StringComparer.InvariantCultureIgnoreCase);

            if (!referenceProperties.ContainsKey("Version"))
                return null;
            var versionString = referenceProperties["Version"];
            return new Tuple<string, string>(referencedAssemblyName, versionString);
        }

    }
}
