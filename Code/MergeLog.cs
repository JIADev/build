using System;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class MergeLog : Task
	{
		[Required]
		public string InputFile { get; set; }
		[Required]
		public string BuildLogFile { get; set; }
		
		public override bool Execute()
		{
			try
			{
				var xml = ReadXml(InputFile);
				MergeXml(BuildLogFile, xml);
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
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

			foreach (var logEntry in newRevisions.Select(LogEntry.CreateNew).Where(r => r.FilesModified != null && r.FilesModified.Any()))
			{
				modificationsElement.Add(logEntry.ToXElement());
			}

			logDoc.Save(buildLogFile);
		}
	}
}
