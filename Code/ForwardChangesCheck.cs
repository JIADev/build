using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Build.Utilities;
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

		public override bool Execute()
		{
			var output = RunHg(string.Format("log --rev \"ancestors('{0}') and !ancestors('{1}')\"", OriginalChangeset, NewChangeset));
			
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
