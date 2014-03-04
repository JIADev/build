﻿using System;
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
		
		private static void GenerateXml(string hgExe, string outputFile, IEnumerable<string> changesets)
		{
			var args = CreateArgs(changesets);

			var xmlInput = RunProcess(hgExe, args, Environment.CurrentDirectory);
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
			xDoc.Save(outputFile);
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
