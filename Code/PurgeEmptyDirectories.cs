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
				var errorLevel = PurgeEmptyDirectories(arg);
				if (errorLevel > 0)
					return errorLevel;
			}

			return args.Length == 0 ? PurgeEmptyDirectories() : 0;
		}

		private static int PurgeEmptyDirectories()
		{
			return PurgeEmptyDirectories(Environment.CurrentDirectory);
		}

		private static int PurgeEmptyDirectories(string directory)
		{
			try
			{
				var errors = PurgeEmptyDirectories(new DirectoryInfo(directory));
				return errors.Any() ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}
			
		}

		private static Dictionary<string, Exception> PurgeEmptyDirectories(DirectoryInfo dir)
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
				var isEmpty = !subdir.GetFileSystemInfos().Any();
				if(isEmpty)
				{
					Console.WriteLine("Deleting empty directory " + subdir.FullName);
					try
					{
						subdir.Delete();
						continue;
					}
					catch (Exception ex)
					{
						Console.Error.WriteLine("Unable to delete {0}: {1}", subdir.FullName, ex.Message);
						errors.Add(subdir.FullName, ex);
					}
				}
				errors = errors.Union(PurgeEmptyDirectories(subdir)).ToDictionary(e => e.Key, e => e.Value);
			}
			return errors;
		}
	}
}
