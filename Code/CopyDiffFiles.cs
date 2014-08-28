using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;

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
					Console.WriteLine("Usage: CopyDiffFiles <sourceDirectory> <targetDirectory>");
					return 2;
				}
				var source = args[0];
				var target = args[1];

				var sourceDir = new DirectoryInfo(source);
				var targetDir = new DirectoryInfo(target);
				if (!sourceDir.Exists)
				{
					Console.WriteLine("Source Directory " + source + " does not exist!");
					return 3;
				}
				CopyIfDifferent(sourceDir, targetDir);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 1;
			}
			return 0;
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
			using(var sourceStream = sourceFile.OpenRead())
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
