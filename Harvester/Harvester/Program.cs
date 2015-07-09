using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml;

namespace Harvester
{
	class Program
	{
		// This program supports multiple repository formats because the repository format has evolved over time.
		//
		// Repository format.
		// 1 = Single level repository structure where each feature, including custom feature, has a separate repository.
		// 2 = Master repository contains subrepositories for each feature for customer, including custom feature.
		// 3 = Master repository contains custom feature for customer and a shared j6 subrepository which contains all of the non-custom features.
		private static int _RepositoryFormat;

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
			WriteMessage("Jenkon Changeset Harvester", ConsoleColor.Green);
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

					// Does customer use Mercurial subrepositories?
					if (Directory.Exists(path + customer.Code + "\\.hg"))
					{
						// Does customer have a j6 subdirectory?
						if (Directory.Exists(path + customer.Code + "\\j6"))
						{
							_RepositoryFormat = 3;
						}
						else
						{
							_RepositoryFormat = 2;
						}
					}
					else
					{
						_RepositoryFormat = 1;
					}

					var masterBranchList = new List<MercurialName>();
					var masterBookmarkList = new List<MercurialName>();

					// Does customer use Mercurial subrepositories?
					if (_RepositoryFormat == 2 || _RepositoryFormat == 3)
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

					List<RepositoryEntry> repositoryHistory;

					FileInfo hgrcFile;
					string repository;
					string branch;

					switch (_RepositoryFormat)
					{
						case 1:
						case 2:
							// Loop through feature directories.
							foreach (var directory in Directory.GetDirectories(path + customer.Code))
							{
								// Skip Mercurial directory and Shared directory.
								if (!directory.EndsWith(".hg") && (!directory.EndsWith("\\Shared")))
								{
									// Does directory have a Mercurial configuration file?
									repository = "";
									hgrcFile = new FileInfo(directory + "\\.hg\\hgrc");
									if (hgrcFile.Exists)
									{
										// Get repository name from Mercurial configuration file.
										GetConfigItem(hgrcFile.FullName, "paths", "default", out repository);
									}

									// Split repository name into components.
									var repositoryPattern = new Regex(@"^.+/hgwebdir.cgi/(?<branch>.+)/(?<feature>[^/]+$)");
									var match = repositoryPattern.Match(repository);
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
									GetRepositoryHistory(directory, out repositoryHistory);

									// Load Parent indices for repository entries.
									LoadParentIndices(ref repositoryHistory);

									// Determine branches for repository entries.
									DetermineBranches(ref repositoryHistory, (_RepositoryFormat == 2), ref masterBranchList, feature);

									// Determine bookmarks for repository entries.
									DetermineBookmarks(ref repositoryHistory, (_RepositoryFormat == 2), ref masterBookmarkList, feature);

									// Save repository history to database.
									SaveRepositoryHistory(customer.Code, repository, branch, feature, ref repositoryHistory, ref masterBranchList);
								}
							}

							break;

						case 3:
							repository = "";
							hgrcFile = new FileInfo(path + customer.Code + "\\.hg\\hgrc");
							if (hgrcFile.Exists)
							{
								// Get repository name from Mercurial configuration file.
								GetConfigItem(hgrcFile.FullName, "paths", "default", out repository);
							}

							branch = "customers/" + customer.Code;
							WriteMessage(branch + " " + customer.Code, ConsoleColor.Cyan);

							// Get repository history for master repository.
							GetRepositoryHistory(path + customer.Code, out repositoryHistory);

							// Load Parent indices for repository entries.
							LoadParentIndices(ref repositoryHistory);

							// Determine branches for repository entries.
							DetermineBranches(ref repositoryHistory, true, ref masterBranchList, customer.Code);

							// Determine bookmarks for repository entries.
							DetermineBookmarks(ref repositoryHistory, true, ref masterBookmarkList, customer.Code);

							// Determine features for branches.
							DetermineFeatures(customer.Code, path, ref repositoryHistory, ref masterBranchList);

							// Save repository history to database.
							SaveRepositoryHistory(customer.Code, repository, branch, null, ref repositoryHistory, ref masterBranchList);

							repository = "";
							hgrcFile = new FileInfo(path + customer.Code + "\\j6" + "\\.hg\\hgrc");
							if (hgrcFile.Exists)
							{
								// Get repository name from Mercurial configuration file.
								GetConfigItem(hgrcFile.FullName, "paths", "default", out repository);
							}

							WriteMessage(branch + " " + "j6", ConsoleColor.Cyan);

							// Get repository history for j6 subrepository.
							GetRepositoryHistory(path + customer.Code + "\\j6", out repositoryHistory);

							// Load Parent indices for repository entries.
							LoadParentIndices(ref repositoryHistory);

							// Determine branches for repository entries.
							DetermineBranches(ref repositoryHistory, true, ref masterBranchList, "j6");

							// Determine bookmarks for repository entries.
							DetermineBookmarks(ref repositoryHistory, true, ref masterBookmarkList, "j6");

							// Save repository history to database.
							SaveRepositoryHistory(customer.Code, repository, branch, null, ref repositoryHistory, ref masterBranchList);

							break;
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

				// Clone master repository and subrepositories to directory.
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

			// Run hg log command to determine cutoff revision.
			// (The AddDays is used to specify how many days back we are willing to go.)
			string styleFile = "\"" + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\hglogstyle-revision.txt" + "\"";
			RunProgram("hg",
						"log --style " + styleFile + " -r \"last(date('<" + DateTime.Now.AddDays(-7).ToString("yyyy-M-d") + "'))\"",
						path + customerCode,
						out output);
			int cutoffRevisionNumber = int.Parse(output);

			// Run hg branches command.
			RunProgram("hg",
						"branches",
						path + customerCode,
						out output);

			// Loop through repository branches.
			var linePattern = new Regex(@"^(?<name>[\d\w#\-._]+)\s+(?<revisionNumber>.+):(?<changesetId>[\d\w]+)\s*(?<status>.*)$");
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

				// Is branch active or does branch have a changeset newer than cutoff?
				int branchRevisionNumber = int.Parse(match.Groups["revisionNumber"].Value);
				if (!((match.Groups["status"].Value != "") || (branchRevisionNumber < cutoffRevisionNumber)))
				{
					// Add branch to list.
					branchList.Add
					(
						new MercurialName
						{
							Name = match.Groups["name"].Value,
							SubrepositoryList = new List<Subrepository>()
						}
					);
				}
			}

