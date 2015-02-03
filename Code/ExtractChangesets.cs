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

namespace j6.BuildTools
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
		
		private static void GenerateXml(string hgExe, string outputFile, string[] changesets)
		{
			var docList = new List<XDocument>();

			if (changesets.Any())
			{
				var args = CreateArgs(changesets);

				foreach (var arg in args)
				{
					var xmlInput = BuildSystem.RunProcess(hgExe, arg, Environment.CurrentDirectory);
					if (string.IsNullOrEmpty(xmlInput))
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
								? string.Empty
								: e.msgElement.Value ?? string.Empty
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
				firstDoc.AddFirst(new XProcessingInstruction("xml-stylesheet", "type=\"text/xsl\" href=\"http://jia-build1.jenkon.com/ccnet/xsl/changelog.xsl\""));
				firstDoc.Save(outputFile);
				return;
			}

			for (var i = 1; i < docList.Count; i++)
			{
				var currentDoc = docList[i];
				var docElements = currentDoc.XPathSelectElements("/log/logentry");
				firstDoc.XPathSelectElement("/log").Add(docElements);
			}
			firstDoc.AddFirst(new XProcessingInstruction("xml-stylesheet", "type=\"text/xsl\" href=\"http://jia-build1.jenkon.com/ccnet/xsl/changelog.xsl\""));
			firstDoc.Save(outputFile);
		}

		private static IEnumerable<string> CreateArgs(string[] changesets)
		{
			var list = new List<string>();
			const int BUFFER_SIZE = 1000;

			for (var i = 0; i < changesets.Length; i += BUFFER_SIZE)
				list.Add(string.Format("log {0} -v --no-merges --style xml", string.Join(" ", changesets.Skip(i).Take(BUFFER_SIZE).Select(c => string.Format("-r {0}", c)))));
			
			return list;
		}

		private static string[] GetChangesets(string mergedRevisionFile)
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
