using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class ExtractChangesets : Task
	{
		static readonly Regex ChangesetRegex = new Regex("^changeset:.*$", RegexOptions.Multiline);

		public string InputFile { get; set; }
		public string OutputFile { get; set; }
		public string PathToHg { get; set; }

		public ExtractChangesets()
		{
			PathToHg = "hg";
		}
		public override bool Execute()
		{
			try
			{
				if (!File.Exists(InputFile))
				{
					Console.WriteLine("InputFile {0} doesn't exist", InputFile);
					return false;
				}
				
				var changesets = GetChangesets(InputFile);
				GenerateXml(PathToHg, OutputFile, changesets);

			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
		}

		private static void GenerateXml(string hgExe, string outputFile, string[] changesets)
		{
			var docList = new List<XDocument>();

			if (changesets.Any())
			{
				var args = CreateArgs(changesets);

				foreach (var arg in args)
				{
					var xmlInput = BuildSystem.RunProcess(hgExe, arg, Environment.CurrentDirectory);
					if (String.IsNullOrEmpty(xmlInput))
						xmlInput = "<log />";
					var xDoc = XDocument.Parse(xmlInput);
					var remove = xDoc.XPathSelectElements("/log/logentry").ToArray()
					                 .Select(le =>
					                         new
						                         {
							                         logEntry = le,
							                         msgElement = le == null
								                                      ? null
								                                      : le.XPathSelectElement("msg")
						                         })
					                 .Select(e => new
						                 {
							                 e.logEntry,
							                 msg = e.msgElement == null
								                       ? String.Empty
								                       : e.msgElement.Value
						                 })
					                 .Where(m => m.msg.Contains("@build")).Select(e => e.logEntry);
					foreach (var entry in remove)
					{
						entry.Remove();
					}
					docList.Add(xDoc);
				}
			}
			if (docList.Count < 1)
				return;

			var firstDoc = docList[0];

			if (docList.Count == 1)
			{
				firstDoc.Save(outputFile);
				return;
			}

			for (var i = 1; i < docList.Count; i++)
			{
				var currentDoc = docList[i];
				var docElements = currentDoc.XPathSelectElements("/log/logentry");
				firstDoc.XPathSelectElement("/log").Add(docElements);
			}
			firstDoc.Save(outputFile);
		}

		private static IEnumerable<string> CreateArgs(string[] changesets)
		{
			var list = new List<string>();
			const int bufferSize = 1000;

			for (var i = 0; i < changesets.Length; i += bufferSize)
				list.Add(String.Format("log {0} -v --no-merges --style xml", String.Join(" ", changesets.Skip(i).Take(bufferSize).Select(c => String.Format("-r {0}", c)))));

			return list;
		}

		private static string[] GetChangesets(string mergedRevisionFile)
		{
			using (var stream = new FileStream(mergedRevisionFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			using (var reader = new StreamReader(stream))
			{
				var fileContents = reader.ReadToEnd();
				var changesets = ChangesetRegex.Matches(fileContents).Cast<Match>().Select(m => m.Value.Substring(m.Value.LastIndexOf(':') + 1).Trim()).ToArray();
				return changesets;
			}
		}
	}
}
