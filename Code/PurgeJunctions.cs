using System;
using System.Collections.Generic;
using System.IO;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			foreach (string arg in args)
			{
				int errorLevel = PurgeJunctions(arg);
				if (errorLevel > 0)
					return errorLevel;
			}

			return args.Length == 0 ? PurgeJunctions() : 0;
		}

		private static int PurgeJunctions()
		{
			return PurgeJunctions(Environment.CurrentDirectory);
		}

		private static int PurgeJunctions(string directory)
		{
			try
			{
				Dictionary<string, Exception> errors = PurgeJunctions(new DirectoryInfo(directory));
				return errors.Count > 1 ? 5 : 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 255;
			}
			
		}

		private static Dictionary<string, Exception> PurgeJunctions(DirectoryInfo dir)
		{
			Dictionary<string, Exception> errors = new Dictionary<string, Exception>();

			DirectoryInfo[] subdirs = dir.GetDirectories();

			foreach (DirectoryInfo subdir in subdirs)
			{
				if (subdir.Name.StartsWith(".hg"))
					continue;
				bool isJunction = (subdir.Attributes & FileAttributes.ReparsePoint) == FileAttributes.ReparsePoint;
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
				Dictionary<string, Exception> subdirResults = PurgeJunctions(subdir);
				foreach (KeyValuePair<string, Exception> result in subdirResults)
				{
					errors.Add(result.Key, result.Value);
				}
			}
			return errors;
		}
	}
}
