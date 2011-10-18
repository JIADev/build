using System;

namespace Harvester
{
	public class RepositoryEntry
	{
		public int RevisionNumber { get; set; }
		public string ChangesetId { get; set; }
		public string User { get; set; }
		public DateTime CreatedDateTime { get; set; }
		public string Summary { get; set; }
		public string Files { get; set; }
		public string IssueNumber { get; set; }
	}
}
