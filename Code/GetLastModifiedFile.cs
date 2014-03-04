using System;
using System.IO;
using System.Linq;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			
			if (args.Length < 0)
			{
				Console.WriteLine("Usage GetLastModifiedFile.exe <directory> [<searchPattern>]");
				return 1;
			}

			var directory = new DirectoryInfo(args[0]);
			
			Console.WriteLine(
				(args.Length > 1 ? directory.GetFiles(args[1]) : directory.GetFiles())
				.OrderByDescending(f => f.LastWriteTimeUtc)
				.Select(f => f.FullName)
				.FirstOrDefault());

			return 0;
		}

	}
}
