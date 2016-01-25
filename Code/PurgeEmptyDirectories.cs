using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class PurgeEmptyDirectories : Task
	{
		public string Directories { get; set; }

		public override bool Execute()
		{
			var args = Directories.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
			if (args.Select(PurgeEmptyDirs).Any(errorLevel => errorLevel > 0))
			{
				return false;
			}

			if (args.Length == 0)
			{
				return PurgeEmptyDirs() == 0;
			}
			return true;
		}
		private static int PurgeEmptyDirs()
		{
			return PurgeEmptyDirs(Environment.CurrentDirectory);
		}

		private static int PurgeEmptyDirs(string directory)
		{
			try
			{
				var errors = PurgeEmptyDirs(new DirectoryInfo(directory));
				return errors.Any() ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}

		}

		private static Dictionary<string, Exception> PurgeEmptyDirs(DirectoryInfo dir)
		{
			var errors = new Dictionary<string, Exception>();

			var subdirs = dir.GetDirectories();

			foreach (var subdir in subdirs.Where(d => !d.Name.StartsWith(".hg")))
			{
				var isJunction = subdir.Attributes.HasFlag(FileAttributes.ReparsePoint);
				if (isJunction)
				{
					continue;
				}
				errors = errors.Union(PurgeEmptyDirs(subdir)).ToDictionary(e => e.Key, e => e.Value);
				var isEmpty = !subdir.GetFileSystemInfos().Any();
				if (!isEmpty) continue;
				Console.WriteLine("Deleting empty directory " + subdir.FullName);
				try
				{
					subdir.Delete();
				}
				catch (Exception ex)
				{
					Console.Error.WriteLine("Unable to delete {0}: {1}", subdir.FullName, ex.Message);
					errors.Add(subdir.FullName, ex);
				}
			}
			return errors;
		}
	}
}
