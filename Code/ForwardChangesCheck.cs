using System;
using System.Linq;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class ForwardChangesCheck : HgTask
	{
		[Required]
		public new string RepoDirectory { get { return base.RepoDirectory; } set { base.RepoDirectory = value; } }
		
		[Required]
		public string OriginalChangeset { get; set; }
		
		[Required]
		public string NewChangeset { get; set; }

		public string TagsBranch { get; set; }

		public string Source { get; set; }

		public ForwardChangesCheck()
		{
			if (string.IsNullOrWhiteSpace(TagsBranch))
				TagsBranch = "tags";
		}

		public override bool Execute()
		{
			var originalChangesets = OriginalChangeset.Split(new[] { ' ', ';', ',', ':' }, StringSplitOptions.RemoveEmptyEntries);

			if (!string.IsNullOrWhiteSpace(Source))
			{
				if (!string.IsNullOrWhiteSpace(TagsBranch))
					RunHg(string.Format("pull -r {0} {1}", TagsBranch, Source));

				RunHg(string.Format("pull -r {0} {1}",
				                    string.Join(" ", originalChangesets.Select(oc => string.Format("-r {0}", oc))),
				                    Source));
			}

			var output = RunHg(string.Format("log --rev \"({0}) and !ancestors('{1}')\"", string.Join(" or ", originalChangesets.Select(c => string.Format("ancestors('{0}')", c))), NewChangeset));
			
			if (!string.IsNullOrWhiteSpace(output))
			{
				Console.ForegroundColor = ConsoleColor.Red;
				
				Console.Error.WriteLine("The following changes were reverted:");
				Console.WriteLine(output);

				Console.ResetColor();
				return false;
			}
			return true;
		}
	}
}
