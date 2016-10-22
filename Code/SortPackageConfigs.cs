using System.IO;
using System.Xml;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using System.Xml.Serialization;

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

	        var packages = packageConfigs.Select(Packages.Load);
			
			foreach (var package in packages.Where(p => p.Items != null))
			{
				package.SortDistinct();
				package.Save(new XmlSerializerNamespaces(new[]
				{
					new XmlQualifiedName(string.Empty, string.Empty), 
				}), Encoding.UTF8);
			}

			return true;
        }
    }
}