			// Loop through branch list.
			foreach (var branch in branchList)
			{
				// Get subrepository ids.
				GetSubrepositoryIds(customerCode, path, "branch", branch);
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
			var linePattern = new Regex(@"^\s{0,}(?<name>[\d\w#\-._]+)\s+(?<revisionNumber>.+):(?<changesetId>.+)$");
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
					new MercurialName
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
				GetSubrepositoryIds(customerCode, path, "bookmark", bookmark);
			}

			return true;
		}

		/// <summary>
		/// Get subrepository ids.
		/// </summary>
// ReSharper disable UnusedMethodReturnValue.Local
		private static bool GetSubrepositoryIds(string customerCode, string path, string mercurialType, MercurialName mercurialName)
// ReSharper restore UnusedMethodReturnValue.Local
		{
			string output;

			switch (_RepositoryFormat)
			{
				case 2:
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
								new Subrepository
								{
									Name = match.Groups["subrepositoryName"].Value,
									ChangesetId = match.Groups["changesetId"].Value
								}
							);
						}
					}

					break;

				case 3:
					string styleFile = "\"" + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\hglogstyle-changeset.txt" + "\"";

					// Run hg log command to get master repository changeset for branch or bookmark.
					RunProgram("hg",
								"log --style " + styleFile + " -r \"last(" + mercurialType + "(r'" + mercurialName.Name + "'))\"",
								path + customerCode,
								out output);

					// Add master repository to list
					mercurialName.SubrepositoryList.Add
					(
						new Subrepository
						{
							Name = customerCode,
							ChangesetId = output
						}
					);

					try
					{
						// Run hg log command to get j6 subrepository changeset for branch or bookmark.
						RunProgram("hg",
								   "log --style " + styleFile + " -r \"last(" + mercurialType + "(r'" + mercurialName.Name + "'))\"",
								   path + customerCode + "\\j6",
								   out output);

						// Add subrepository to list
						mercurialName.SubrepositoryList.Add
						(
							new Subrepository
							{
								Name = "j6",
								ChangesetId = output
							}
						);
					}
// ReSharper disable EmptyGeneralCatchClause
					catch
