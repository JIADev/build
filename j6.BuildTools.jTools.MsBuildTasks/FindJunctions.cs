using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class FindJunctions : Task
	{
		public string Sources { get; set; }
		public override bool Execute()
		{
			var args = Sources.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);

			if (args.Select(ExecuteFindJunctions).Any(errorLevel => errorLevel > 0))
				return false;

			if (args.Length == 0)
				return ExecuteFindJunctions() == 0;

			return true;
		}

		private static int ExecuteFindJunctions()
		{
			return ExecuteFindJunctions(Environment.CurrentDirectory);
		}

		private static int ExecuteFindJunctions(string directory)
		{
			try
			{
				var errors = ExecuteFindJunctions(new DirectoryInfo(directory));
				return errors.Any() ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}

		}

		private static Dictionary<string, Exception> ExecuteFindJunctions(DirectoryInfo dir)
		{
			var errors = new Dictionary<string, Exception>();

			var subdirs = dir.GetDirectories();

			foreach (var subdir in subdirs.Where(d => !d.Name.StartsWith(".hg")))
			{
				var isJunction = subdir.Attributes.HasFlag(FileAttributes.ReparsePoint);
				if (isJunction)
				{
					Console.WriteLine(subdir.FullName);
					continue;
				}
				errors = errors.Union(ExecuteFindJunctions(subdir)).ToDictionary(e => e.Key, e => e.Value);
			}
			return errors;
		}
	}
}
