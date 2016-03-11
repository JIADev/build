using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using Ionic.Zip;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class Protect : Task
	{
		[Required]
		public string BaseDir { get; set; }
		[Required]
		public string DriverFeature { get; set; }

		public override bool Execute()
		{
			try
			{
				ExecuteProtect(BaseDir, DriverFeature);

			}
			catch (Exception ex)
			{
				Console.Error.WriteLine("ERROR: " + ex.Message);
				return false;
			}

			return true;
		}

		private static void ExecuteProtect(string baseDir, string driverFeature)
		{
			const string unprotected = "-UNPROTECTED";
			var releaseDir = new DirectoryInfo(baseDir);

			ProtectAll(driverFeature, releaseDir);

			if (releaseDir.FullName.EndsWith(unprotected, StringComparison.InvariantCultureIgnoreCase))
			{
				var newDirName = releaseDir.FullName.Substring(0, releaseDir.FullName.Length - unprotected.Length);
				Console.WriteLine(String.Format("Renaming {0} to {1}", releaseDir.FullName, newDirName));
				releaseDir.MoveTo(newDirName);
			}
		}

		public static void ProtectAll(string driverFeature, DirectoryInfo baseDir, int maxRetries = 1)
		{
			var root = baseDir.Root;

			var tempDir = Path.Combine(root.FullName, "temp", Guid.NewGuid().ToString().Split(new[] { '-' }, StringSplitOptions.RemoveEmptyEntries).First());

			try
			{
				if (Directory.Exists(tempDir))
				{
					Console.WriteLine(String.Format("Deleting: {0}", tempDir));
					Directory.Delete(tempDir, true);
				}

				Directory.CreateDirectory(tempDir);

				Console.WriteLine(String.Format("Reading: {0}", baseDir.FullName));
				var zipFiles = ExtractZips(baseDir, tempDir);
				var assembliesToVeil = GetAssembliesToVeil(driverFeature, baseDir);
				var distinctFiles = GetDistinctFiles(assembliesToVeil, tempDir);
				var targets = String.Join(";", distinctFiles.Keys.ToArray());
				var args = "/Secure /Target:" + targets;
				try
				{
					BuildSystem.RunProcess("AgileDotNet.Console.exe", args, baseDir.FullName, null, 120);
				}
				catch (TimeoutException)
				{
					if (maxRetries == 0)
						throw;

					ProtectAll(driverFeature, baseDir, maxRetries - 1);
					return;
				}
				catch (Exception ex)
				{
					Console.Error.WriteLine("ERROR: " + ex);
					throw;
				}
				foreach (var veiledFile in distinctFiles)
				{
					foreach (var targetFile in veiledFile.Value.Select(f => f.FullName).ToArray())
					{
						Console.WriteLine(String.Format("Overwriting {0}", targetFile));
						File.Copy(veiledFile.Key, targetFile, true);
					}
				}
				RecreateZips(zipFiles);
			}
			catch (Exception ex1)
			{
				Console.WriteLine("ERROR: " + ex1);
				throw;
			}
			finally
			{
				if (Directory.Exists(tempDir))
				{
					Console.WriteLine(String.Format("Deleting: {0}", tempDir));
					Directory.Delete(tempDir, true);
				}
			}
		}

		private static void RecreateZips(Dictionary<FileInfo, DirectoryInfo> zipFiles)
		{
			foreach (var zip in zipFiles)
			{
				var zipFileInfo = zip.Key;
				var zipDirectoryInfo = zip.Value;
				Console.WriteLine(String.Format("Recreating file {0} from {1}", zipFileInfo.Name, zipDirectoryInfo.FullName));
				using (var zipFile = new ZipFile())
				{
					foreach (var directory in zipDirectoryInfo.GetDirectories())
					{
						Console.WriteLine(String.Format("Zipping {0}", directory.FullName));
						zipFile.AddDirectory(directory.FullName, directory.Name);
					}
					zipFile.AddFiles(zipDirectoryInfo.GetFiles().Select(f => f.FullName), false, "\\");
					zipFile.Save(zipFileInfo.FullName);
				}
				Console.WriteLine(String.Format("Closing file {0}", zipFileInfo.FullName));
			}
		}

		private static Dictionary<FileInfo, DirectoryInfo> ExtractZips(DirectoryInfo baseDir, string tempDir)
		{
			var zipFileInfos = baseDir.GetFiles("*.zip", SearchOption.AllDirectories);
			var extractedList = new Dictionary<FileInfo, DirectoryInfo>();
			foreach (var zipFileInfo in zipFileInfos)
			{
				var extractedDirectory = Path.Combine(tempDir, zipFileInfo.Name.Substring(0, zipFileInfo.Name.Length - ".zip".Length));
				Console.WriteLine(String.Format("Extracting: {0} to {1}", zipFileInfo.FullName, extractedDirectory));
				using (var zipFile = ZipFile.Read(zipFileInfo.FullName))
					zipFile.ExtractAll(extractedDirectory);
				extractedList.Add(zipFileInfo, new DirectoryInfo(extractedDirectory));
			}
			return extractedList;
		}

		private static IEnumerable<FileInfo> GetAssembliesToVeil(string driverFeature, DirectoryInfo dirInfo)
		{
			var startsWith = new[]
				{
					"Jenkon.", "J6.", "IH", driverFeature
				};
			// AND
			var endsWith = new[]
				{
					".dll"
				};
			// AND
			var notEqualTo = new[] { "j6.Core.Logic.dll" };

			return (from f in dirInfo.GetFiles("*.*", SearchOption.AllDirectories)
			        where startsWith.Any(s => f.Name.StartsWith(s, StringComparison.InvariantCultureIgnoreCase)) &&
			              endsWith.Any(e => f.Name.EndsWith(e, StringComparison.InvariantCultureIgnoreCase)) &&
			              !notEqualTo.Any(n => f.Name.Equals(n, StringComparison.InvariantCultureIgnoreCase))
			        select f).ToList();
		}

		private static Dictionary<string, FileInfo[]> GetDistinctFiles(IEnumerable<FileInfo> assembliesToVeil, string tempDir)
		{
			var returnValue = new Dictionary<string, FileInfo[]>(StringComparer.InvariantCultureIgnoreCase);
			using (var md5 = MD5.Create())
			{
				var md5Dictionary =
					assembliesToVeil.Select(a => new { OriginalFile = a, MD5 = GetMd5(a, md5), a.Length })
					                .GroupBy(a => new { MD5 = string.Join("", a.MD5.Select(c => c.ToString("x")).ToArray()), a.Length })
					                .ToDictionary(a => a.Key, a => a.Select(f => f.OriginalFile).ToArray());

				foreach (var entry in md5Dictionary)
				{
					var firstFile = entry.Value.First();
					var tempFile = Path.Combine(tempDir,
					                            String.Format("{0}_{1}_{2}{3}", firstFile.Name, entry.Key.MD5, entry.Key.Length, firstFile.Extension));
					returnValue.Add(tempFile, entry.Value);
					firstFile.CopyTo(tempFile);
				}
			}
			Console.WriteLine(String.Format("{0} distinct files to secure: {1}", returnValue.Count, String.Join(", ", returnValue.Select(r => r.Key).ToArray())));
			return returnValue;

		}

		private static byte[] GetMd5(FileInfo a, HashAlgorithm md5)
		{
			using (var file = a.OpenRead())
				return md5.ComputeHash(file);
		}
	}
}
