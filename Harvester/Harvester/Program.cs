using System;
using System.Collections.Generic;
using System.Data.Linq;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace Harvester
{
	class Program
	{
		/// <summary>
		/// Harvest Mercurial changesets.
		/// 
		/// args may be used to facilitate testing against a test repository.
		/// If specified, the Repository table will not be used and hg clone will not be done.
		/// A test repository should have been previously cloned into the app setting configured directory.
		/// The branch and feature specified must correspond to a record in the Repository table.
		/// args[0] = branch
		/// args[1] = feature
		/// </summary>
		static void Main(string[] args)
		{
			var startDateTime = DateTime.UtcNow;
			WriteMessage("Mercurial Changeset Harvester", ConsoleColor.Green);
			WriteMessage("Started", ConsoleColor.Green);
			try
			{
				List<Repository> repositories;

				if (args.Count() != 2)
				{
					// Get list of repositories.
					using (var dataContext = new DatabaseDataContext())
					{
						repositories = dataContext.Repositories
							.Where(r => r.HarvestFlag == true)
							.OrderBy(r => r.Branch)
							.ThenBy(r => r.Feature)
							.ToList();
					}
				}
				else
				{
					// Use specified information for repository.
					repositories = new List<Repository> {new Repository {Branch = args[0], Feature = args[1], URL = ""}};
				}

				// Loop through repositories.
				foreach (var repository in repositories)
				{
					WriteMessage(repository.Branch + " " + repository.Feature, ConsoleColor.Cyan);

					string path = Properties.Settings.Default.Directory + @"\HarvesterRepository";
					if (args.Count() != 2)
					{
						// Prepare empty directory.
						if (Directory.Exists(path))
						{
							Directory.Delete(path, true);
							while (Directory.Exists(path))
							{
								Thread.Sleep(50);
							}
						}
						Directory.CreateDirectory(path);
					}

					// Clone repository to directory.
					if (args.Count() != 2)
					{
						string output;
						RunProgram("hg",
						           "clone http://" + Properties.Settings.Default.MercurialUser + ":" + Properties.Settings.Default.MercurialPassword + "@" + repository.URL,
						           path,
						           out output);
					}

					// Get repository history.
					string repositoryDirectory = new DirectoryInfo(path).GetDirectories().First().FullName;
					List<RepositoryEntry> repositoryHistory;
					GetRepositoryHistory(repositoryDirectory, out repositoryHistory);

					// Load Parent indices for repository entries.
					LoadParentIndices(ref repositoryHistory);

					// Determine branches for repository entries.
					DetermineBranches(ref repositoryHistory);

					// Determine bookmarks for repository entries.
					DetermineBookmarks(ref repositoryHistory);

					// Save repository history to database.
					SaveRepositoryHistory(repository.Branch, repository.Feature, ref repositoryHistory);

					if (args.Count() != 2)
					{
						// Delete directory.
						Directory.Delete(path, true);
						while (Directory.Exists(path))
						{
							Thread.Sleep(50);
						}
					}
				}
			}
			catch (Exception e)
			{
				WriteMessage(string.Format("Aborted - An error occurred: {0}", e.Message), ConsoleColor.Red);
				if (AppDomain.CurrentDomain.FriendlyName.EndsWith(".vshost.exe")) Console.ReadLine();
				Environment.Exit(1);
			}
			WriteMessage("Finished - Execution time: " + (DateTime.UtcNow - startDateTime) + "\n", ConsoleColor.Green);
			if (AppDomain.CurrentDomain.FriendlyName.EndsWith(".vshost.exe")) Console.ReadLine();
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
			var branches = "";
			var bookmarks = "";
			var parents = "";
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
					case "branches":
						lineType = 2;
						break;
					case "bookmarks":
						lineType = 3;
						break;
					case "parents":
						lineType = 4;
						break;
					case "user":
						lineType = 5;
						break;
					case "date":
						lineType = 6;
						break;
					case "summary":
						lineType = 7;
						break;
					case "files":
						lineType = 8;
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
						branches = "";
						bookmarks = "";
						parents = "";
						user = "";
						date = DateTime.MinValue;
						summary = "";
						files = "";
						nextType++;
						break;
					case 2:
						branches = match.Groups["value"].Value;
						nextType++;
						break;
					case 3:
						bookmarks = match.Groups["value"].Value;
						nextType++;
						break;
					case 4:
						parents = match.Groups["value"].Value;
						nextType++;
						break;
					case 5:
						user = match.Groups["value"].Value;
						nextType++;
						break;
					case 6:
						value = match.Groups["value"].Value;
						match = datePattern.Match(value);
						if (!match.Success)
						{
							throw new Exception("Repository history date line does not have expected format.");
						}
						date = DateTime.Parse(match.Result("${month} ${day} ${year} ${time}"));
						nextType++;
						break;
					case 7:
						summary = match.Groups["value"].Value;
						nextType++;
						break;
					case 8:
						files = match.Groups["value"].Value;
						repositoryHistory.Add(new RepositoryEntry
						{
							RevisionNumber = Convert.ToInt32(revisionNumber),
							ChangesetId = changesetId,
							Branches = branches,
							Bookmarks = bookmarks,
							Parents = parents,
							User = user,
							CreatedDateTime = date,
							Summary = summary,
							Files = files,
							BranchList = new List<string>(),
							BookmarkList = new List<string>(),
							ParentIndexList = new List<int>(),
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
		/// Load Parent indices for repository entries.
		/// </summary>
		private static void LoadParentIndices(ref List<RepositoryEntry> repositoryHistory)
		{
			var changesetPattern = new Regex(@"^(?<revisionNumber>.+):(?<changesetId>.+)$");

			// Loop through repository history.
			var numberOfEntries = repositoryHistory.Count();
			for (int ii = 0; ii < numberOfEntries; ii++)
			{
				var repositoryEntry = repositoryHistory[ii];

				// Is prior changeset the parent?
				if (repositoryEntry.Parents.Trim() == "")
				{
					// Are we not on last entry?
					if (ii < (numberOfEntries - 1))
					{
						// Add index for prior changeset.
						repositoryEntry.ParentIndexList.Add(ii + 1);
					}
				}
				else
				{
					// Loop through parent changeset information.
					var parentList = Regex.Split(repositoryEntry.Parents, @"\*\^\*");
					foreach (var parent in parentList)
					{
						// Skip last entry in list.
						if (parent == "") continue;

						// Split parent changeset information into components. 
						var match = changesetPattern.Match(parent);
						if (!match.Success)
						{
							throw new Exception("Repository history parents line does not have expected format.");
						}
						var revisionNumber = Convert.ToInt32(match.Groups["revisionNumber"].Value);

						// Find repository history entry for parent changeset.
						for (int jj = ii + 1; jj < numberOfEntries; jj++)
						{
							if (repositoryHistory[jj].RevisionNumber == revisionNumber)
							{
								// Add index for parent changeset.
								repositoryEntry.ParentIndexList.Add(jj);
								break;
							}
						}
					}
				}
			}
		}

		/// <summary>
		/// Determine branches for repository entries.
		/// </summary>
		private static void DetermineBranches(ref List<RepositoryEntry> repositoryHistory)
		{
			// Loop through repository history.
			var numberOfEntries = repositoryHistory.Count();
			for (int ii = 0; ii < numberOfEntries; ii++)
			{
				var repositoryEntry = repositoryHistory[ii];

				// Does repository entry have branch(es)?
				var branchList = Regex.Split(repositoryEntry.Branches, @"\*\^\*");
				if (branchList.Count() > 1)
				{
					// Loop through branches.
					foreach (string branch in branchList)
					{
						// Skip last entry in list.
						if (branch == "") continue;

						// Add branch to current entry and all parents.
						AddBranch(ref repositoryHistory, ii, branch);
					}
				}
			}
		}

		/// <summary>
		/// Add branch to current entry and all parents.
		/// </summary>
		private static void AddBranch(ref List<RepositoryEntry> repositoryHistory, int currentIndex, string branch)
		{
			var repositoryEntry = repositoryHistory[currentIndex];

			// Exit if branch is already present.
			if (repositoryEntry.BranchList.Contains(branch))
			{
				return;
			}

			// Add branch to current entry.
			repositoryEntry.BranchList.Add(branch);

			// Loop through parent entries.
			foreach (int parentIndex in repositoryEntry.ParentIndexList)
			{
				AddBranch(ref repositoryHistory, parentIndex, branch);
			}
		}

		/// <summary>
		/// Determine bookmarks for repository entries.
		/// </summary>
		private static void DetermineBookmarks(ref List<RepositoryEntry> repositoryHistory)
		{
			// Loop through repository history.
			var numberOfEntries = repositoryHistory.Count();
			for (int ii = 0; ii < numberOfEntries; ii++)
			{
				var repositoryEntry = repositoryHistory[ii];

				// Does repository entry have bookmark(s)?
				var bookmarkList = Regex.Split(repositoryEntry.Bookmarks, @"\*\^\*");
				if (bookmarkList.Count() > 1)
				{
					// Loop through bookmarks.
					foreach (string bookmark in bookmarkList)
					{
						// Skip last entry in list.
						if (bookmark == "") continue;

						// Add bookmark to current entry and all parents.
						AddBookmark(ref repositoryHistory, ii, bookmark);
					}
				}
			}
		}

		/// <summary>
		/// Add bookmark to current entry and all parents.
		/// </summary>
		private static void AddBookmark(ref List<RepositoryEntry> repositoryHistory, int currentIndex, string bookmark)
		{
			var repositoryEntry = repositoryHistory[currentIndex];

			// Exit if bookmark is already present.
			if (repositoryEntry.BookmarkList.Contains(bookmark))
			{
				return;
			}

			// Add bookmark to current entry.
			repositoryEntry.BookmarkList.Add(bookmark);

			// Loop through parent entries.
			foreach (int parentIndex in repositoryEntry.ParentIndexList)
			{
				AddBookmark(ref repositoryHistory, parentIndex, bookmark);
			}
		}

		/// <summary>
		/// Save repository history to database.
		/// </summary>
		private static void SaveRepositoryHistory(string branch, string feature, ref List<RepositoryEntry> repositoryHistory)
		{
			// Loop through repository history.
			foreach (var repositoryEntry in repositoryHistory)
			{
				using (var dataContext = new DatabaseDataContext())
				{
					var branches = new StringBuilder();
					foreach (string mercurialBranch in repositoryEntry.BranchList)
					{
						branches.Append(mercurialBranch + "*^*");
					}

					var bookmarks = new StringBuilder();
					foreach (string bookmark in repositoryEntry.BookmarkList)
					{
						bookmarks.Append(bookmark + "*^*");
					}

					ISingleResult<AddRepositoryEntryResult> result = dataContext.AddRepositoryEntry(branch,
					                                                                                feature,
					                                                                                repositoryEntry.ChangesetId,
					                                                                                repositoryEntry.User,
					                                                                                repositoryEntry.CreatedDateTime,
					                                                                                repositoryEntry.Summary,
					                                                                                repositoryEntry.Files,
																									branches.ToString(),
					                                                                                bookmarks.ToString(),
					                                                                                repositoryEntry.IssueNumber);

					if ((int) result.ReturnValue != 0)
						throw new Exception("Error while adding repository entry to database.");
				}
			}
		}
	}
}
