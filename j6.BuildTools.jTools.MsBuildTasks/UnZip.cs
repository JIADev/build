using System;
using System.Collections.Generic;
using System.IO;
using Ionic.Zip;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class UnZip : Task
	{
		[Required]
		public string ZipFiles { get; set; }
		[Required]
		public string TargetDirectory { get; set; }
		
		public override bool Execute()
		{
			try
			{
				var zipFiles = GetFiles(ZipFiles);

				foreach (var zipFile in zipFiles)
				{
					Extract(zipFile, TargetDirectory);
				}

				return true;
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine("ERROR: " + ex.Message);
				return false;
			}
		}

		private static IEnumerable<FileInfo> GetFiles(string searchParam)
		{
			if (File.Exists(searchParam))
			{
				return new[] { new FileInfo(searchParam) };
			}
			var directoryName = Path.GetDirectoryName(searchParam);
			
			if (directoryName == null)
				return new FileInfo[0];
			
			var searchPath = directoryName.Trim(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar });
			var searchText = searchParam.Substring(searchPath.Length).Trim(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar });
			var searchDir = new DirectoryInfo(searchPath);
			var files = searchDir.GetFiles(searchText);
			return files;
		}

		private static void Extract(FileInfo zipFileInfo, string targetDirectory)
		{
			var targetDir = new DirectoryInfo(targetDirectory);
			if (!targetDir.Exists)
			{
				Console.WriteLine("Creating " + targetDirectory);
				targetDir.Create();
			}

			using (var zipFile = ZipFile.Read(zipFileInfo.FullName))
			{
				Console.WriteLine("Extracting " + zipFileInfo.FullName + " to " + targetDir.FullName);
				zipFile.ExtractAll(targetDir.FullName);
			}
		}
	}
}
