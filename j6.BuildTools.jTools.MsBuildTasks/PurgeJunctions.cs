using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class PurgeJunctions : Task
	{
		public string Directories { get; set; }

		public override bool Execute()
		{
			var args = Directories.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);

			if (args.Select(ExecutePurgeJunctions).Any(errorLevel => errorLevel > 0))
			{
				return false;
			}

			if (args.Length == 0)
			{
				return ExecutePurgeJunctions() == 0;
			}
			return true;
		}
		private static int ExecutePurgeJunctions()
		{
			return ExecutePurgeJunctions(Environment.CurrentDirectory);
		}

		private static int ExecutePurgeJunctions(string directory)
		{
			try
			{
				var errors = ExecutePurgeJunctions(new DirectoryInfo(directory));
				return errors.Count > 1 ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}
		}

		private static Dictionary<string, Exception> ExecutePurgeJunctions(DirectoryInfo dir)
		{
			var errors = new Dictionary<string, Exception>();

			DirectoryInfo[] subdirs = dir.GetDirectories();

			foreach (var subdir in subdirs)
			{
				if (subdir.Name.StartsWith(".hg"))
					continue;
				var isJunction = (subdir.Attributes & FileAttributes.ReparsePoint) == FileAttributes.ReparsePoint;
				if (isJunction)
				{
					Console.WriteLine("Deleting junction " + subdir.FullName);
					try
					{
						subdir.Delete();
					}
					catch (Exception ex)
					{
						Console.Error.WriteLine("Unable to delete {0}: {1}", subdir.FullName, ex.Message);
						errors.Add(subdir.FullName, ex);
					}
					continue;
				}
				var subdirResults = ExecutePurgeJunctions(subdir);
				foreach (var result in subdirResults)
				{
					errors.Add(result.Key, result.Value);
				}
			}
			return errors;
		}
	}
}
