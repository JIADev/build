using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Build.Framework;
using System.IO;

namespace j6.BuildTools.MsBuildTasks
{
	public class FastClone : HgTask
	{
		private readonly Dictionary<string, string> _prefixes = new Dictionary<string, string> { { "repos://", @"\\repo.jenkon.com\repo$\" } };

		[Required]
		public string Repository { get; set; }

		[Required]
		public string LocalDir { get; set; }

		[Required]
		public string ParentLocation { get; set; }

		public override bool Execute()
		{
			var localDir = new DirectoryInfo(Path.Combine(ParentLocation, LocalDir));
			if (!EnsureDirectoryEmpty(localDir))
				return false;
			
			var source = GetSourceLocation(Repository);
			
			if (source == null || !source.Exists)
				return false;

			var hgDir = source.GetDirectories(".hg").SingleOrDefault();
			if (hgDir == null || !hgDir.Exists)
				return false;
			Console.WriteLine("Cloning {0} to {1}, please wait", Repository, localDir);
			return CopyDirectory(hgDir, new DirectoryInfo(Path.Combine(localDir.FullName, ".hg")));
		}

		private bool CopyDirectory(DirectoryInfo source, DirectoryInfo target)
		{
			try
			{
				Console.Write(".");
				var sourceFiles = source.GetFileSystemInfos();

				if (!target.Exists)
					target.Create();

				foreach (var sourceFile in sourceFiles)
				{
					var directory = sourceFile as DirectoryInfo;
					var file = sourceFile as FileInfo;

					if (directory != null)
						CopyDirectory(directory, new DirectoryInfo(Path.Combine(target.FullName, directory.Name)));

					if (file != null)
						file.CopyTo(Path.Combine(target.FullName, file.Name));
				}
			}
			catch (Exception ex)
			{
				WriteError(ex.Message);
				return false;
			}
			return true;
		}

		private DirectoryInfo GetSourceLocation(string repository)
		{
			var prefix = _prefixes.SingleOrDefault(pre => repository.StartsWith(pre.Key, StringComparison.InvariantCultureIgnoreCase));
			
			if (prefix.Equals(default(KeyValuePair<string, string>)))
			{
				WriteError(string.Format("Prefix must start with one of: {0}", string.Join(", ", _prefixes.Keys)));
				return null;
			}

			return new DirectoryInfo(repository.Replace(prefix.Key, prefix.Value));
		}

		private bool EnsureDirectoryEmpty(DirectoryInfo localDir)
		{
			if (!localDir.Exists)
			{
				localDir.Create();
				return true;
			}

			var fsInfos = localDir.GetFileSystemInfos();
			
			if (fsInfos.Any())
			{
				WriteError(string.Format("Directory {0} is not empty", localDir.FullName));
				return false;
			}
			return true;
		}
	}
}
