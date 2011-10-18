using System;
using System.Collections.Generic;
using System.Data.Linq;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace Harvester
{
	class Program
	{
		static void Main(string[] args)
		{
			var startDateTime = DateTime.UtcNow;
			WriteMessage("Mercurial Changeset Harvester", ConsoleColor.Green);
			WriteMessage("Started", ConsoleColor.Green);
			try
			{
				var customerCode = "";

				// Are we not in a customer build directory?
				var currentDirectory = new DirectoryInfo(".");
				if (currentDirectory.Name.ToLower() != "build")
				{
					throw new Exception("Current directory is not a customer build directory.");
				}

				if (currentDirectory.Parent != null)
				{
					// Loop through parent subdirectories
					foreach (var peerDirectory in currentDirectory.Parent.GetDirectories())
					{
						// Does directory have a feature configuration file?
						var featureFile = new FileInfo(peerDirectory.FullName + "\\Feature.xml");
						if (featureFile.Exists)
						{
							// We are on a feature directory.

							// Are we on a customer feature directory?
							if ((peerDirectory.Name.Length > 4) && (peerDirectory.Name.Substring(0, 4) == "CUST"))
							{
								// Did we previously find a customer feature directory?
								if (customerCode != "")
								{
									throw new Exception("More than one customer feature directory found.");
								}
								// Remember customer.
								customerCode = peerDirectory.Name;
							}
						}
					}

					// Loop through parent subdirectories
					var repositoryPattern = new Regex(@"^.+/hgwebdir.cgi/(?<branch>.+)/(?<feature>[^/]+$)");
					foreach (var peerDirectory in currentDirectory.Parent.GetDirectories())
					{
						// Does directory have a feature configuration file?
						var featureFile = new FileInfo(peerDirectory.FullName + "\\Feature.xml");
						if (featureFile.Exists)
						{
							// We are on a feature directory.

							// Does directory have a Mercurial configuration file?
							string repository;
							var hgFile = new FileInfo(peerDirectory.FullName + "\\.hg\\hgrc");
							if (hgFile.Exists)
							{
								// Get repository name from Mercurial configuration file.
								GetConfigItem(hgFile.FullName, "paths", "default", out repository);
							}
							else
							{
								throw new Exception("Mercurial configuration file was not found.");
							}

							// Split repository name into components.
							var match = repositoryPattern.Match(repository);
							string branch;
							string feature;
							if (match.Success)
							{
								branch = match.Groups["branch"].Value;
								if (branch.Substring(0, 8) == "feature/")
									branch = branch.Substring(8);
								feature = match.Groups["feature"].Value;

								WriteMessage(customerCode + " " + branch + " " + feature, ConsoleColor.Cyan);
							}
							else
							{
								throw new Exception("Repository name does not have expected format.");
							}

							// Get repository history.
							List<RepositoryEntry> repositoryHistory;
							GetRepositoryHistory(peerDirectory.FullName, out repositoryHistory);

							// Loop through repository history.
							foreach (var repositoryEntry in repositoryHistory)
							{
								// Add repository entry to database.
								AddRepositoryEntry(customerCode, branch, feature, repositoryEntry);
							}
						}
					}
				}
			}
			catch (Exception e)
			{
				WriteMessage(string.Format("Aborted - An error occurred: {0}", e.Message), ConsoleColor.Red);
				Environment.Exit(1);
			}
			WriteMessage("Finished - Execution time: " + (DateTime.UtcNow - startDateTime) + "\n", ConsoleColor.Green);
		}

		/// <summary>
		/// Write message to console.
		/// </summary>
		private static void WriteMessage(string message, ConsoleColor foregroundColor = ConsoleColor.White)
		{
			var oldColor = Console.ForegroundColor;
			Console.ForegroundColor = foregroundColor;
			Console.WriteLine(message);
			Console.ForegroundColor = oldColor;
		}

		/// <summary>
		/// Get configuration file item.
		/// 
		/// Expected file format:
		///     [section-name]
		///     item-key = item-value
		/// </summary>
		private static void GetConfigItem(string filePath, string section, string key, out string value)
		{
			// Set default return value.
			value = "";

			var currentSection = "";
			var sectionPattern = new Regex(@"^\s*\[(?<section>\w+)\]\s*$");
			var entryPattern = new Regex(@"^\s*(?<key>\w+)\s*=\s*(?<value>.+)$");
			using (var reader = new StreamReader(filePath))
			{
				// Read configuration file.
				String line;
				while ((line = reader.ReadLine()) != null)
				{
					// Skip blank lines.
					if (line.Trim() == "") continue;

					// Are we on a section heading?
					var match = sectionPattern.Match(line);
					if (match.Success)
					{
						// Remember section name.
						currentSection = match.Groups["section"].Value;
					}
					else
					{
						// Are we in requested section?
						if (currentSection == section)
						{
							// Are we on a line with an entry?
							match = entryPattern.Match(line);
							if (match.Success)
							{
								// Does entry have requested key?
								if (match.Groups["key"].Value == key)
								{
									// Return entry value.
									value = match.Groups["value"].Value;
									return;
								}
							}
						}
					}
				}
			}
		}

		/// <summary>
		/// Get repository history.
		/// </summary>
		private static void GetRepositoryHistory(string repositoryDirectory, out List<RepositoryEntry> repositoryHistory)
		{
			// Set default return value.
			repositoryHistory = new List<RepositoryEntry>();

			// Run hg log command.
			string output;
			string styleFile = "\"" + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\hglogstyle.txt" + "\"";
			RunProgram("hg", "log --style " + styleFile, repositoryDirectory, out output);
			string[] rawRepositoryHistory = Regex.Split(output, "\n");

			// Loop through repository history.
			var nextType = 1;
			var revisionNumber = "";
			var changesetId = "";
			var user = "";
			var date = DateTime.MinValue;
			var summary = "";
			var files = "";
			var historyLinePattern = new Regex(@"^(?<key>.+?):\s*(?<value>.+)$");
			var changesetPattern = new Regex(@"^(?<revisionNumber>.+):(?<changesetId>.+)$");
			var datePattern = new Regex(@"^(.+?)\s(?<month>.+?)\s(?<day>.+?)\s(?<time>.+?)\s(?<year>.+?)\s(.+)$");
			foreach (var line in rawRepositoryHistory)
			{
				// Skip blank lines.
				if (line.Trim() == "") continue;

				// Split repository history line into key and value.
				var match = historyLinePattern.Match(line);
				if (!match.Success)
				{
					throw new Exception("Repository history line does not have expected format.");
				}

				// Determine line type indicated by line key.
				int lineType;
				switch (match.Groups["key"].Value)
				{
					case "changeset":
						lineType = 1;
						break;
					case "user":
						lineType = 2;
						break;
					case "date":
						lineType = 3;
						break;
					case "summary":
						lineType = 4;
						break;
					case "files":
						lineType = 5;
						break;
					default:
						lineType = 0;
						break;
				}

				// Verify line type matches next type.
				if ((lineType != 0) && (lineType != nextType))
				{
					throw new Exception("Repository history line does not have expected key.");
				}

				// Parse line value based on line type.
				string value;
				switch (lineType)
				{
					case 1:
						value = match.Groups["value"].Value;
						match = changesetPattern.Match(value);
						if (!match.Success)
						{
							throw new Exception("Repository history changeset line does not have expected format.");
						}
						revisionNumber = match.Groups["revisionNumber"].Value;
						changesetId = match.Groups["changesetId"].Value;
						user = "";
						date = DateTime.MinValue;
						summary = "";
						files = "";
						nextType++;
						break;
					case 2:
						user = match.Groups["value"].Value;
						nextType++;
						break;
					case 3:
						value = match.Groups["value"].Value;
						match = datePattern.Match(value);
						if (!match.Success)
						{
							throw new Exception("Repository history date line does not have expected format.");
						}
						date = DateTime.Parse(match.Result("${month} ${day} ${year} ${time}"));
						nextType++;
						break;
					case 4:
						summary = match.Groups["value"].Value;
						nextType++;
						break;
					case 5:
						files = match.Groups["value"].Value;
						repositoryHistory.Add(new RepositoryEntry
						{
							RevisionNumber = Convert.ToInt32(revisionNumber),
							ChangesetId = changesetId,
							User = user,
							CreatedDateTime = date,
							Summary = summary,
							Files = files,
							IssueNumber = GetRedmineIssueNumber(summary)
						});
						nextType = 1;
						break;
				}
			}

			// Verify last changeset was completed.
			if (nextType != 1)
			{
				throw new Exception("Last changeset was not completed.");
			}
		}

		/// <summary>
		/// Run program and return output.
		/// </summary>
		private static void RunProgram(string fileName, string arguments, string workingDirectory, out string output)
		{
			var process = new Process
			{
				StartInfo = new ProcessStartInfo
				{
					FileName = fileName,
					Arguments = arguments,
					WorkingDirectory = workingDirectory,
					UseShellExecute = false,
					RedirectStandardOutput = true,
					StandardOutputEncoding = Encoding.UTF8,
				}
			};
			process.Start();
			output = process.StandardOutput.ReadToEnd();
			process.WaitForExit();
			if (process.ExitCode != 0)
				throw new Exception(string.Format("{0} {1} exited with code {2}.", fileName, arguments, process.ExitCode));
		}

		/// <summary>
		/// Get Redmine issue number from changeset summary.
		/// </summary>
		private static string GetRedmineIssueNumber(string summary)
		{
			var issueNumberPattern = new Regex(@"^[\w\s]*#\s*(?<issue>[0-9]*)[\s:;]");
			var match = issueNumberPattern.Match(summary);
			string issueNumber = match.Success ? match.Groups["issue"].Value : "";

			return issueNumber;
		}

		/// <summary>
		/// Add repository entry to database.
		/// </summary>
		private static void AddRepositoryEntry(string customer, string branch, string feature, RepositoryEntry repositoryEntry)
		{
			using (var dataContext = new DatabaseDataContext())
			{
				ISingleResult<AddRepositoryEntryResult> result = dataContext.AddRepositoryEntry(customer, branch, feature,
																								repositoryEntry.ChangesetId,
																								repositoryEntry.User,
																								repositoryEntry.CreatedDateTime,
																								repositoryEntry.Summary,
																								repositoryEntry.Files,
																								repositoryEntry.IssueNumber);

				if ((int)result.ReturnValue != 0)
					throw new Exception("Error while adding repository entry to database.");
			}
		}
	}
}
