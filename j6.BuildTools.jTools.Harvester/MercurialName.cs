using System.Collections.Generic;

namespace Harvester
{
	public class MercurialName
	{
		public string Name { get; set; }
		public List<Subrepository> SubrepositoryList { get; set; }

		// For branches in format 3 repositories, list of features related to branch.
		public List<string> FeatureList { get; set; }
	}
}
