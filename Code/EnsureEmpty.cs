using System;
using System.IO;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class EnsureEmpty : Task
	{
		[Required]
		public string FileName { get; set; }
		public bool ShowContents { get; set; }
		public string NotEmptyMessage { get; set; }
		
		public override bool Execute()
		{
			var fileInfo = new FileInfo(FileName);
			if (!fileInfo.Exists)
			{
				Console.Error.WriteLine(string.Format("File {0} does not exist.", fileInfo.FullName));
				return false;
			}

			if (fileInfo.Length == 0)
			{
				// Success!  Empty file
				return true;
			}
			Console.ForegroundColor = ConsoleColor.Red;

			if (NotEmptyMessage != null)
			{
				Console.Error.WriteLine(string.Format("{0}{1}", NotEmptyMessage, Environment.NewLine));
			}
			if (ShowContents)
			{
				using (var fileStream = fileInfo.Open(FileMode.Open, FileAccess.Read, FileShare.Read))
				using (var fileInput = new StreamReader(fileStream))
				{
					Console.Error.Write(fileInput.ReadToEnd());
				}
			}
			Console.ResetColor();
			var returnValue = (int)(fileInfo.Length % int.MaxValue);
			return returnValue == 0;
		}
	}
}
