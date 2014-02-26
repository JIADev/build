using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;

namespace ExtractChangesets
{
	class Program
	{
		static readonly Regex ChangesetRegex = new Regex("^changeset:.*$", RegexOptions.Multiline);

		private static int Main(string[] args)
		{
			try
			{
				var hgExe = "hg";
				if (args.Length < 0)
				{
					Console.WriteLine("Usage ExtractChangesets.exe <mergedRevisions.txt.file> <outputFile.xml> [<path.to.hg.exe>] (defaults to {0})",
						hgExe);
					return 1;
				}
				var mergedRevisionFile = args[0];

				if (!File.Exists(mergedRevisionFile))
				{
					Console.WriteLine("{0} doesn't exist", mergedRevisionFile);
					return 2;
				}
				string outputFile = null;
				
				if (args.Length > 1)
				{
					outputFile = args[1];
				}

				if (args.Length > 2)
				{
					hgExe = args[2];
				}

				var changesets = GetChangesets(mergedRevisionFile);
				GenerateXml(hgExe, outputFile, changesets);
				
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}
		
		private static void GenerateXml(string hgExe, string outputFile, IEnumerable<string> changesets)
		{
			var args = CreateArgs(changesets);

			var xmlInput = RunProcess(hgExe, args, Environment.CurrentDirectory);
			var xDoc = XDocument.Parse(xmlInput);
			var remove = xDoc.XPathSelectElements("/log/logentry")
				.Select(le => new {logEntry = le, msg = le == null ? string.Empty : (le.XPathSelectElement("msg") ?? string.Empty)})
				.Where(m => m.msg.Value.Contains("@build")).Select(e => e.logEntry);
			foreach (var entry in remove)
			{
				entry.Remove();
			}
			xDoc.Save(outputFile);
		}

		private static string RunProcess(string process,
			string args,
			string workingDirectory,
			Dictionary<string, string> extraEnvVariables = null)
		{
			var startInfo =
				new ProcessStartInfo
				{
					FileName = process,
					UseShellExecute = false,
					RedirectStandardError = true,
					RedirectStandardOutput = true,
					Arguments = args,
					WorkingDirectory = workingDirectory,
					StandardErrorEncoding = Encoding.UTF8,
					StandardOutputEncoding = Encoding.UTF8,
				};
			foreach (var extraEnvVariable in extraEnvVariables ?? new Dictionary<string, string>())
			{
				startInfo.EnvironmentVariables[extraEnvVariable.Key] = extraEnvVariable.Value;
			}
			var proc = new Process
			{
				StartInfo = startInfo
			};

			var outputString = new StringWriter();
			proc.Start();
			var errorBuilder = new StringBuilder();

			var outputWriter = new Thread(() =>
			{
				string line;
				lock (proc)
					while ((line = proc.StandardOutput.ReadLine()) != null)
					{
						Console.WriteLine(line);
						outputString.WriteLine(line);
					}
			});
			var errorWriter = new Thread(() =>
			{
				string line;
				lock (proc)
					while ((line = proc.StandardError.ReadLine()) != null)
					{
						Console.Error.WriteLine(line);
						errorBuilder.AppendLine(line);
					}
			});
			outputWriter.Start();
			errorWriter.Start();
			if (!string.IsNullOrEmpty(errorBuilder.ToString()))
				throw new Exception(errorBuilder.ToString());

			proc.WaitForExit();
			outputWriter.Join();
			errorWriter.Join();

			if (proc.ExitCode != 0)
				throw new Exception(
					string.Format("{0} {1}: {2}", process, args, proc.ExitCode));

			return outputString.ToString();
		}

		private static string CreateArgs(IEnumerable<string> changesets)
		{
			return string.Format("log {0} --no-merges --style xml", string.Join(" ", changesets.Select(c => string.Format("-r {0}", c))));
		}

		private static IEnumerable<string> GetChangesets(string mergedRevisionFile)
		{
			using (var stream = new FileStream(mergedRevisionFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			using(var reader = new StreamReader(stream))
			{
				var fileContents = reader.ReadToEnd();
				var changesets = ChangesetRegex.Matches(fileContents).Cast<Match>().Select(m => m.Value.Substring(m.Value.LastIndexOf(':') + 1).Trim()).ToArray();
				return changesets;
			}
		}
	}
}
