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
    public class SortPackageConfigs : Task
    {
        [Required]
        public string Root { get; set; }

        public override bool Execute()
        {
            var root = new DirectoryInfo(Root);
            var packageConfigs = root.GetFiles("packages.config", SearchOption.AllDirectories);
            
        
            foreach (var child in packageConfigs.Select(cc => new { FileInfo = cc, Xml = XDocument.Load(cc.FullName) }))
            {
                var filePackageNodes = new List<XElement>();
                if (child == null || child.Xml == null || child.Xml.Root == null ||
                    !child.Xml.Root.Name.LocalName.Equals("packages", StringComparison.InvariantCultureIgnoreCase))
                    continue;

                filePackageNodes.AddRange(child.Xml.Root.Elements().OrderBy(c => c.Attribute("id").Value).ThenBy(c => Version.Parse(c.Attribute("version").Value)));
                child.Xml.Root.RemoveAll();
                foreach (var packageNode in filePackageNodes)
                {
                    child.Xml.Root.Add(packageNode);
                }
                child.Xml.Save(child.FileInfo.FullName);
            }

            return true;
        }
    }
}
