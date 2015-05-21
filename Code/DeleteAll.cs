using System;
using System.IO;
using System.Linq;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools
{
	class Program
	{
		private static bool _verbose;

		private static int Main(string[] args)
		{
			try
			{
				_verbose = args.Any(a => a.Equals("--verbose", StringComparison.InvariantCultureIgnoreCase));

				var repoRoot = FindRepoRoot(new DirectoryInfo(Environment.CurrentDirectory));
				if (repoRoot == null)
				{
					Console.WriteLine("Must be in a mercurial repository.");
					return 2;
				}
				
				var junctionsDeleted = DeleteJunctions(repoRoot);
				Console.WriteLine("Deleted {0} junctions.", junctionsDeleted);

				var infos = repoRoot.GetFileSystemInfos().Where(i => !i.Name.Equals(".hg")).ToArray();

				foreach (var info in infos)
				{
					if (_verbose)
						Console.WriteLine(string.Format("Deleting {0}", info));
					
					var dirInfo = info as DirectoryInfo;
					
					if (dirInfo != null)
						dirInfo.Delete(true);
					else
						info.Delete();
				}
				Console.WriteLine("Deleted {0} files and directories.", infos.Length);
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				return 3;
			}
			return 0;
		}

		private static int DeleteJunctions(DirectoryInfo directory)
		{
			if (directory.Attributes.HasFlag(FileAttributes.ReparsePoint))
			{
				if(_verbose)
					Console.WriteLine(string.Format("Deleting Junction {0}", directory));
				directory.Delete();
				return 1;
			}
			return directory.GetDirectories().Sum(dir => DeleteJunctions(dir));
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
	}
}
