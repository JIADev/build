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
		/// args may be used to facilitate testing repository parsing logic.
		/// args[0] = customer code
		/// 
		/// If specified, hg clone will not be done.
		/// A test repository should have been previously cloned into the app setting configured directory.
		/// </summary>
		static void Main(string[] args)
		{
			var startDateTime = DateTime.UtcNow;
			WriteMessage("Mercurial Changeset Harvester", ConsoleColor.Green);
			WriteMessage("Started", ConsoleColor.Green);
			try
			{
				List<Customer> customers;

				if (args.Count() != 1)
				{
					// Get customer information for all customers configured to be harvested.
					using (var dataContext = new DatabaseDataContext())
					{
						customers = (
							from customer in dataContext.Customers
							where customer.HarvestFlag == true
							orderby customer.Code
							select customer).ToList();
					}
				}
				else
				{
					// Get customer information for specified customer.
					using (var dataContext = new DatabaseDataContext())
					{
						customers = (
							from customer in dataContext.Customers
							where customer.Code == args[0]
							&& customer.HarvestFlag == true
							select customer).ToList();
					}
				}

				// Set directory to hold repositories.
				string path = Properties.Settings.Default.Directory + @"\HarvesterRepository\";

				// Loop through customers.
				foreach (var customer in customers)
				{
					WriteMessage("Customer " + customer.Code, ConsoleColor.Green);

					if (args.Count() != 1)
					{
						// Get repositories for customer.
						if (!GetRepositoriesForCustomer(customer.Code, path))
						{
							// Skip further processing if an issue was encountered.
							continue;
						}
					}

					var masterBranchList = new List<MercurialName>();
					var masterBookmarkList = new List<MercurialName>();

					// Determine if customer uses Mercurial subrepositories.
					bool usesSubrepositories = Directory.Exists(path + customer.Code + "\\.hg");

					// Does customer use Mercurial subrepositories?
					if (usesSubrepositories)
					{
						// Get master repository branches for customer.
						if (!GetBranchesForCustomer(customer.Code, path, masterBranchList))
						{
							// Skip further processing if an issue was encountered.
							continue;
						}
						// Get master repository bookmarks for customer.
						if (!GetBookmarksForCustomer(customer.Code, path, masterBookmarkList))
						{
							// Skip further processing if an issue was encountered.
							continue;
						}
					}

					// Loop through feature directories.
					var repositoryPattern = new Regex(@"^.+/hgwebdir.cgi/(?<branch>.+)/(?<feature>[^/]+$)");
					foreach (var directory in Directory.GetDirectories(path + customer.Code))
					{
						// Skip Mercurial directory and Shared directory.
						if (!directory.EndsWith(".hg") && (!directory.EndsWith("\\Shared")))
						{
							// Does directory have a Mercurial configuration file?
							string repository = "";
							var hgFile = new FileInfo(directory + "\\.hg\\hgrc");
							if (hgFile.Exists)
							{
								// Get repository name from Mercurial configuration file.
								GetConfigItem(hgFile.FullName, "paths", "default", out repository);
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

								WriteMessage(branch + " " + feature, ConsoleColor.Cyan);
							}
							else
							{
								throw new Exception("Repository path does not have expected format.");
							}

							// Get repository history.
							List<RepositoryEntry> repositoryHistory;
							GetRepositoryHistory(directory, out repositoryHistory);

							// Load Parent indices for repository entries.
							LoadParentIndices(ref repositoryHistory);

							// Determine branches for repository entries.
							DetermineBranches(ref repositoryHistory, usesSubrepositories, ref masterBranchList, feature);

							// Determine bookmarks for repository entries.
							DetermineBookmarks(ref repositoryHistory, usesSubrepositories, ref masterBookmarkList, feature);

							// Save repository history to database.
							SaveRepositoryHistory(customer.Code, repository, branch, feature, ref repositoryHistory);
						}
					}

					if (args.Count() != 1)
					{
						// Delete directory.
						Directory.Delete(path, true);
						while (Directory.Exists(path))
						{
							Thread.Sleep(100);
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
		/// Get repositories for customer.
		/// </summary>
		private static bool GetRepositoriesForCustomer(string customerCode, string path)
		{
			Customer customerInfo;

			// Get customer information.
			using (var dataContext = new DatabaseDataContext())
			{
				customerInfo = (
					from customer in dataContext.Customers
					where customer.Code == customerCode
					&& customer.HarvestFlag == true
					select customer).SingleOrDefault();
			}

			// Exit if no customer information found or if customer is inactive.
			if ((customerInfo == null)
			|| (customerInfo.HarvestFlag == null)
			|| (customerInfo.HarvestFlag == false))
			{
				return false;
			}

			// Prepare empty directory.
			if (Directory.Exists(path))
			{
				Directory.Delete(path, true);
				while (Directory.Exists(path))
				{
					Thread.Sleep(100);
				}
			}
			Directory.CreateDirectory(path);

			// Is a master repository configured?
			if (customerInfo.URL != null)
			{
				WriteMessage("Cloning repository " + customerInfo.URL.Substring(customerInfo.URL.IndexOf(".cgi", StringComparison.InvariantCultureIgnoreCase) + 4), ConsoleColor.Cyan);

				// Clone master repository and sub repositories to directory.
				string output;
				RunProgram("hg",
							"clone http://" + customerInfo.URL,
							path,
							out output);
			}
			else
			{
				// Create directory to hold repositories (to make directory structure similar to master/sub repository style).
				path = path + "\\" + customerCode;
				Directory.CreateDirectory(path);

				List<Repository> repositories;

				// Get list of repositories.
				using (var dataContext = new DatabaseDataContext())
				{
					repositories = (
						from customer in dataContext.Customers
						join customerRepository in dataContext.CustomerRepositories on customer.Id equals customerRepository.Customer
						join repository in dataContext.Repositories on customerRepository.Repository equals repository.Id
						where customer.Code == customerCode
						&& repository.HarvestFlag == true
						select repository).ToList();
				}

				// Loop through repositories.
				foreach (var repository in repositories)
				{
					WriteMessage("Cloning repository " + repository.URL.Substring(repository.URL.IndexOf(".cgi", StringComparison.InvariantCultureIgnoreCase) + 4), ConsoleColor.Cyan);

					// Clone repository to directory.
					string output;
					RunProgram("hg",
								"clone http://" + repository.URL,
								path,
								out output);
				}
			}

			return true;
		}

		/// <summary>
		/// Get master repository branches for customer.
		/// </summary>
		private static bool GetBranchesForCustomer(string customerCode, string path, List<MercurialName> branchList)
		{
			string output;

			// Run hg branches command.
			RunProgram("hg",
						"branches",
						path + customerCode,
						out output);

			// Loop through repository branches.
			var linePattern = new Regex(@"^(?<name>[\d\w.-_]+)\s+(?<revisionNumber>.+):(?<changesetId>.+)$");
			string[] branchesOutput = Regex.Split(output, "\n");
			foreach (var line in branchesOutput)
			{
				// Skip blank lines.
				if (line.Trim() == "") continue;

				// Split branch line into components.
				var match = linePattern.Match(line);
				if (!match.Success)
				{
					throw new Exception("Branch line does not have expected format.");
				}

				// Add branch to list.
				branchList.Add
				(
					new MercurialName()
					{
						Name = match.Groups["name"].Value,
						SubrepositoryList = new List<Subrepository>()
					}
				);
			}

			// Loop through branch list.
			foreach (var branch in branchList)
			{
				// Get subrepository ids.
				GetSubrepositoryIds(customerCode, path, branch);
			}

			return true;
		}

		/// <summary>
		/// Get master repository bookmarks for customer.
		/// </summary>
		private static bool GetBookmarksForCustomer(string customerCode, string path, List<MercurialName> bookmarkList)
		{
			string output;

			// Run hg bookmarks command.
			RunProgram("hg",
						"bookmarks",
						path + customerCode,
						out output);

			// Loop through repository bookmarks.
			var linePattern = new Regex(@"^\s{0,}(?<name>[\d\w.-_]+)\s+(?<revisionNumber>.+):(?<changesetId>.+)$");
			string[] bookmarksOutput = Regex.Split(output, "\n");
			foreach (var line in bookmarksOutput)
			{
				// Exit if no bookmarks are present.
				if (line == "no bookmarks set") return true;

				// Skip blank lines.
				if (line.Trim() == "") continue;

				// Split bookmark line into components.
				var match = linePattern.Match(line);
				if (!match.Success)
				{
					throw new Exception("Bookmark line does not have expected format.");
				}

				// Add bookmark to list.
				bookmarkList.Add
				(
					new MercurialName()
					{
						Name = match.Groups["name"].Value,
						SubrepositoryList = new List<Subrepository>()
					}
				);
			}

			// Loop through bookmark list.
			foreach (var bookmark in bookmarkList)
			{
				// Get subrepository ids.
				GetSubrepositoryIds(customerCode, path, bookmark);
			}

			return true;
		}

		/// <summary>
		/// Get subrepository ids.
		/// </summary>
		private static bool GetSubrepositoryIds(string customerCode, string path, MercurialName mercurialName)
		{
			string output;

			// Run hg update command to get Mercurial to switch to specified name.
			RunProgram("hg",
						"update " + mercurialName.Name,
						path + customerCode,
						out output);

			using (var reader = new StreamReader(path + customerCode + "\\.hgsubstate"))
			{
				// Read hgsubstate file.
				var linePattern = new Regex(@"^(?<changesetId>[\d\w]+)\s+(?<subrepositoryName>.+)$");
				String line;
				while ((line = reader.ReadLine()) != null)
				{
					// Skip blank lines.
					if (line.Trim() == "") continue;

					// Split hgsubstate line into components.
					var match = linePattern.Match(line);
					if (!match.Success)
					{
						throw new Exception("hgsubstate line does not have expected format.");
					}

					// Add subrepository to list
					mercurialName.SubrepositoryList.Add
					(
						new Subrepository()
						{
							Name = match.Groups["subrepositoryName"].Value,
							ChangesetId = match.Groups["changesetId"].Value
						}
					);
				}
			}

			return true;
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
		private static void DetermineBranches(ref List<RepositoryEntry> repositoryHistory, bool usesSubrepositories, ref List<MercurialName> masterBranchList, string feature)
		{
			// Does customer use Mercurial subrepositories?
			var numberOfEntries = repositoryHistory.Count();
			if (usesSubrepositories)
			{
				// Loop through branches.
				foreach (var branch in masterBranchList)
				{
					// Loop through subrepositories for branch.
					foreach (var subrepository in branch.SubrepositoryList)
					{
						// Are we on subrepository for feature?
						if (subrepository.Name == feature)
						{
							// Loop through subrepository history.
							for (int ii = 0; ii < numberOfEntries; ii++)
							{
								var repositoryEntry = repositoryHistory[ii];

								// Are we on tip for branch?
								if (repositoryEntry.ChangesetId == subrepository.ChangesetId)
								{
									// Add branch to current entry and all parents.
									AddBranch(ref repositoryHistory, ii, branch.Name);
								}
							}
						}
					}
				}
			}
			else
			{
				// Loop through repository history.
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
		private static void DetermineBookmarks(ref List<RepositoryEntry> repositoryHistory, bool usesSubrepositories, ref List<MercurialName> masterBookmarkList, string feature)
		{
			// Does customer use Mercurial subrepositories?
			var numberOfEntries = repositoryHistory.Count();
			if (usesSubrepositories)
			{
				// Loop through bookmarks.
				foreach (var bookmark in masterBookmarkList)
				{
					// Loop through subrepositories for bookmark.
					foreach (var subrepository in bookmark.SubrepositoryList)
					{
						// Are we on subrepository for feature?
						if (subrepository.Name == feature)
						{
							// Loop through subrepository history.
							for (int ii = 0; ii < numberOfEntries; ii++)
							{
								var repositoryEntry = repositoryHistory[ii];

								// Are we on tip for bookmark?
								if (repositoryEntry.ChangesetId == subrepository.ChangesetId)
								{
									// Add bookmark to current entry and all parents.
									AddBookmark(ref repositoryHistory, ii, bookmark.Name);
								}
							}
						}
					}
				}
			}
			else
			{
				// Loop through repository history.
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
		private static void SaveRepositoryHistory(string customerCode, string repository, string branch, string feature, ref List<RepositoryEntry> repositoryHistory)
		{
			// Format repository URL.
			string repositoryURL = repository;
			if (repositoryURL.Substring(0, 7) == "http://")
				repositoryURL = repositoryURL.Substring(7);

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

					ISingleResult<AddRepositoryEntryResult> result = dataContext.AddRepositoryEntry(customerCode,
																									repositoryURL,
																									branch,
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
