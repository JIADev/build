using System.Linq;
using Microsoft.Build.Framework;
using System.Text.RegularExpressions;
using System.Diagnostics;

namespace j6.BuildTools.MsBuildTasks
{
	public class GetTipChangeset : HgTask
	{
		private static readonly Regex ChangesetLineRegex = new Regex("changeset:[^;]*");
		[Output]
		public string Changeset { get; set; }

		public override bool Execute()
		{
			Debugger.Break();
			var output = RunHgArrayOutput("tip");
			var changesetLine = output.Single(o => ChangesetLineRegex.Match(o).Success);
			var changesetPosition = changesetLine.LastIndexOf(':');
			Changeset = changesetLine.Substring(changesetPosition).Trim(':');
			return true;
		}
	}
}
