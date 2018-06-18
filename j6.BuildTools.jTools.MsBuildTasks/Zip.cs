using System;
using System.IO;
using System.Linq;
using Ionic.Zip;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class Zip : Task
	{
		[Required]
		public string Directory { get; set; }
		[Required]
		public string FileName { get; set; }

		public override bool Execute()
		{
			try
			{
				
				var zipFile = new FileInfo(FileName);
				var zipDirectory = new DirectoryInfo(Directory);
				CreateZip(zipFile, zipDirectory);
				return true;
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine("ERROR: " + ex.Message);
				return false;
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
