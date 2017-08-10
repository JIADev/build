using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class CopyDiffFiles : Task
	{
		[Required]
		public string Source { get; set; }
		[Required]
		public string Target { get; set; }

		public override bool Execute()
		{
			try
			{
				var sourceDir = new DirectoryInfo(Source);
				var targetDir = new DirectoryInfo(Target);
				if (!sourceDir.Exists)
				{
					Console.Error.WriteLine("Source Directory " + Source + " does not exist!");
					return false;
				}
				CopyIfDifferent(sourceDir, targetDir);
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
		}

		private static void CopyIfDifferent(DirectoryInfo sourceDir, DirectoryInfo targetDir)
		{
			if (!targetDir.Exists)
			{
				Console.WriteLine("Creating target " + targetDir.FullName);
				targetDir.Create();
			}
			var files = sourceDir.GetFiles();
			foreach (var sourceFile in files)
			{
				var targetFile = new FileInfo(Path.Combine(targetDir.FullName, sourceFile.Name));

				if (!targetFile.Exists)
				{
					Console.WriteLine("Copying " + sourceFile.FullName + " to " + targetFile.FullName);
					sourceFile.CopyTo(targetFile.FullName);
					continue;
				}

				if (IsDifferent(sourceFile, targetFile))
				{
					Console.WriteLine("Copying " + sourceFile.FullName + " to " + targetFile.FullName);
					sourceFile.CopyTo(targetFile.FullName, true);
				}
			}
		}

		private static readonly MD5 Hash = MD5.Create();

		private static bool IsDifferent(FileInfo sourceFile, FileInfo targetFile)
		{
			using (var sourceStream = sourceFile.OpenRead())
			using (var targetStream = targetFile.OpenRead())
			{
				var sourceHash = Hash.ComputeHash(sourceStream);
				var targetHash = Hash.ComputeHash(targetStream);

				if (sourceHash.Where((t, i) => t != targetHash[i]).Any())
					return true;
			}
			return false;
		}
	}
}
