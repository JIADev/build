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

		private static int Main(string[] args)
		{
			try
			{
				var repoRoot = FindRepoRoot(new DirectoryInfo(Environment.CurrentDirectory));
				if (repoRoot == null)
				{
					Console.WriteLine("Must be in a mercurial repository.");
					return 2;
				}
				
				var hgExe = "hg";
				RevertAll(hgExe, repoRoot);

				var hgIgnoreFile = repoRoot.GetFiles(".hgignore").Where(f => f.Exists && f.Name.Equals(".hgignore", StringComparison.InvariantCultureIgnoreCase)).Select(f => f.FullName).SingleOrDefault();
				var tmpIgnoreFile = Path.Combine(repoRoot.FullName, string.Format("{0}.hgignore", Guid.NewGuid()));

				if(hgIgnoreFile != null)
					File.Move(hgIgnoreFile, tmpIgnoreFile);

				DeleteJunctions(repoRoot);

				var files = GetHgStatFiles(hgExe, repoRoot, tmpIgnoreFile);

				if (hgIgnoreFile != null)
				{
					File.Move(tmpIgnoreFile, hgIgnoreFile);
				}
				foreach (var file in files.Where(f => f.Exists))
				{
					Console.WriteLine(string.Format("Deleting {0}", file));
					file.Delete();
				}
				DeleteEmptyDirectories(repoRoot);

			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}

		private static void DeleteJunctions(DirectoryInfo directory)
		{
			if (directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
			{
				Console.WriteLine(string.Format("Deleting Junction {0}", directory));
				directory.Delete();
				return;
			}
			foreach (var dir in directory.GetDirectories())
				DeleteJunctions(dir);
		}

		private static void DeleteEmptyDirectories(DirectoryInfo directory)
		{
			foreach(var dir in directory.GetDirectories())
				DeleteEmptyDirectories(dir);
			
			if (!directory.GetFileSystemInfos().Any())
			{
				Console.WriteLine(string.Format("Deleting empty directory {0}", directory));
				directory.Delete(false);
			}
		}

		private static void RevertAll(string hgExe, DirectoryInfo directory)
		{
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
							.Where(f => f != null && f.Exists && f.FullName != tempIgnoreFile).ToArray();
			return files;
		}
	}
}
