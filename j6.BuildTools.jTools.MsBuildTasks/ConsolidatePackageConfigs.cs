using System.IO;
using System.Xml;
using System.Xml.Serialization;
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

			var allPackages = packageConfigs.Select(Packages.Load).Where(p => p.Items != null).ToArray();
	        var vc = new VersionComparer();
	        var allPackageNodes = allPackages.SelectMany(p => p.Items).GroupBy(p => new {p.Id, p.TargetFramework})
	                                         .ToDictionary(p => p.Key, p => p.OrderByDescending(p1 => p1.VersionString, vc).FirstOrDefault());
			var masterPackage = new Packages(allPackageNodes.Values);
			
			masterPackage.SortDistinct();
			masterPackage.Save(MasterPackageConfig, new XmlSerializerNamespaces(new[]
				{
					new XmlQualifiedName(string.Empty, string.Empty), 
				}), Encoding.UTF8);

	        var childPackages = allPackages.Where(p => p.FileName != MasterPackageConfig);
	        
			foreach (var childPackage in childPackages)
			{
				childPackage.Items = null;
				childPackage.Save(new XmlSerializerNamespaces(new[]
					{
						new XmlQualifiedName(string.Empty, string.Empty),
					}), Encoding.UTF8);
			}
			
			return true;
        }
    }
}
