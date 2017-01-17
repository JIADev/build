using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class Which : Task
	{
		[Required]
		public string Command { get; set; }

		public override bool Execute()
		{
			var envVariables = Environment.GetEnvironmentVariables();
			var path = string.Empty;
			var pathExt = string.Empty;

			foreach (DictionaryEntry variable in envVariables)
			{
				var key = variable.Key as string;
				var value = variable.Value as string;
				if(key == null)
					continue;
				
				if (key.Equals("PATH", StringComparison.InvariantCultureIgnoreCase) && !string.IsNullOrEmpty(value))
					path = value;

				if (key.Equals("PATHExt", StringComparison.InvariantCultureIgnoreCase) && !string.IsNullOrEmpty(value))
					pathExt = value;
			}

			var paths = new List<string> {"."};
			paths.AddRange(path.Split(new[] { ";" }, StringSplitOptions.RemoveEmptyEntries));
			var pathExts = pathExt.Split(new[] {";"}, StringSplitOptions.RemoveEmptyEntries);
			var instances = new List<string>();

			foreach (var dirPath in paths.Where(Directory.Exists))
			{
				{
					var filePath = Path.Combine(dirPath, Command);

					if (File.Exists(filePath))
					{
						var files = Directory.GetFiles(dirPath, Command);

						instances.Add(files[0]);
					}
				}
				
				foreach (var pe in pathExts)
				{
					var filePath = Path.Combine(dirPath, Command + pe);
					if (!File.Exists(filePath)) continue;

					var files = Directory.GetFiles(dirPath, Command + pe);
					instances.AddRange(files);
				}
			}
			Console.ForegroundColor = ConsoleColor.Green;
			
			if (instances.Count == 0)
			{
				Console.WriteLine("No instances of {0} found in path", Command);
			}
			else
			{
				Console.WriteLine(instances[0]);
				if (instances.Count > 1)
				{
					Console.WriteLine("Additional instances found:");
					var index = 0;
					foreach (var instance in instances)
					{
						index++;
						if (index == 1)
							continue;
						Console.WriteLine("\t{0}", instance);
					}
				}
			}
			Console.ResetColor();
			return true;
		}
	}
}
