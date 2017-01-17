using System;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class GetLastModifiedFile : Task
	{
		[Required]
		public string Directory { get; set; }
		public string SearchPattern { get; set; }
		[Output]
		public string LastModifiedFile { get; private set; }

		public override bool Execute()
		{
			var directory = new DirectoryInfo(Directory);
			
			LastModifiedFile =
				(string.IsNullOrWhiteSpace(SearchPattern) ? directory.GetFiles() : directory.GetFiles(SearchPattern))
					.OrderByDescending(f => f.LastWriteTimeUtc)
					.Select(f => f.FullName)
					.FirstOrDefault();

			return true;
		}
	}
}
