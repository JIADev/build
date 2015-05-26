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
		enum FileType
		{
			File,
			Directory,
			Junction
		}
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

				var deleted = DeleteDirectories(repoRoot, new[] {".hg"});

				Console.WriteLine("Deleted {0} files, {1} junctions, and {2} directories.",
				                  deleted[FileType.File],
				                  deleted[FileType.Junction],
								  deleted[FileType.Directory]);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}

		private static Dictionary<FileType, int> DeleteDirectories(DirectoryInfo directory, string[] exclude)
		{
			var fsInfos = directory.GetFileSystemInfos();
			var returnValue = new Dictionary<FileType, int>
				{
					{ FileType.File, 0 },
					{ FileType.Junction, 0 },
					{ FileType.Directory, 0 }
				};
			foreach (var fsInfo in fsInfos)
			{
				if(exclude != null && exclude.Contains(fsInfo.Name, StringComparer.InvariantCultureIgnoreCase))
					continue;
				
				var file = fsInfo as FileInfo;
				var subDir = fsInfo as DirectoryInfo;
				
				if (file != null && file.Exists)
				{
					file.Delete();
					if(_verbose)
						Console.WriteLine(string.Format("Deleted {0}", file.FullName));
					returnValue[FileType.File]++;
				}

				if (subDir == null || !subDir.Exists) continue;

				if (subDir.Attributes.HasFlag(FileAttributes.ReparsePoint))
				{
					subDir.Delete();
					if (_verbose)
						Console.WriteLine(string.Format("Deleted Junction {0}", subDir));
					returnValue[FileType.Junction]++;
					continue;
				}

				var subResults = DeleteDirectories(subDir, exclude);
				returnValue[FileType.File] += subResults[FileType.File];
				returnValue[FileType.Junction] += subResults[FileType.Junction];
				returnValue[FileType.Directory] += subResults[FileType.Directory];
			}
			if (!directory.GetFileSystemInfos().Any())
			{
				directory.Delete(false);
				if (_verbose)
					Console.WriteLine(string.Format("Deleted {0}", directory.FullName));
				returnValue[FileType.Directory]++;
			}
			return returnValue;
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
