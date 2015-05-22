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

				var infos =
					repoRoot.GetFiles()
					        .Cast<FileSystemInfo>()
					        .Union(repoRoot.GetDirectories())
					        .Where(i => !i.Name.Equals(".hg"))
					        .Select(f => new {Type = f.GetType(), Info = f})
					        .GroupBy(f => f.Type)
							.ToDictionary(f => f.Key,
					                      f => f.Select(i => i.Info).ToArray());

				foreach (var type in infos.Keys)
				{
					if (type == typeof (FileInfo))
					{
						foreach (var info in infos[type].Cast<FileInfo>())
						{
							if (_verbose)
								Console.WriteLine(string.Format("Deleting {0}", info));
							info.Delete();
						}
					}
					else if (type == typeof (DirectoryInfo))
					{
						foreach (var info in infos[type].Cast<DirectoryInfo>())
						{
							if (_verbose)
								Console.WriteLine(string.Format("Deleting {0}", info));
							info.Delete(true);
						}
					}
					
				}
				Console.WriteLine("Deleted {0} files and {1} directories.", infos.ContainsKey(typeof(FileInfo)) ? infos[typeof(FileInfo)].Length : 0, infos.ContainsKey(typeof(DirectoryInfo)) ? infos[typeof(DirectoryInfo)].Length : 0);
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
