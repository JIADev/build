using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;

namespace Sandbox
{
	class Program
	{
		static void Main(string[] args)
		{
			if (args.Length == 0)
			{
				return;
			}

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

			foreach (var dirPath in paths)
			{
				if (!Directory.Exists(dirPath))
					continue;

				{
					var filePath = Path.Combine(dirPath, args[0]);

					if (File.Exists(filePath))
					{
						var files = Directory.GetFiles(dirPath, args[0]);

						instances.Add(files[0]);
					}
				}
				
				foreach (var pe in pathExts)
				{
					var filePath = Path.Combine(dirPath, args[0] + pe);
					if (!File.Exists(filePath)) continue;

					var files = Directory.GetFiles(dirPath, args[0] + pe);
					instances.AddRange(files);
				}
			}
			if (instances.Count == 0)
			{
				Console.WriteLine("No instances of {0} found in path", args[0]);
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
		}
	}
}
