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
					Console.WriteLine("Usage ExtractChangesets.exe <mergedRevisions.txt.file> <outputFile.xml> <ccnetLogFile.xml> [<path.to.hg.exe>] (defaults to {0})",
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
				string buildLogFile = null;

				if (args.Length > 1)
				{
					outputFile = args[1];
				}

				if (args.Length > 2)
				{
					buildLogFile = args[2];
				}

				if (args.Length > 3)
				{
					hgExe = args[3];
				}

				var changesets = GetChangesets(mergedRevisionFile);
				var xml = GenerateXml(hgExe, outputFile, changesets);
				if (buildLogFile != null)
					MergeXml(buildLogFile, xml);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}

		private static void MergeXml(string buildLogFile, XDocument revisionLog)
		{
			XDocument logDoc;
			using (var logFile = new FileStream(buildLogFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			{
				logDoc = XDocument.Load(logFile);
			}
			var mods = logDoc.XPathSelectElements("/cruisecontrol/modifications/modification").ToArray();
			mods.Remove();

			var modificationsElement = logDoc.XPathSelectElement("/cruisecontrol/modifications");
			
			var newRevisions = revisionLog.XPathSelectElements("/log/logentry");
			
			foreach (var logEntry in newRevisions.Select(CreateLogEntry))
			{
				modificationsElement.Add(logEntry.ToXElement());
			}
			
			logDoc.Save(buildLogFile);
		}

		private class LogEntry
		{
			// ReSharper disable UnusedAutoPropertyAccessor.Local
			// ReSharper disable MemberCanBePrivate.Local
			public int? Revision { get; set; }
			public string Node { get; set; }
			public string ParentRevision { get; set; }
			public string ParentNode { get; set; }
			public string Branch { get; set; }
			public string Author { get; set; }
			public string Email { get; set; }
			public DateTime? Date { get; set; }
			public string Msg { get; set; }
			// ReSharper restore MemberCanBePrivate.Local
			// ReSharper restore UnusedAutoPropertyAccessor.Local

			public XElement ToXElement()
			{
				var returnValue = new XElement("modification");
				
				returnValue.Add(new XAttribute("type", "Changeset"));

				if(Date.HasValue)
					returnValue.Add(CreateElement("date", Date.Value.ToString("yyyy-MM-dd HH:mm:ss")));
				
				if(!string.IsNullOrWhiteSpace(Author))
					returnValue.Add(CreateElement("user", Author));
				
				if(!string.IsNullOrWhiteSpace(Msg))
					returnValue.Add(CreateElement("comment", Msg));
				
				if (!string.IsNullOrWhiteSpace(Node))
				{
					returnValue.Add(Node.Length > 12
						? CreateElement("changeNumber", Node.Substring(0, 12))
						: CreateElement("changeNumber", Node));
				}

				if(!string.IsNullOrWhiteSpace(Node))
					returnValue.Add(CreateElement("version", Node));
				
				if(!string.IsNullOrWhiteSpace(Email))
					returnValue.Add(CreateElement("email", Email));
				
				return returnValue;
			}

			private XElement CreateElement(string elementName, string innerText)
			{
				var newElement = new XElement(elementName);
				newElement.SetValue(innerText);
				return newElement;
			}
		}

		private static LogEntry CreateLogEntry(XElement logEntryElement)
		{
			var author = logEntryElement.XPathSelectElement("author");
			var email = author == null ? null : author.Attribute("email");
			var parent = logEntryElement.XPathSelectElement("parent");
			var parentRevision = parent == null ? null : parent.Attribute("revision");
			var parentNode = parent == null ? null : parent.Attribute("node");
			var revision = logEntryElement.Attribute("revision");
			var node = logEntryElement.Attribute("node");
			var branch = logEntryElement.XPathSelectElement("branch");
			var date = logEntryElement.XPathSelectElement("date");

			var returnValue = new LogEntry
			{
				Revision = revision == null ? null : (int?)int.Parse(revision.Value),
				Node = node == null ? null : node.Value,
				Branch = branch == null ? null : branch.Value,
				ParentRevision = parentRevision == null ? null : parentRevision.Value,
				ParentNode = parentNode == null ? null : parentNode.Value,
				Author = author == null ? null : author.Value,
				Email = email == null ? null : email.Value,
				Date = date == null ? null : (DateTime?)DateTime.Parse(date.Value),
				Msg = logEntryElement.XPathSelectElement("msg").Value
			};
			return returnValue;
		}

		private static XDocument GenerateXml(string hgExe, string outputFile, IEnumerable<string> changesets)
		{
			var args = CreateArgs(changesets);

			var xmlInput = RunProcess(hgExe, args, Environment.CurrentDirectory, true, outputFile);
			var xDoc = XDocument.Parse(xmlInput);
			return xDoc;
		}

		private static string RunProcess(string process,
			string args,
			string workingDirectory,
			bool waitForExit,
			string outputFileName = null,
			Dictionary<string, string> extraEnvVariables = null)
		{
			waitForExit = waitForExit || outputFileName != null;
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
			var outputFile = (outputFileName == null
				? null
				: new FileStream(outputFileName, FileMode.Create, FileAccess.Write, FileShare.Read));
			
			var outputTextWriter = (outputFile == null ? Console.Out : new StreamWriter(outputFile));
			var outputString = new StringWriter();
			try
			{
				proc.Start();
				var errorBuilder = new StringBuilder();

				var outputWriter = new Thread(() =>
				{
					string line;
					lock (proc)
						while ((line = proc.StandardOutput.ReadLine()) != null)
						{
							outputTextWriter.WriteLine(line);
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
				if (waitForExit)
				{
					proc.WaitForExit();
					outputWriter.Join();
					errorWriter.Join();
				}
				if (proc.ExitCode != 0)
					throw new Exception(
						string.Format("{0} {1}: {2}", process, args, proc.ExitCode));
			}
			finally
			{
				outputTextWriter.Flush();
				if (outputFile != null)
				{
					outputFile.Flush();
					outputFile.Dispose();
				}
			}
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
