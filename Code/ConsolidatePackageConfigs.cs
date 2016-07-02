using System.IO;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;

namespace j6.BuildTools.MsBuildTasks
{
    public class ConsolidatePackageConfigs : Task
    {
        [Required]
        public string Root { get; set; }

        [Required]
        public string MasterPackageConfig { get; set; }

        public override bool Execute()
        {
            var root = new DirectoryInfo(Root);
            var packageConfigs = root.GetFiles("packages.config", SearchOption.AllDirectories);
            var masterPackageConfig = new FileInfo(MasterPackageConfig);
            
            if (!masterPackageConfig.Exists)
            {
                Console.Error.WriteLine(string.Format("File does not exist: {0}", MasterPackageConfig));
                return false;
            }

            var childConfigs = packageConfigs.Where(pc => !pc.FullName.Equals(masterPackageConfig.FullName));
            var master = XDocument.Load(masterPackageConfig.FullName);
            
            var masterPackage = master.Root;
            if (masterPackage == null)
            {
                Console.Error.WriteLine(string.Format("Unable to load {0}", MasterPackageConfig));
                return false;
            }

            var allPackageNodes = new List<XElement>();
            foreach (var child in childConfigs.Select(cc => new { FileInfo = cc, Xml = XDocument.Load(cc.FullName) }))
            {
                if (child == null || child.Xml == null || child.Xml.Root == null ||
                    !child.Xml.Root.Name.LocalName.Equals("packages", StringComparison.InvariantCultureIgnoreCase))
                    continue;

                allPackageNodes.AddRange(child.Xml.Root.Elements());
                child.Xml.Root.RemoveAll();
                child.Xml.Save(child.FileInfo.FullName);
            }

            masterPackage.RemoveAll();
            var allDescendants = allPackageNodes.GroupBy(e => e.Attribute("id").Value, e => e, StringComparer.InvariantCultureIgnoreCase).ToDictionary(e => e.Key, e => e.ToArray(), StringComparer.InvariantCultureIgnoreCase);
            foreach (var package in allDescendants.OrderBy(p => p.Key))
            {
                var versionComparer = new VersionComparer();
                var byVersion =
                    package.Value.GroupBy(v => v.Attribute("version").Value, v => v,
                                          StringComparer.InvariantCultureIgnoreCase).OrderBy(v => v.Key, versionComparer)
                                          .ToDictionary(v => v.Key, v => v.OrderBy(v1 => v1.Attribute("targetFramework") == null ? 0 : 1).ToArray(), StringComparer.InvariantCultureIgnoreCase);
                if(!byVersion.Any())
                    continue;
                var latestVersion = byVersion.LastOrDefault();
                var latestVersionNodes = latestVersion.Value.Select(v => new
                    {
                        Id = v.Attribute("id").Value,
                        Version = v.Attribute("version").Value,
                        targetFramework = v.Attribute("targetFramework") == null ? null : v.Attribute("targetFramework").Value
                    }).Distinct();

                var add = latestVersionNodes.Select(
                    n =>
                    latestVersion.Value.First(
                        lv =>
                            {
                                var tfn = lv.Attribute("targetFramework");
                                var tf = (tfn == null ? null : tfn.Value);
                                return
                                    lv.Attribute("id").Value.Equals(n.Id) &&
                                    lv.Attribute("version").Value.Equals(n.Version) &&
                                    string.Equals(tf, n.targetFramework);
                            }
                        )).Cast<object>().ToArray();
                masterPackage.Add(add);
            }
            master.Save(MasterPackageConfig);
            return true;
        }
    }
}
