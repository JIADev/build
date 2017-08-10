using System;
using System.Diagnostics;
using System.IO;
using Microsoft.Build.Utilities;
// ReSharper disable InconsistentNaming

namespace j6.BuildTools.MsBuildTasks
{
	public class ResetXmlEncoding : Task
	{
		private const string XML_FILE_COUNT = "XmlFileCount";

		public string Sources { get; set; }

		public override bool Execute()
		{
			var tl = new ConsoleTraceListener();
			Trace.Listeners.Add(tl);
			var sourceDirs = Sources.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);
			var sourceDir = new DirectoryInfo(sourceDirs.Length > 0 ? sourceDirs[0] : Environment.CurrentDirectory);
			var enumerator = new FileEnumerator();
			enumerator.FileFound += ConvertToText;
			enumerator.EnumerationComplete += sender => Trace.WriteLine(string.Format("Found {0} xml files:",
																					  sender.Data.ContainsKey(
																						  XML_FILE_COUNT)
																						  ? sender.Data[XML_FILE_COUNT]
																						  : 0));

			enumerator.TraverseDirectory(sourceDir);
			return true;
		}

		private static void ConvertToText(FileEnumerator sender, FileInfo fInfo)
		{
			if (!fInfo.Extension.Equals(".xml", StringComparison.InvariantCultureIgnoreCase) || fInfo.Name.ToLowerInvariant().Contains("resource"))
				return;
			var xmlFileCount = sender.Data.ContainsKey(XML_FILE_COUNT) ? (int)sender.Data[XML_FILE_COUNT] : 0;
			xmlFileCount++;
			sender.Data[XML_FILE_COUNT] = xmlFileCount;
			Trace.Write(string.Format("({0}) {1}...", xmlFileCount, fInfo.FullName));
			ConvertToText(fInfo);
			Trace.WriteLine("Done");
		}

		private static void ConvertToText(FileInfo xmlFile)
		{
			using (var ms = new MemoryStream())
			using (var sw = new StreamWriter(ms))
			{
				using (var fs = new FileStream(xmlFile.FullName, FileMode.Open, FileAccess.Read, FileShare.Read))
				using (var sr = new StreamReader(fs))
				{
					while (!sr.EndOfStream)
					{
						string input = sr.ReadLine();
						sw.WriteLine(input);
					}
				}
				sw.Flush();
				ms.Seek(0, SeekOrigin.Begin);

				using (var fs = new FileStream(xmlFile.FullName, FileMode.Create, FileAccess.Write, FileShare.Read))
				using (var fsw = new StreamWriter(fs))
				using (var msr = new StreamReader(ms))
				{
					while (!msr.EndOfStream)
					{
						string input = msr.ReadLine();
						fsw.WriteLine(input);
					}
					fsw.Flush();
				}
			}

		}
	}
}
