using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class ChangedFiles : Task
	{
		[Required]
		public string InputFile { get; set; }
		[Required]
		public string OutputFile { get; set; }

		public override bool Execute()
		{
			try
			{
				if (File.Exists(OutputFile))
					File.Delete(OutputFile);

				var xml = ReadXml(InputFile);
				if (xml == null)
					return true;
				var files = GetChangedFiles(xml);

				if (files.Any())
				{
					WriteOutputFile(OutputFile, files);
				}
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
		}

		private static void WriteOutputFile(string outputFile, IEnumerable<string> files)
		{
			using (var outputStream = new FileStream(outputFile, FileMode.Create, FileAccess.Write, FileShare.Read))
			using (var outputWriter = new StreamWriter(outputStream))
			{
				foreach (var file in files)
					outputWriter.WriteLine(file);
			}
		}

		private static XDocument ReadXml(string inputFile)
		{
			XDocument returnValue = null;
			using (var input = new FileStream(inputFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			using (var readerInput = new StreamReader(input))
			{
				var xmlData = readerInput.ReadToEnd();
				if (!String.IsNullOrWhiteSpace(xmlData))
					returnValue = XDocument.Parse(xmlData);
			}
			return returnValue;
		}

		private static string[] GetChangedFiles(XDocument revisionLog)
		{
			var newRevisions = revisionLog.XPathSelectElements("/log/logentry");

			var returnValue = newRevisions.Select(LogEntry.CreateNew).Where(r => r.FilesModified != null).SelectMany(r => r.FilesModified).ToArray();

			return returnValue;
		}
	}
}
