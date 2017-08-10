using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class RevertAll : Task
	{
		public bool Verbose { get; set; }
		[Required]
		public string BaseDirectory { get; set; }

		public override bool Execute()
		{
			try
			{
				var repoRoot = FindRepoRoot(new DirectoryInfo(BaseDirectory));
				if (repoRoot == null)
				{
					Console.Error.WriteLine("Must be in a mercurial repository.");
					return false;
				}
				string[] pathTooLong;
				var junctionsDeleted = DeleteJunctions(repoRoot.FullName, out pathTooLong);
				Console.WriteLine("Deleted {0} junctions.", junctionsDeleted);
				var directoriesDeleted = DeleteTooLong(repoRoot.FullName, pathTooLong);

				var hgIgnoreFile = repoRoot.GetFiles(".hgignore").Where(f => f.Exists && f.Name.Equals(".hgignore", StringComparison.InvariantCultureIgnoreCase)).Select(f => f.FullName).SingleOrDefault();
				var tmpIgnoreFile = Path.Combine(repoRoot.FullName, string.Format("{0}.hgignore", Guid.NewGuid()));

				if (hgIgnoreFile != null)
					File.Move(hgIgnoreFile, tmpIgnoreFile);

				const string hgExe = "hg";
				var files = GetHgStatFiles(hgExe, repoRoot, tmpIgnoreFile).ToArray();

				if (hgIgnoreFile != null)
					File.Move(tmpIgnoreFile, hgIgnoreFile);

				var fileCount = new IndexObject();
				var filePathTooLong = files.Where(f => f.Length >= 248).ToArray();
				directoriesDeleted += DeleteTooLong(repoRoot.FullName, filePathTooLong);
				Console.WriteLine("Deleted {0} total directories with path names too long", directoriesDeleted);

				files.AsParallel().ForAll(file =>
				{
					if (!File.Exists(file))
						return;
					if (Verbose)
						Console.WriteLine(string.Format("Deleting {0}", file));
					File.Delete(file);
					lock (fileCount)
						fileCount.Count++;
				});

				Console.WriteLine(string.Format("Deleted {0} files.", fileCount.Count));
				ExecuteRevertAll(hgExe, repoRoot);

				var emptyDirectories = DeleteEmptyDirectories(repoRoot);
				Console.WriteLine(string.Format("Deleted {0} empty directories.", emptyDirectories));
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex);
				return false;
			}
			return true;
		}

		private int DeleteTooLong(string repoRoot, string[] pathTooLong)
		{
			var pathNotTooLong =
					pathTooLong.Select(p => FindParentNotTooLong(repoRoot, p)).Distinct(StringComparer.InvariantCultureIgnoreCase).ToArray();
			var deleted = 0;
			foreach (var notTooLong in pathNotTooLong)
			{
				try
				{
					var newName = string.Format("{0}\\{1}.ptl", repoRoot, Path.GetFileName(notTooLong));
					while (Directory.Exists(newName))
					{
						newName = newName + ".ptl";
					}
					if(Verbose)
						Console.WriteLine(string.Format("Moving {0} to {1}", notTooLong, newName));
					Directory.Move(notTooLong, newName);
					if(Verbose)
						Console.WriteLine(string.Format("Deleting {0}", newName));
					Directory.Delete(newName, true);
					deleted++;
				}
				catch (DirectoryNotFoundException)
				{
				}
			}
			return deleted;

		}

		private class IndexObject
		{
			public int Count { get; set; }
		}
		private int DeleteJunctions(string directoryName, out string[] pathTooLong)
		{
			var ptl = new List<string>();
			var directory = new DirectoryInfo(directoryName);
			if (directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
			{
				if (Verbose)
					Console.WriteLine(string.Format("Deleting Junction {0}", directory));
				directory.Delete();
				pathTooLong = ptl.ToArray();
				return 1;
			}
			var dirCount = new IndexObject();
			string[] subDirs;

			try
			{
				subDirs = directory.GetDirectories().Select(d =>
				{
					try
					{
						return d.FullName;
					}
					catch (PathTooLongException)
					{
						ptl.Add(directoryName);
						return null;
					}
				}
					).Where(d => !string.IsNullOrWhiteSpace(d)).ToArray();
			}
			catch (PathTooLongException)
			{
				ptl.Add(directoryName);
				subDirs = new string[0];
			}

			foreach (var dir in subDirs)
			{
				string[] subptl;
				var count = DeleteJunctions(dir, out subptl);
				lock (dirCount)
					dirCount.Count += count;
				ptl.AddRange(subptl);
			}
			pathTooLong = ptl.ToArray();
			return dirCount.Count;
		}

		private static string FindParentNotTooLong(string repoRoot, string directory)
		{
			var current = directory;
			var max = 248 - repoRoot.Length;
			while (current != null && current.Length >= max)
			{
				var lastIndex = current.LastIndexOfAny(new[] {Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar});
				if (lastIndex < 0)
					throw new InvalidOperationException("No directory separator characters found in " + current);
				current = current.Substring(0, lastIndex);
			}
			return current;
		}

		private int DeleteEmptyDirectories(DirectoryInfo directory)
		{
			var emptyDirCount = new IndexObject();

			foreach (var dir in directory.GetDirectories())
			{
				var count = DeleteEmptyDirectories(dir);
				lock (emptyDirCount)
					emptyDirCount.Count += count;
			}
			var emptyDirectoriesDeleted = emptyDirCount.Count;

			if (!directory.GetFileSystemInfos().Any())
			{
				if (Verbose)
					Console.WriteLine(string.Format("Deleting empty directory {0}", directory));
				directory.Delete(false);
				emptyDirectoriesDeleted++;
			}
			return emptyDirectoriesDeleted;
		}

		private void ExecuteRevertAll(string hgExe, DirectoryInfo directory)
		{
			if (Verbose)
				Console.WriteLine("Reverting all files under " + directory.FullName);
			const string command = "revert --all --no-backup";
			try
			{
				BuildSystem.RunProcess(hgExe, command, directory.FullName, timeoutSeconds: 90);
			}
			catch (TimeoutException)
			{
				Thread.Sleep(10 * 1000);
				BuildSystem.RunProcess(hgExe, command, directory.FullName);
			}
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

		private static IEnumerable<string> GetHgStatFiles(string hgExe, DirectoryInfo directory, string tempIgnoreFile)
		{
			string output;

			try
			{
				output = BuildSystem.RunProcess(hgExe, "status", directory.FullName, timeoutSeconds: 45, displayStdOut: false);
			}
			catch (TimeoutException)
			{
				Thread.Sleep(10 * 1000);
				output = BuildSystem.RunProcess(hgExe, "status", directory.FullName);
			}

			var currentAssembly = System.Reflection.Assembly.GetExecutingAssembly().Location;
			var files = output.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries)
							.Select(s => s.TrimStart(new[] { ' ', '?' }).Trim())
							.Select(s =>
							{
								try
								{
									var file = Path.Combine(directory.FullName, s);
									return file;
								}
								catch
								{
									return null;
								}
							})
							.Where(f => !string.IsNullOrWhiteSpace(f) && !f.Equals(tempIgnoreFile, StringComparison.InvariantCultureIgnoreCase) && !f.Equals(currentAssembly, StringComparison.InvariantCultureIgnoreCase)).ToArray();
			return files;
		}
	}
}
