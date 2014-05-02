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
				var hgIgnoreFile = repoRoot.GetFiles(".hgignore").SingleOrDefault(f => f.Exists && f.Name.Equals(".hgignore", StringComparison.InvariantCultureIgnoreCase));
				var tmpIgnoreFile = new FileInfo( string.Format("{0}.hgignore", Guid.NewGuid()));

				var hgExe = "hg";
				RevertAll(hgExe, repoRoot);

				if(hgIgnoreFile != null)
					hgIgnoreFile.MoveTo(tmpIgnoreFile.FullName);

				var files = GetHgStatFiles(hgExe, repoRoot, tmpIgnoreFile);
				
				if(hgIgnoreFile != null)
					tmpIgnoreFile.MoveTo(hgIgnoreFile.FullName);

				DeleteJunctions(repoRoot);

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
		
		private static FileInfo[] GetHgStatFiles(string hgExe, DirectoryInfo directory, FileInfo tempIgnoreFile)
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
							.Where(f => f != null && f.Exists && f.FullName != tempIgnoreFile.FullName).ToArray();
			return files;
		}
		
		private static void GenerateXml(string hgExe, string outputFile, IEnumerable<string> changesets)
		{
			var xmlInput = string.Empty;
			if (changesets.Any())
			{
				var args = CreateArgs(changesets);

				xmlInput = BuildSystem.RunProcess(hgExe, args, Environment.CurrentDirectory);
			}
			if (string.IsNullOrEmpty(xmlInput))
				xmlInput = "<log />";
			var xDoc = XDocument.Parse(xmlInput);
			var remove = xDoc.XPathSelectElements("/log/logentry").ToArray()
				.Select(le => 
				new 
				{
					logEntry = le, 
					msgElement = le == null 
					      ? null
					      : le.XPathSelectElement("msg")
				})
				.Select(e => new 
					   { 
					   e.logEntry,
					   msg = e.msgElement == null
					       ? string.Empty
					       : e.msgElement.Value ?? string.Empty
					   })
				.Where(m => m.msg.Contains("@build")).Select(e => e.logEntry);
			foreach (var entry in remove)
			{
				entry.Remove();
			}
			xDoc.Save(outputFile);
		}

		private static string CreateArgs(IEnumerable<string> changesets)
		{
			return string.Format("log {0} -v --no-merges --style xml", string.Join(" ", changesets.Select(c => string.Format("-r {0}", c))));
		}

		private static IEnumerable<string> GetChangesets(string mergedRevisionFile)
		{
			using (var stream = new FileStream(mergedRevisionFile, FileMode.Open, FileAccess.Read, FileShare.Read))
			using(var reader = new StreamReader(stream))
			{
				var fileContents = reader.ReadToEnd();
				var changesets = ChangesetRegex.Matches(fileContents).Cast<Match>().Select(m => m.Value.Substring(m.Value.LastIndexOf(':') + 1).Trim()).ToArray();
				return changesets;
			}
		}
	}
}
