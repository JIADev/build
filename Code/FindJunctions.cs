using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			foreach (var arg in args)
			{
				var errorLevel = FindJunctions(arg);
				if (errorLevel > 0)
					return errorLevel;
			}

			return args.Length == 0 ? FindJunctions() : 0;
		}

		private static int FindJunctions()
		{
			return FindJunctions(Environment.CurrentDirectory);
		}

		private static int FindJunctions(string directory)
		{
			try
			{
				var errors = FindJunctions(new DirectoryInfo(directory));
				return errors.Any() ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}
			
		}

		private static Dictionary<string, Exception> FindJunctions(DirectoryInfo dir)
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
				errors = errors.Union(FindJunctions(subdir)).ToDictionary(e => e.Key, e => e.Value);
			}
			return errors;
		}
	}
}
