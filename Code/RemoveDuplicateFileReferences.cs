using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			var outputFile = args.Length > 1 ? args[1] : null;
			var fileList = new List<string>();
			if (args.Length > 0)
				fileList.Add(args[0]);
			else
			{
				fileList.AddRange(GetCsProjFiles());
			}
			return fileList.Sum(f => RemoveDuplicateEntries(f, outputFile));
		}

		private static IEnumerable<string> GetCsProjFiles()
		{
			return Directory.GetFiles(Environment.CurrentDirectory, "*.csproj", SearchOption.AllDirectories);
		}

		private static int RemoveDuplicateEntries(string fileName, string outputFile = null)
		{
			var xDocument = XDocument.Load(fileName);
			var root = xDocument.Root;
			
			if (root == null)
				return 0;

			var duplicateNodes =
				root.Elements()
					.Where(n => n.Name.LocalName == "ItemGroup")
					.SelectMany(i => i.Elements())
					.GroupBy(c => c.Name.LocalName).Where(c => c.Attributes().Any(a => a.Name.LocalName == "Include"))
					.ToDictionary(c => c.Key, c => c.GroupBy(d => d.Attributes().Single(e => e.Name.LocalName == "Include").Value).Where(f => f.Count() > 1)
						.ToDictionary(f => f.Key, f => f.ToArray())).SelectMany(f => f.Value.SelectMany(g => g.Value.Skip(1))).ToArray();

			if (!duplicateNodes.Any())
				return 0;

			foreach (var dup in duplicateNodes)
				dup.Remove();

			xDocument.Save(outputFile ?? fileName);
			return 0;
		}
	}
}
