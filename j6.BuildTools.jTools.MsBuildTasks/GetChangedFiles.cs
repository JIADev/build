using System;
using System.Diagnostics;
using System.Linq;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class GetChangedFiles : HgTask
	{
		[Required]
		public new string RepoDirectory { get { return base.RepoDirectory; } set { base.RepoDirectory = value; } }

		[Required]
		public string OriginalChangeset { get; set; }

		[Required]
		public string NewChangeset { get; set; }

		public string AdditionalArgs { get; set; }

		[Output]
		public string[] ChangedFiles { get; set; }

		public override bool Execute()
		{
			var output = RunHgXmlOutput(string.Format("log --rev \"ancestors('{0}') and !ancestors({1}) {2}\"", NewChangeset,
										 OriginalChangeset, AdditionalArgs));
			
			ChangedFiles = new string[0];

			if (output == null || output.Root == null || (!output.Root.HasElements && !output.Root.HasAttributes))
				return true;

			ChangedFiles = output.Elements("log").SelectMany(log => log.Elements("logentry")).SelectMany(logentry => logentry.Elements("paths")).SelectMany(paths => paths.Elements("path")).Select(p => p.Value).Distinct(StringComparer.InvariantCultureIgnoreCase).ToArray();
			return true;
		}
	}
}
