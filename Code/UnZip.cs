using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Ionic.Zip;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			try
			{
				if (args.Length != 2)
				{
					Console.WriteLine("Usage: ExtractZip <zipfile(s)> [<targetDirectory>]");
					return 1;
				}
				var zipFiles = GetFiles(args[0]);
				
				foreach (var zipFile in zipFiles)
				{
					Extract(zipFile, args[1]);
				}

				return 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine("ERROR: " + ex.Message);
				return 0;
			}
		}

		private static IEnumerable<FileInfo> GetFiles(string searchParam)
		{
			if (File.Exists(searchParam))
			{
				return new [] { new FileInfo(searchParam) };
			}
			var searchPath = Path.GetDirectoryName(searchParam).Trim(new [] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar });
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
