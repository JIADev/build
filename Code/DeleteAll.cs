using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools
{
	class Program
	{
		private static bool _verbose;
		
		private static int Main(string[] args)
		{
			try
			{
				_verbose = args.Any(a => a.Equals("--verbose", StringComparison.InvariantCultureIgnoreCase));

				var repoRoot = FindRepoRoot(new DirectoryInfo(Environment.CurrentDirectory));
				if (repoRoot == null)
				{
					Console.WriteLine("Must be in a mercurial repository.");
					return 2;
				}

				var junctionsDeleted = DeleteJunctions(repoRoot);
				Console.WriteLine("Deleted {0} junctions.", junctionsDeleted);

				var deleted = DeleteDirectories(repoRoot, new[] {".hg"});

				Console.WriteLine("Deleted {0} files and {1} directories.",
				                  deleted[typeof(FileInfo)],
				                  deleted[typeof(DirectoryInfo)]);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}

		private static Dictionary<Type, int> DeleteDirectories(DirectoryInfo directory, string[] exclude)
		{
			var fsInfos = directory.GetFileSystemInfos();
			var returnValue = new Dictionary<Type, int>
				{
					{typeof (FileInfo), 0},
					{typeof (DirectoryInfo), 0}
				};
			foreach (var fsInfo in fsInfos)
			{
				if(exclude != null && exclude.Contains(fsInfo.Name, StringComparer.InvariantCultureIgnoreCase))
					continue;
				
				var file = fsInfo as FileInfo;
				var subDir = fsInfo as DirectoryInfo;
				
				if (file != null && file.Exists)
				{
					returnValue[typeof (FileInfo)]++;
					file.Delete();
				}

				if (subDir == null || !subDir.Exists) continue;

				var subResults = DeleteDirectories(subDir, exclude);
				returnValue[typeof (FileInfo)] += subResults[typeof (FileInfo)];
				returnValue[typeof (DirectoryInfo)] += subResults[typeof (DirectoryInfo)];
			}
			if (!directory.GetFileSystemInfos().Any())
			{
				directory.Delete(false);
				returnValue[typeof (DirectoryInfo)]++;
			}
			return returnValue;
		}

		private static int DeleteJunctions(DirectoryInfo directory)
		{
			if (directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
			{
				if(_verbose)
					Console.WriteLine(string.Format("Deleting Junction {0}", directory));
				directory.Delete();
				return 1;
			}
			return directory.GetDirectories().Sum(dir => DeleteJunctions(dir));
		}

		private static DirectoryInfo FindRepoRoot(DirectoryInfo directory)
		{
			var hasHgDirectory =
				directory.GetDirectories(".hg").Any(d => d.Name.Equals(".hg", StringComparison.InvariantCultureIgnoreCase));
			if (hasHgDirectory)
				return directory;

			if (directory.Parent != null && directory.Parent.Exists)
				return FindRepoRoot(directory.Parent);

			return null;
		}
	}
}
