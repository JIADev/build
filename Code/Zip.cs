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
				if (args.Length < 2)
				{
					Console.WriteLine("Usage: Zip <directory> <zipFileName>");
					return 1;
				}
				var zipFile = new FileInfo(args[1]);
				var zipDirectory = new DirectoryInfo(args[0]);
				CreateZip(zipFile, zipDirectory);
				return 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine("ERROR: " + ex.Message);
				return 255;
			}
		}

		private static void CreateZip(FileInfo zipFileInfo, DirectoryInfo zipDirectoryInfo)
		{
			using (var zipFile = new ZipFile())
			{
				foreach (var directory in zipDirectoryInfo.GetDirectories())
				{
					Console.WriteLine("Zipping " + directory.FullName);
					zipFile.AddDirectory(directory.FullName, directory.Name);
				}
				var files = zipDirectoryInfo.GetFiles().Select(f => f.FullName).ToArray();
				foreach (var file in files)
				{
					Console.WriteLine("Zipping " + file);
				}
				zipFile.AddFiles(files, false, "\\");
				var bootstrapDir = zipDirectoryInfo.GetDirectories("Bootstrap").SingleOrDefault(d => d.Name.Equals("Bootstrap", StringComparison.InvariantCultureIgnoreCase));
				
				if (bootstrapDir != null && bootstrapDir.GetFiles("install.exe", SearchOption.TopDirectoryOnly).SingleOrDefault() != null)
				{
					zipFileInfo = new FileInfo(zipFileInfo.FullName.Replace(".zip", ".exe"));
					zipFile.SaveSelfExtractor(zipFileInfo.FullName,
					                          new SelfExtractorSaveOptions
						                          {
							                          Flavor = SelfExtractorFlavor.WinFormsApplication,
							                          RemoveUnpackedFilesAfterExecute = true,
							                          PostExtractCommandLine = "Bootstrap\\Install.exe"
						                          });
				}
				else
					zipFile.Save(zipFileInfo.FullName);
			}
			Console.WriteLine("Created " + zipFileInfo.FullName);
		}
	}
}
