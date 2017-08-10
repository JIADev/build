using System;
using System.Collections.Generic;

namespace Harvester
{
	public class RepositoryEntry
	{
		// Mercurial fields.
		public int RevisionNumber { get; set; }
		public string ChangesetId { get; set; }
		public string ChangesetBranch { get; set; }
		public string Branches { get; set; }
		public string Bookmarks { get; set; }
		public string Parents { get; set; }
		public string User { get; set; }
		public DateTime CreatedDateTime { get; set; }
		public string Summary { get; set; }
		public string Files { get; set; }

		// Constructed fields.
		public List<string> BranchList { get; set; }
		public List<string> BookmarkList { get; set; }
		public List<int> ParentIndexList { get; set; }
		public string IssueNumber { get; set; }
	}
}
