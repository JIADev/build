using System;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
	public class DeleteIfEmpty : Task
	{
		public string Files { get; set; }

		public override bool Execute()
		{
			var files = Files.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);
			
			if (files.Length == 0)
				files = Directory.GetFiles(Environment.CurrentDirectory, "*.*");

			foreach (var info in files.Select(file => new FileInfo(file)).Where(info => info.Exists).Where(info => info.Length == 0))
			{
				info.Delete();
			}
			return true;
		}
	}
}
