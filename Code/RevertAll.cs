using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;

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
				string[] pathTooLong;
				var junctionsDeleted = DeleteJunctions(repoRoot.FullName, out pathTooLong);
				Console.WriteLine("Deleted {0} junctions.", junctionsDeleted);
				var pathNotTooLong =
					pathTooLong.Select(FindParentNotTooLong).Distinct(StringComparer.InvariantCultureIgnoreCase).ToArray();
				foreach (var notTooLong in pathNotTooLong)
				{
					try
					{
						var newName = string.Format("{0}\\{1}.ptl", Directory.GetCurrentDirectory(), Path.GetFileName(notTooLong));
						Console.WriteLine(string.Format("Moving {0} to {1}", notTooLong, newName));
						Directory.Move(notTooLong, newName);
						Directory.Delete(newName, true);
					}
					catch (DirectoryNotFoundException)
					{
					}
				}

				var hgIgnoreFile = repoRoot.GetFiles(".hgignore").Where(f => f.Exists && f.Name.Equals(".hgignore", StringComparison.InvariantCultureIgnoreCase)).Select(f => f.FullName).SingleOrDefault();
				var tmpIgnoreFile = Path.Combine(repoRoot.FullName, string.Format("{0}.hgignore", Guid.NewGuid()));

				if(hgIgnoreFile != null)
					File.Move(hgIgnoreFile, tmpIgnoreFile);

				const string hgExe = "hg";
				var files = GetHgStatFiles(hgExe, repoRoot, tmpIgnoreFile);

				if (hgIgnoreFile != null)
					File.Move(tmpIgnoreFile, hgIgnoreFile);

				var fileCount = new IndexObject();

				files.AsParallel().ForAll(file =>
					{
						if (!file.Exists)
							return;
						if (_verbose)
							Console.WriteLine(string.Format("Deleting {0}", file));
						file.Delete();
						lock (fileCount)
							fileCount.Count++;
					});
				
				Console.WriteLine(string.Format("Deleted {0} files.", fileCount.Count));
				RevertAll(hgExe, repoRoot);

				var emptyDirectories = DeleteEmptyDirectories(repoRoot);
				Console.WriteLine(string.Format("Deleted {0} empty directories.", emptyDirectories));
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}
		private class IndexObject
		{
			public int Count { get; set; }
		}
		private static int DeleteJunctions(string directoryName, out string[] pathTooLong)
		{
			var ptl = new List<string>();
			var directory = new DirectoryInfo(directoryName);
			if (directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
			{
				if(_verbose)
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

		private static string FindParentNotTooLong(string directory)
		{
			var current = directory;
			var max = 248 - Directory.GetCurrentDirectory().Length;
			while (current != null && current.Length >= max)
			{
				
					current = Path.GetDirectoryName(current);
			}
			return current;
		}

		private static int DeleteEmptyDirectories(DirectoryInfo directory)
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
				if(_verbose)
					Console.WriteLine(string.Format("Deleting empty directory {0}", directory));
				directory.Delete(false);
				emptyDirectoriesDeleted++;
			}
			return emptyDirectoriesDeleted;
		}

		private static void RevertAll(string hgExe, DirectoryInfo directory)
		{
			if(_verbose)
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
		
		private static FileInfo[] GetHgStatFiles(string hgExe, DirectoryInfo directory, string tempIgnoreFile)
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
			var files = output.Split(new [] { '\n' }, StringSplitOptions.RemoveEmptyEntries)
							.Select(s => s.TrimStart(new [] { ' ', '?' }).Trim())
							.Select(s =>
								{
									try
									{
										var file = new FileInfo(s);
										return file;
									}
									catch
									{
										return null;
									}
								})
							.Where(f => f != null && f.Exists && f.FullName != tempIgnoreFile && !f.FullName.Equals(currentAssembly, StringComparison.InvariantCultureIgnoreCase)).ToArray();
			return files;
		}
	}
}
