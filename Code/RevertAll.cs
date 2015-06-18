using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;

namespace j6.BuildTools
{
	class Program
	{
		static readonly Regex ChangesetRegex = new Regex("^changeset:.*$", RegexOptions.Multiline);
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

				var hgIgnoreFile = repoRoot.GetFiles(".hgignore").Where(f => f.Exists && f.Name.Equals(".hgignore", StringComparison.InvariantCultureIgnoreCase)).Select(f => f.FullName).SingleOrDefault();
				var tmpIgnoreFile = Path.Combine(repoRoot.FullName, string.Format("{0}.hgignore", Guid.NewGuid()));

				if(hgIgnoreFile != null)
					File.Move(hgIgnoreFile, tmpIgnoreFile);

				var hgExe = "hg";
				var files = GetHgStatFiles(hgExe, repoRoot, tmpIgnoreFile);

				if (hgIgnoreFile != null)
					File.Move(tmpIgnoreFile, hgIgnoreFile);

				var fileCount = 0;
				foreach (var file in files.Where(f => f.Exists))
				{
					if(_verbose)
						Console.WriteLine(string.Format("Deleting {0}", file));
					file.Delete();
					fileCount++;
				}
				Console.WriteLine(string.Format("Deleted {0} files.", fileCount));
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

		private static int DeleteEmptyDirectories(DirectoryInfo directory)
		{
			var emptyDirectoriesDeleted = directory.GetDirectories().Sum(dir => DeleteEmptyDirectories(dir));
			
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
			BuildSystem.RunProcess(hgExe, "revert --all --no-backup", directory.FullName);
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
			var output = BuildSystem.RunProcess(hgExe, "status", directory.FullName);
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
