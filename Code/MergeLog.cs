using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using System.Xml.XPath;

namespace ExtractChangesets
{
	class Program
	{
		private static int Main(string[] args)
		{
			try
			{

				var inputFile = args[0];
				var buildLogFile = args[1];

				var xml = ReadXml(inputFile);
				MergeXml(buildLogFile, xml);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 1;
			}
			return 0;
		}

		private static XDocument ReadXml(string inputFile)
		{
			XDocument returnValue;
			using (var input = new FileStream(inputFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			{
				returnValue = XDocument.Load(input);
			}
			return returnValue;
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

			foreach (var logEntry in newRevisions.Select(LogEntry.CreateNew))
			{
				modificationsElement.Add(logEntry.ToXElement());
			}

			logDoc.Save(buildLogFile);
		}
	}
}
