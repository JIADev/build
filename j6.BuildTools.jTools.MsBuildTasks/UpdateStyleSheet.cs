using System;
using System.Text;
using System.Xml.Linq;
using System.IO;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Diagnostics;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class UpdateStyleSheet : Task
	{
		[Required]
		public string InputFileName { get; set; }
		[Required]
		public string StyleSheet { get; set; }
		public string OutputFileName { get; set; }

		public override bool Execute()
		{
			var logInfo = new FileInfo(InputFileName);

			if (!logInfo.Exists || logInfo.Length == 0)
			{
				Console.Error.WriteLine(string.Format("Input file {0} does not exist or is empty.", InputFileName));
				return false;
			}
			if (string.IsNullOrWhiteSpace(OutputFileName))
				OutputFileName = InputFileName;
			try
			{
				XDocument document;
				using (var reader = new StreamReader(logInfo.FullName, Encoding.UTF8))
					document = XDocument.Load(reader);
				AddStyleSheet(document, StyleSheet);
				document.Save(OutputFileName);
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex.ToString());
				return false;
			}
			return true;
		}

		public static void AddStyleSheet(XDocument document, string styleSheet)
		{
			document.Declaration.Encoding = "utf-8";
			XDocument styleDoc;
			using (var reader = new StreamReader(styleSheet, Encoding.UTF8))
				styleDoc = XDocument.Load(reader);
			var log = document.Root;
			// ReSharper disable PossibleNullReferenceException
			log.AddFirst(styleDoc.Root);
			// ReSharper restore PossibleNullReferenceException
			document.AddFirst(new XProcessingInstruction("xml-stylesheet", "type=\"text/xsl\" href=\"#changelogStyle\""));
			document.AddFirst(new XDocumentType("browsers", null, null, "<!ATTLIST xsl:stylesheet id ID #REQUIRED>"));
			
		}
	}
}
