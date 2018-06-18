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
			string output = string.Empty;
			try
			{
				var originalChangesets = OriginalChangeset.Split(new[] { ' ', ';', ',', ':' }, StringSplitOptions.RemoveEmptyEntries);

				if (!string.IsNullOrWhiteSpace(Source))
				{
					if (!string.IsNullOrWhiteSpace(TagsBranch))
						output = RunHg(string.Format("pull -b {0} {1}", TagsBranch, Source));

					output = RunHg(string.Format("pull {0} {1}",
										string.Join(" ", originalChangesets.Union(new [] { NewChangeset }).Distinct().Select(oc => string.Format("-r {0}", oc))),
										Source));
				}

				output = RunHg(string.Format("log --rev \"({0}) and !ancestors('{1}')\"", string.Join(" or ", originalChangesets.Select(c => string.Format("ancestors('{0}')", c))), NewChangeset));

				if (!string.IsNullOrWhiteSpace(output))
				{
					Console.ForegroundColor = ConsoleColor.Red;

					Console.Error.WriteLine("The following changes were reverted:");
					Console.WriteLine(output);

					Console.ResetColor();
					return false;
				}
			}
			catch (Exception ex)
			{
				Console.ForegroundColor = ConsoleColor.Red;

				Console.Error.WriteLine("Error during ForwardChangesCheck /p:RepoDirectory={0};OriginalChangeset{1};NewChangeset={2};TagsBranch={3};Source={4}", RepoDirectory, OriginalChangeset, NewChangeset, TagsBranch, Source);
				
				if(!string.IsNullOrWhiteSpace(output))
					Console.Error.WriteLine("Last hg output: {0}", output);

				Console.Error.WriteLine("Exception: {0}", ex);

				Console.ResetColor();
				return false;
			}
			
			return true;
		}
	}
}