// ReSharper restore EmptyGeneralCatchClause
					{
						// Subrepository may not have branch or bookmark that master does so ignore resulting error.
					}

					break;

				default:
					throw new Exception(string.Format("GetSubrepositoryIds received an unsupported repository format '{0}'.", _RepositoryFormat));
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
			string styleFile = "\"" + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\hglogstyle-history.txt" + "\"";
			RunProgram("hg", "log --style " + styleFile, repositoryDirectory, out output);
			string[] rawRepositoryHistory = Regex.Split(output, "\n");

			// Loop through repository history.
			var nextType = 1;
			var revisionNumber = "";
			var changesetId = "";
			var changesetBranch = "";
			var branches = "";
			var bookmarks = "";
			var parents = "";
			var user = "";
			var date = DateTime.MinValue;
			var summary = "";
// ReSharper disable TooWideLocalVariableScope
// ReSharper disable RedundantAssignment
			var files = "";
// ReSharper restore RedundantAssignment
// ReSharper restore TooWideLocalVariableScope
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
						changesetBranch = "";
						branches = "";
						bookmarks = "";
						parents = "";
						user = "";
						date = DateTime.MinValue;
						summary = "";
// ReSharper disable RedundantAssignment
						files = "";
// ReSharper restore RedundantAssignment
						nextType++;
						break;
					case 2:
						branches = match.Groups["value"].Value;
						var branchList = Regex.Split(branches, @"\*\^\*");
						if ((branchList.Count() == 1)
						&& (branchList[0].Trim() == ""))
						{
							// No branches.
						}
						else if ((branchList.Count() == 2)
						&& (branchList[1].Trim() == ""))
						{
							changesetBranch = branchList[0];
						}
						else
						{
							throw new Exception("Repository history branches line has more than one branch.");
						}
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
							ChangesetBranch = changesetBranch,
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
					RedirectStandardError = true,
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
									break;
								}
							}
							break;
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
									break;
								}
							}
							break;
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

		private static List<int> _CheckedRepositoryEntryList;
		private static int _ClosestFeatureDepth;
		private static FeatureEntry _ClosestFeatureEntry;

		/// <summary>
		/// Determine features for repository entries.
		/// </summary>
		private static void DetermineFeatures(string customerCode, string path, ref List<RepositoryEntry> repositoryHistory, ref List<MercurialName> masterBranchList)
		{
			// Get features from all Feature.xml files.
			List<FeatureEntry> featureEntryList = GetAllFeatures(customerCode, path);

			// Loop through branches.
			foreach (var branch in masterBranchList)
			{
				// Loop through subrepositories for branch.
				foreach (var subrepository in branch.SubrepositoryList)
				{
					// Are we on subrepository for custom feature?
					if (subrepository.Name == customerCode)
					{
						// Loop through repository history.
						var numberOfEntries = repositoryHistory.Count();
						for (int ii = 0; ii < numberOfEntries; ii++)
						{
							// Are we on tip for branch?
							var repositoryEntry = repositoryHistory[ii];
							if (repositoryEntry.ChangesetId == subrepository.ChangesetId)
							{
								// Find closest feature entry.
								_CheckedRepositoryEntryList = new List<int>();
								_ClosestFeatureDepth = 1000000;
								_ClosestFeatureEntry = new FeatureEntry
								{
									ChangesetId = null,
									FeatureList = new List<string>()
								};
								FindClosestFeatureEntry(ref featureEntryList, ref repositoryHistory, ii, 0);
								branch.FeatureList = _ClosestFeatureEntry.FeatureList;

								// Add custom feature if not present.
								if (!branch.FeatureList.Contains(customerCode))
								{
									branch.FeatureList.Add(customerCode);
								}
								break;
							}
						}
						break;
					}
				}
			}
		}

		/// <summary>
		/// Get features from all Feature.xml files.
		/// </summary>
		private static List<FeatureEntry> GetAllFeatures(string customerCode, string path)
		{
			var featureEntryList = new List<FeatureEntry>();

			string output;

			// Run hg log command to find Feature.xml files.
			string styleFile = "\"" + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\hglogstyle-changesethistory.txt" + "\"";
			RunProgram("hg",
						"log --style " + styleFile + " CUST000/Feature.xml",
						path + customerCode,
						out output);

			// Loop through changesets with a Feature.xml file.
			string[] changesetIdList = Regex.Split(output, @"\*\^\*");
			foreach (string changesetId in changesetIdList)
			{
				// Skip last entry in list.
				if (changesetId == "") continue;

				// Get Feature.xml features.
				List<string> featureList = GetFeatures(customerCode, path, changesetId);

				// Add changeset info to feature entry list.
				featureEntryList.Add(new FeatureEntry
				{
					ChangesetId = changesetId,
					FeatureList = featureList
				});
			}

			return featureEntryList;
		}

		/// <summary>
		/// Get Feature.xml features.
		/// </summary>
		private static List<string> GetFeatures(string customerCode, string path, string changesetId)
		{
			var featureList = new List<string>();

			string output;

			// Run hg cat command to retrieve contents of Feature.xml file.
			RunProgram("hg",
						"cat -r " + changesetId + " " + customerCode + "/Feature.xml",
						path + customerCode,
						out output);

			// Parse features from file.
			var featureDocument = new XmlDocument();
			featureDocument.LoadXml(output);
			XmlNodeList featureNodeList = featureDocument.SelectNodes("/Feature/Requires/Require");
			if (featureNodeList != null)
			{
				featureList.AddRange((from XmlNode featureNode in featureNodeList orderby featureNode.InnerText select featureNode.InnerText).Distinct());
			}

			return featureList;
		}

		/// <summary>
		/// Find closest feature entry.
		/// </summary>
		private static void FindClosestFeatureEntry(ref List<FeatureEntry> featureEntryList, ref List<RepositoryEntry> repositoryHistory, int currentIndex, int depth)
		{
			var repositoryEntry = repositoryHistory[currentIndex];

			// Skip repository entry if we already checked it.
			if (_CheckedRepositoryEntryList.Contains(currentIndex))
			{
				return;
			}

			// Add repository entry to checked list.
			_CheckedRepositoryEntryList.Add(currentIndex);

			// Loop through feature entries.
			foreach (var featureEntry in featureEntryList)
			{
				// Does repository entry match a feature entry?
				if (featureEntry.ChangesetId == repositoryEntry.ChangesetId)
				{
					// Is repository entry closer to tip than prior match?
					if (depth < _ClosestFeatureDepth)
					{
						// Save matching feature entry.
						_ClosestFeatureDepth = depth;
						_ClosestFeatureEntry = featureEntry;
					}
					break;
				}
			}

			// Loop through parent entries.
			foreach (int parentIndex in repositoryEntry.ParentIndexList)
			{
				FindClosestFeatureEntry(ref featureEntryList, ref repositoryHistory, parentIndex, depth + 1);
			}
		}

		/// <summary>
		/// Save repository history to database.
		/// </summary>
		private static void SaveRepositoryHistory(string customerCode, string repository, string branch, string feature, ref List<RepositoryEntry> repositoryHistory, ref List<MercurialName> masterBranchList)
		{
			// Format repository URL.
			string repositoryUrl = repository;
			if (repositoryUrl.Substring(0, 7) == "http://")
				repositoryUrl = repositoryUrl.Substring(7);

			// Loop through repository history.
			foreach (var repositoryEntry in repositoryHistory)
			{
				using (var dataContext = new DatabaseDataContext())
				{
					dataContext.CommandTimeout = 3600;

					switch (_RepositoryFormat)
					{
						case 1:
						case 2:
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

							var result = dataContext.AddRepositoryEntry(customerCode,
																		repositoryUrl,
																		branch,
																		feature,
																		repositoryEntry.ChangesetId,
																		repositoryEntry.User,
																		repositoryEntry.CreatedDateTime,
																		repositoryEntry.Summary,
																		repositoryEntry.Files,
																		branches.ToString(),
																		bookmarks.ToString(),
																		repositoryEntry.ChangesetBranch,
																		repositoryEntry.IssueNumber);
							if ((int)result.ReturnValue != 0)
								throw new Exception("Error while adding repository entry to database.");

							break;

						case 3:
							// Loop through repository entry files.
							var fileFeaturePattern = new Regex(@"^(?<action>\w+):(?<feature>.+?)/.+$");
							var fileList = Regex.Split(repositoryEntry.Files, @"\*\^\*");
							var fileFeatureList = new List<string>();
							var filePortalList = new List<string>();
							foreach (var file in fileList)
							{
								// Skip last entry in list.
								if (file == "") continue;

								// Determine feature for file.
								// (Ignore mismatches because some files are in root directory and not tied to a feature.)
								var match = fileFeaturePattern.Match(file);
								if (match.Success)
								{
									var fileFeature = match.Groups["feature"].Value;

									// Add feature to list if not already present.
									if (!fileFeatureList.Contains(fileFeature))
									{
										fileFeatureList.Add(fileFeature);
									}
								}

								// Determine j6 portal(s) for file and add to list.
								DeterminePortalsForFile(file, ref filePortalList);
							}

							// Loop through repository entry features.
							foreach (var fileFeature in fileFeatureList)
							{
								// Add changeset.
								var addChangesetResult = dataContext.AddChangeset(customerCode,
																					repositoryUrl,
																					branch,
																					fileFeature,
																					repositoryEntry.ChangesetId,
																					repositoryEntry.User,
																					repositoryEntry.CreatedDateTime,
																					repositoryEntry.Summary,
																					repositoryEntry.Files,
																					repositoryEntry.ChangesetBranch,
																					repositoryEntry.IssueNumber);
								if ((int)addChangesetResult.ReturnValue != 0)
									throw new Exception("Error while adding changeset to database.");

								// Loop through repository entry branches.
								foreach (var entryBranch in repositoryEntry.BranchList)
								{
									// Find feature list for branch.
									foreach (var masterBranch in masterBranchList)
									{
										if (entryBranch == masterBranch.Name)
										{
											// Does feature list include repository entry feature?
											if (masterBranch.FeatureList.Contains(fileFeature))
											{
												// Add branch.
												var addBranchResult = dataContext.AddBranch(branch, fileFeature, repositoryEntry.ChangesetId, entryBranch);
												if ((int)addBranchResult.ReturnValue != 0)
													throw new Exception("Error while adding branch to database.");
											}

											break;
										}
									}
								}

								// Loop through repository entry bookmarks.
								foreach (var entryBookmark in repositoryEntry.BookmarkList)
								{
									// Add bookmark.
									var addBookmarkResult = dataContext.AddBookmark(branch, fileFeature, repositoryEntry.ChangesetId, entryBookmark);
									if ((int)addBookmarkResult.ReturnValue != 0)
										throw new Exception("Error while adding bookmark to database.");
								}
							}

							// Loop through repository entry portals.
							foreach (var portal in filePortalList)
							{
								// Add portal.
								var addPortalResult = dataContext.AddPortal(repositoryEntry.ChangesetId, portal);
								if ((int)addPortalResult.ReturnValue != 0)
									throw new Exception("Error while adding portal to database.");
							}

							break;
					}
				}
			}
		}

		/// <summary>
		/// Determine j6 portal(s) for file and add to list.
		/// </summary>
		private static void DeterminePortalsForFile(string file, ref List<string> filePortalList)
		{
			var fileConsultantPattern = new Regex(@"^WebBusiness/.+$|^.+/Site/Business/.+$|^WebConsultant/.+$|^.+/Site/Consultant/.+$");
			var fileEmployeePattern = new Regex(@"^WebEmployee/.+$|^.+/Site/Employee/.+$");
			var filePersonalPattern = new Regex(@"^WebPersonal/.+$|^.+/Site/Personal/.+$");
			var fileServicePattern = new Regex(@"^WebService/.+$|^.+/Site/Service/.+$|^.+/Site/Services/.+$");

			string portal;

			// Determine portal for file.
			var match = fileConsultantPattern.Match(file);
			if (match.Success)
			{
				portal = "Business";
				if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
			}
			else
			{
				match = fileEmployeePattern.Match(file);
				if (match.Success)
				{
					portal = "Corporate";
					if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
				}
				else
				{
					match = filePersonalPattern.Match(file);
					if (match.Success)
					{
						portal = "PWS";
						if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
					}
					else
					{
						match = fileServicePattern.Match(file);
						if (match.Success)
						{
							portal = "Services";
							if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
						}
						else
						{
							portal = "Business";
							if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
							portal = "Corporate";
							if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
							portal = "PWS";
							if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
							portal = "Services";
							if (!filePortalList.Contains(portal)) filePortalList.Add(portal);
						}
					}
				}
			}
		}
	}
}
