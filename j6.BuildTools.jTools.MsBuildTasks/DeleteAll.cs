using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class DeleteAll : Task
	{
		public bool Verbose { get; set; }
		[Required]
		public string BaseDirectory { get; set; }

		enum FileType
		{
			File,
			Directory,
			Junction
		}
		
		public override bool Execute()
		{
			try
			{
				var repoRoot = FindRepoRoot(new DirectoryInfo(BaseDirectory), ".hg");
				if (repoRoot == null)
				{
					repoRoot = FindRepoRoot(new DirectoryInfo(BaseDirectory), ".git");
				    if (repoRoot == null)
				    {
				        Console.Error.WriteLine("Must be in a mercurial or git repository.");
				        return false;
				    }
				}

				var deleted = DeleteDirectories(repoRoot, new[] { ".hg", ".git" });

				Console.WriteLine("Deleted {0} files, {1} junctions, and {2} directories.",
								  deleted[FileType.File],
								  deleted[FileType.Junction],
								  deleted[FileType.Directory]);
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
		}
		private Dictionary<FileType, int> DeleteDirectories(DirectoryInfo directory, string[] exclude)
		{
			var returnValue = new Dictionary<FileType, int>
				{
					{ FileType.File, 0 },
					{ FileType.Junction, 0 },
					{ FileType.Directory, 0 }
				};
			foreach (var fsInfo in directory.GetFileSystemInfos())
			{
				if (exclude != null && exclude.Contains(fsInfo.Name, StringComparer.InvariantCultureIgnoreCase))
					continue;

				var file = fsInfo as FileInfo;
				var subDir = fsInfo as DirectoryInfo;

				if (file != null && file.Exists)
				{
					file.Delete();
					if (Verbose)
						Console.WriteLine(string.Format("Deleted {0}", file.FullName));
					returnValue[FileType.File]++;
				}

				if (subDir == null || !subDir.Exists) continue;

				if (subDir.Attributes.HasFlag(FileAttributes.ReparsePoint))
				{
					subDir.Delete();
					if (Verbose)
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
				if (Verbose)
					Console.WriteLine(string.Format("Deleted {0}", directory.FullName));
				returnValue[FileType.Directory]++;
			}
			return returnValue;
		}

		private static DirectoryInfo FindRepoRoot(DirectoryInfo directory, string repoRootDirectory)
		{
			var hasRepoRootDirectory =
				directory.GetDirectories(repoRootDirectory).Any(d => d.Name.Equals(repoRootDirectory, StringComparison.InvariantCultureIgnoreCase));
			if (hasRepoRootDirectory)
				return directory;

			if (directory.Parent != null && directory.Parent.Exists)
				return FindRepoRoot(directory.Parent, repoRootDirectory);

			return null;
		}
	}
}
