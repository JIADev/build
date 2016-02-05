using System;
using System.IO;
using System.Text;
using System.Xml.Linq;
using Microsoft.Build.Utilities;
using System.Xml;

namespace j6.BuildTools.MsBuildTasks
{
	public abstract class HgTask : Task
	{
		public string RepoDirectory { get; set; }

		public string HgExe { get; set; }

		private string _additionalHgArgs;
		public string AdditionalHgArgs { get { return _additionalHgArgs ?? string.Empty; } set { _additionalHgArgs = value; } }

		protected HgTask()
		{
			HgExe = "hg";
		}

		public string[] RunHgArrayOutput(string args)
		{
			return RunHg(args).Split(new [] { Environment.NewLine }, StringSplitOptions.None);
		}

		public string RunHg(string args)
		{
			var arguments = args;
			if (!string.IsNullOrWhiteSpace(AdditionalHgArgs))
				arguments = string.Format("{0} {1}", arguments, AdditionalHgArgs);
			var result = BuildSystem.RunProcess(HgExe, arguments, RepoDirectory, displayStdErr: false, displayStdOut: false);
			return result;
		}

		public XDocument RunHgXmlOutput(string args)
		{
			using (var reader = new StringReader(RunHg(string.Format("{0} --style=xml --verbose", args))))
				return XDocument.Load(reader);
		}
	}
}
