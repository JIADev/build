using System;
using System.Text;
using System.Xml.Linq;
using System.IO;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

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
				document.Declaration.Encoding = "utf-8";
				document.AddFirst(new XProcessingInstruction(
					"xml-stylesheet", string.Format("type=\"text/xsl\" href=\"{0}\"", StyleSheet)));
				document.Save(OutputFileName);
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex.ToString());
				return false;
			}
			return true;
		}
	}
}
