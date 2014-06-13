using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using System.Xml.XPath;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			try
			{
				var inputFile = args[0];
				var outputFile = args[1];
				if (File.Exists(outputFile))
					File.Delete(outputFile);

				var xml = ReadXml(inputFile);
				if (xml == null)
					return 0;
				var files = ChangedFiles(xml);

				if (files.Any())
				{
					WriteOutputFile(outputFile, files);
				}
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 1;
			}
			return 0;
		}

		private static void WriteOutputFile(string outputFile, string [] files)
		{
			using (var outputStream = new FileStream(outputFile, FileMode.Create, FileAccess.Write, FileShare.Read))
			using (var outputWriter = new StreamWriter(outputStream))
			{
				foreach (var file in files)
				{
					outputWriter.WriteLine(file);
				}
			}
		}

		private static XDocument ReadXml(string inputFile)
		{
			XDocument returnValue = null;
			using (var input = new FileStream(inputFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			using(var readerInput = new StreamReader(input))
			{
				var xmlData = readerInput.ReadToEnd();
				if(!string.IsNullOrWhiteSpace(xmlData))
					returnValue = XDocument.Parse(xmlData);
			}
			return returnValue;
		}

		private static string[] ChangedFiles(XDocument revisionLog)
		{
			var newRevisions = revisionLog.XPathSelectElements("/log/logentry");

			var returnValue = newRevisions.Select(LogEntry.CreateNew).Where(r => r.FilesModified != null).SelectMany(r => r.FilesModified).ToArray();
			
			return returnValue;
		}
	}
}
