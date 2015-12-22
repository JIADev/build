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
			var filesModified = fileList.Sum(f => RemoveDuplicateEntries(f, outputFile));
			Console.WriteLine(string.Format("Modified {0} project files", filesModified));
			var featureExe = @"Core\boot\feature.exe";
			if (File.Exists(featureExe))
			{
				BuildSystem.RunProcess(featureExe, "cleanpatches", Environment.CurrentDirectory);
			}
			return 0;
		}

		private static IEnumerable<string> GetCsProjFiles()
		{
			return Directory.GetFiles(Environment.CurrentDirectory, "*.csproj", SearchOption.AllDirectories);
		}

		private static int RemoveDuplicateEntries(string fileName, string outputFile = null)
		{
			try
			{
				var xDocument = XDocument.Load(fileName);

				var root = xDocument.Root;

				if (root == null)
					return 0;

				var badNodes =
					root.Elements()
					    .Where(
						    n =>
						    n.Name.LocalName == "Import" &&
						    n.Attributes()
						     .Any(
							     a =>
							     a.Name == "Project" &&
							     a.Value.Equals(@"$(SolutionDir)\.nuget\NuGet.targets", StringComparison.InvariantCulture)))
					    .Union(
						    root.Elements()
						        .Where(
							        n =>
							        n.Name.LocalName == "Target" &&
							        n.Attributes()
							         .Any(
								         a =>
								         a.Name == "Name" && a.Value.Equals("EnsureNuGetPackageBuildImports", StringComparison.InvariantCulture))
							        &&
							        n.Attributes().Any(
								        a =>
								        a.Name == "BeforeTargets" && a.Value.Equals("PrepareForBuild", StringComparison.InvariantCulture))))
					    .ToArray();

				var duplicateNodes =
					root.Elements()
					    .Where(n => n.Name.LocalName == "ItemGroup")
					    .SelectMany(i => i.Elements())
					    .GroupBy(c => c.Name.LocalName).Where(c => c.Attributes().Any(a => a.Name.LocalName == "Include"))
					    .ToDictionary(c => c.Key,
					                  c =>
					                  c.GroupBy(d => d.Attributes().Single(e => e.Name.LocalName == "Include").Value)
					                   .Where(f => f.Count() > 1)
					                   .ToDictionary(f => f.Key, f => f.ToArray()))
					    .SelectMany(f => f.Value.SelectMany(g => g.Value.Skip(1)))
					    .ToArray();

				var fileModified = false;

				foreach (var bad in badNodes)
				{
					bad.Remove();
					fileModified = true;
				}

				foreach (var dup in duplicateNodes)
				{
					dup.Remove();
					fileModified = true;
				}

				if (!fileModified)
					return 0;

				xDocument.Save(outputFile ?? fileName);
			}
			catch (Exception ex)
			{
				Console.WriteLine(string.Format("ERROR: {0} {1}", fileName, ex.Message));
				return 0;
			}
			return 1;
		}
	}
}
