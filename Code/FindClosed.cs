using System;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class FindClosed : Task
	{
		[Required]
		public string SearchBranch { get; set; }
		[Required]
		public string InputFile { get; set; }
		[Required]
		public string OutputFile { get; set; }
		
		public override bool Execute()
		{
			if (File.Exists(OutputFile))
				File.Delete(OutputFile);

			using (var reader = new StreamReader(File.Open(InputFile, FileMode.Open, FileAccess.Read, FileShare.Read)))
			{
				while (!reader.EndOfStream)
				{
					var line = reader.ReadLine();

					if (line == null)
						return true;

					var parts = line.Split(new[] { " ", "\t", "\n", "\r" }, StringSplitOptions.RemoveEmptyEntries);

					if (parts.Length < 2)
						return true;

					if (!parts[0].Trim().Equals(SearchBranch, StringComparison.InvariantCulture)) continue;

					if (parts.Last().Equals("(closed)", StringComparison.InvariantCulture))
						return true;

					using (var writer = new StreamWriter(File.Open(OutputFile, FileMode.Create, FileAccess.Write, FileShare.Read)))
					{
						writer.WriteLine(line);
						writer.Flush();
					}

				}
			}
			return true;
		}
	}
}
