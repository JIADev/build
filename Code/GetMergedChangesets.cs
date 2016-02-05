using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class GetMergedChangesets : HgTask
	{
		[Required]
		public new string RepoDirectory { get { return base.RepoDirectory; } set { base.RepoDirectory = value; } }

		[Required]
		public string OriginalChangeset { get; set; }

		[Required]
		public string NewChangeset { get; set; }

		public string AdditionalArgs { get; set; }
		
		public string OutputFile { get; set; }

		public string StyleSheet { get; set; }

		private string _updateToChangeset;
		public string UpdateToChangeset { get { return string.IsNullOrWhiteSpace(_updateToChangeset) ? NewChangeset : _updateToChangeset; } set { _updateToChangeset = value; } }

		
		public override bool Execute()
		{
			var output = RunHgXmlOutput(string.Format("log --rev \"ancestors('{0}') and !ancestors({1}) {2}\"", NewChangeset,
			                             OriginalChangeset, AdditionalArgs));

			if (string.IsNullOrWhiteSpace(OutputFile)) return true;

			if (!string.IsNullOrWhiteSpace(StyleSheet))
				UpdateStyleSheet.AddStyleSheet(output, StyleSheet);

			output.Save(OutputFile);
			
			return true;
		}
	}
}
