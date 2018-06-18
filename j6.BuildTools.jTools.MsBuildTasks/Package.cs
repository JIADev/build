using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace j6.BuildTools.MsBuildTasks
{
	[Serializable]
	[XmlRoot("packages", Namespace = "")]
	public class Packages : SerializableObject<Packages>
	{
		[XmlElement("package")]
		public Package[] Items { get; set; }

		private Package.Comparer _comparer = new Package.Comparer();
		
		public Packages()
		{
			
		}

		public Packages(IEnumerable<Package> initialList)
		{
			Items = Sort(Distinct(initialList)).ToArray();
		}

		public void Distinct()
		{
			Items = Distinct(Items).ToArray();
		}

		public void Sort()
		{
			Items = Sort(Items).ToArray();
		}

		public void SortDistinct()
		{
			Items = Sort(Distinct(Items)).ToArray();
		}

		private IEnumerable<Package> Sort(IEnumerable<Package> input)
		{
			return input.OrderBy(i => i.Id).ThenBy(i => i.Version).ThenByDescending(i => i.TargetFramework);
		}
		
		public IEnumerable<Package> Distinct(IEnumerable<Package> input)
		{
			return input.Distinct(_comparer);
		}
	}

	[Serializable]
	[XmlRoot("package", Namespace = "")]
	public class Package : SerializableObject<Package>
	{
		[XmlAttribute("id")]
		public string Id { get; set; }

		[XmlAttribute("version")]
		public string VersionString { get { return Version.ToString(); } set { Version = Version.Parse(value); } }

		[XmlIgnore]
		public Version Version { get; set; }

		[XmlAttribute("targetFramework")]
		public string TargetFramework { get; set; }

		public class Comparer : IEqualityComparer<Package>
		{
			public bool Equals(Package x, Package y)
			{
				if (ReferenceEquals(x, y))
					return true;

				if (x == null || y == null)
					return false;

				return (x.Id ?? string.Empty).Equals((y.Id ?? string.Empty), StringComparison.InvariantCultureIgnoreCase)
				       && (x.VersionString ?? string.Empty).Equals((y.VersionString ?? string.Empty), StringComparison.InvariantCultureIgnoreCase)
				       && (x.TargetFramework ?? string.Empty).Equals((y.TargetFramework ?? string.Empty), StringComparison.InvariantCultureIgnoreCase);
			}

			public int GetHashCode(Package obj)
			{
				return string.Format("Package:{0}:{1}:{2}", obj.Id, obj.VersionString, obj.TargetFramework).GetHashCode();
			}
		}

	}
}
