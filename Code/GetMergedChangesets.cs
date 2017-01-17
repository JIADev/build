using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Microsoft.Build.Framework;

namespace j6.BuildTools.MsBuildTasks
{
	public class GetMergedChangesets : HgTask
	{
		[Required]
		public new string RepoDirectory { get { return base.RepoDirectory; } set { base.RepoDirectory = value; } }

		[Required]
		public string OriginalChangeset { get; set; }

		[Required]
		public string NewChangeset { get; set; }

		public string AdditionalArgs { get; set; }
		
		public string OutputFile { get; set; }

		public string StyleSheet { get; set; }

		private string _updateToChangeset;
		public string UpdateToChangeset { get { return string.IsNullOrWhiteSpace(_updateToChangeset) ? NewChangeset : _updateToChangeset; } set { _updateToChangeset = value; } }

		
		public override bool Execute()
		{
			var originalChangesets = OriginalChangeset.Split(new[] { ' ', ';', ',', ':' }, StringSplitOptions.RemoveEmptyEntries);
			var output = RunHgXmlOutput(string.Format("log --rev \"ancestors('{0}') and !({1}) {2}\"", NewChangeset,
										 string.Join(" or ", originalChangesets.Select(c => string.Format("ancestors('{0}')", c))), AdditionalArgs));
			if (string.IsNullOrWhiteSpace(OutputFile)) return true;
			if (output == null)
			{
				using (File.Create(OutputFile)) 
					return true;
			}

			var log =
				output.Elements("log").Single();

			var logEntries = log.Elements("logentry");
			var paths =
				logEntries.SelectMany(
					logEntry =>
					logEntry.Elements("paths")
							.SelectMany(
								p1 => p1.Elements("path").Select(p => new
									{
										Action = p.Attribute("action").Value,
										Path = p.Value,
										Node = logEntry.Attribute("node").Value,
										Branch = logEntry.Element("branch"),
										Parent = logEntry.Element("parent"), //.Attribute("node").Value,
										Author = logEntry.Element("author"),
										Date = logEntry.Element("date"),
										Message = logEntry.Element("msg")
									})))
						  .GroupBy(p => p.Path, StringComparer.InvariantCultureIgnoreCase)
						  .Select(p => new
						  {
							  Actions = p.Select(p1 => p1.Action).Distinct().ToArray(),
							  Branches = p.Select(p1 => p1.Branch).Where(b => b != null).Select(b => b.Value).Distinct().ToArray(),
							  Authors = p.Select(p1 => p1.Author).Where(a => a != null).Select(a => a.Value).Distinct().ToArray(),
							  AuthorBranches = p.Select(p1 => new { p1.Author, p1.Branch }).Where(a => a.Author != null && a.Branch != null).Select(a => string.Format("{0} ({1})", a.Author.Value, a.Branch.Value)).Distinct().ToArray(),
							  Path = p.Key,
							  Entries = p
								  .Select(p1 => new
								  {
									  p1.Action,
									  p1.Path,
									  p1.Node,
									  Branch = p1.Branch == null ? null : p1.Branch.Value,
									  ParentNode = p1.Parent == null ? null : p1.Parent.Attribute("node") == null ? null : p1.Parent.Attribute("node").Value,
									  Author = p1.Author == null ? null : p1.Author.Value,
									  Date = p1.Date == null ? default(DateTime?) : DateTime.Parse(p1.Date.Value),
									  Message = p1.Message == null ? null : p1.Message.Value
								  })
								  
						  }).Select(p =>
									  {
										  var file = new XElement("file");
										  var actions = new XAttribute("actions", string.Join(", ", p.Actions));
										  var path = new XAttribute("path", p.Path);
										  var branches = new XAttribute("branches", string.Join(", ", p.Branches));
										  var authors = new XAttribute("authors", string.Join(", ", p.Authors));
										  var authorBranches = new XAttribute("authorBranches", string.Join(", ", p.AuthorBranches));
										  file.Add(actions);
										  file.Add(path);
										  file.Add(branches);
										  file.Add(authors);
										  file.Add(authorBranches);
										  var fileLogEntries = p.Entries.Select(p1 =>
											  {
												  var logEntry = new XElement("logentry");
												  if (p1.Date != null)
												  {
													  var date = new XAttribute("date", p1.Date);
													  logEntry.Add(date);
												  }
												  var action = new XAttribute("action", p1.Action);
												  logEntry.Add(action);
												  if (p1.Branch != null)
												  {
													  var branch = new XAttribute("branch", p1.Branch);
													  logEntry.Add(branch);
												  }
												  if (p1.Author != null)
												  {
													  var author = new XAttribute("author", p1.Author);
													  logEntry.Add(author);
												  }
												  if (p1.Message != null)
												  {
													  var message = new XAttribute("msg", p1.Message);
													  logEntry.Add(message);
												  }
												  var node = new XAttribute("node", p1.Node);
												  logEntry.Add(node);
												  if (p1.ParentNode != null)
												  {
													  var parentNode = new XAttribute("parentNode", p1.ParentNode);
													  logEntry.Add(parentNode);
												  }
												  return logEntry;
											  });

										  foreach (var fileLogEntry in fileLogEntries)
										  {
											  file.Add(fileLogEntry);
										  }

										  return file;
									  });
			 
			if (!string.IsNullOrWhiteSpace(StyleSheet))
				UpdateStyleSheet.AddStyleSheet(output, StyleSheet);
			var modifiedFiles = new XElement("modifiedfiles");
			foreach (var path in paths)
			{
				modifiedFiles.Add(path);
			}

			log.Add(modifiedFiles);
			output.Save(OutputFile);
			
			return true;
		}
	}
}
