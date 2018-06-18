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

        public bool OnlyUseLatest { get; set; }

        public override bool Execute()
        {
            var root = new DirectoryInfo(Root);
            var packageConfigs = root.GetFiles("packages.config", SearchOption.AllDirectories);

            var packages = packageConfigs.Select(Packages.Load).Where(p => p.Items != null).ToArray();
            var latestVersions = new Dictionary<string, Package>();
            if (OnlyUseLatest)
            {
                latestVersions = GetLatestVersions(packages.SelectMany(p => p.Items));
            }
			foreach (var package in packages)
			{
			    if (OnlyUseLatest)
			    {
			        var packageNames = package.Items.Select(p => p.Id).Distinct(StringComparer.InvariantCultureIgnoreCase);
			        package.Items = packageNames.Select(p => latestVersions[p]).ToArray();
			    }
			    package.SortDistinct();
				package.Save(new XmlSerializerNamespaces(new[]
				{
					new XmlQualifiedName(string.Empty, string.Empty), 
				}), Encoding.UTF8);
			}

			return true;
        }

        private Dictionary<string, Package> GetLatestVersions(IEnumerable<Package> packages)
        {
            var vc = new VersionComparer();
	        
            var returnValue = packages.GroupBy(p => p.Id, StringComparer.InvariantCultureIgnoreCase)
                             .ToDictionary(p => p.Key, p => p.OrderByDescending(pk => pk.VersionString, vc)
                                                                .ThenByDescending(pk => pk.TargetFramework, StringComparer.InvariantCultureIgnoreCase).First());
            return returnValue;
        }
    }
}
