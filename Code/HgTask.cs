using System;
using System.IO;
using System.Xml;
using System.Xml.Linq;
using Microsoft.Build.Utilities;
using System.Diagnostics;

namespace j6.BuildTools.MsBuildTasks
{
	public abstract class HgTask : Task
	{
		private ConsoleTraceListener _traceListener;

		public string RepoDirectory { get; set; }

		public string HgExe { get; set; }

		public bool Verbose
		{
			get { return _traceListener != null; }
			set
			{
				if (_traceListener == null && value)
				{
					_traceListener = new ConsoleTraceListener();
					Trace.Listeners.Add(_traceListener);
				}
				else if (_traceListener != null && !value)
				{
					Trace.Listeners.Remove(_traceListener);
					_traceListener = null;
				}
			}
		}


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
			var xmlText = RunHg(string.Format("{0} --style=xml --verbose", args));
			if (string.IsNullOrWhiteSpace(xmlText))
				return null;
			using (var reader = new StringReader(xmlText))
			{
				return XDocument.Load(reader);
			}
		}

		public void WriteError(string errorText)
		{
			Console.ForegroundColor = ConsoleColor.Red;
			Console.WriteLine(errorText);
			Console.ResetColor();
		}

		protected string HumanReadableSize(double bytesRead)
		{
			var sizes = new[]
				{
					"bytes",
					"KiB",
					"MiB",
					"GiB",
					"TiB",
					"PiB"
				};
			var index = 0;
			while (bytesRead > 1024 && sizes.Length > index)
			{
				index++;
				bytesRead = bytesRead / 1024;
			}
			return string.Format("{0:0.00} {1}", bytesRead, sizes[index]);
		}
	}
}
