using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Microsoft.Build.Utilities;
using Microsoft.Build.Framework;

// ReSharper disable RedundantStringFormatCall
namespace j6.BuildTools.MsBuildTasks
{
	public class CleanProjectFiles : Task
	{
		[Required]
		public string RepositoryDirectory { get; set; }
		public string OutputFile { get; set; }
		public string InputFiles { get; set; }
		public string FeatureExe { get; set; }

		public CleanProjectFiles()
		{
			FeatureExe = @"Core\boot\feature.exe";
		}

		public override bool Execute()
		{
			InputFiles = InputFiles ?? string.Empty;
			var fileList = InputFiles.Split(new [] { ';' }, StringSplitOptions.RemoveEmptyEntries).ToArray();
			if (fileList.Length == 0)
				fileList = GetCsProjFiles().ToArray();

			var filesModified = fileList.Sum(f => RemoveDuplicateEntries(f, OutputFile));
			Console.WriteLine(string.Format("Modified {0} project files", filesModified));
			
			if (File.Exists(FeatureExe))
			{
				BuildSystem.RunProcess(FeatureExe, "cleanpatches", Environment.CurrentDirectory);
			}
			return true;
		}

		private IEnumerable<string> GetCsProjFiles()
		{
			return Directory.GetFiles(RepositoryDirectory, "*.csproj", SearchOption.AllDirectories);
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
				Console.WriteLine(String.Format("ERROR: {0} {1}", fileName, ex.Message));
				return 0;
			}
			return 1;
		}
	}
}
