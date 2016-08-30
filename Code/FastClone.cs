﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Build.Framework;
using System.IO;

namespace j6.BuildTools.MsBuildTasks
{
	public class FastClone : HgTask, ICancelableTask
	{
		public FastClone()
		{
			CancelTimeout = 5;
		}
		private bool _cancelRequested;
	    private long _totalBytesCopied;
	    private long? _totalSize;
	    private string _totalSizeString;
	    private DateTime? _startTime;
        private readonly Dictionary<string, string> _prefixes = new Dictionary<string, string> { { "repos://", @"\\repo.jenkon.com\repo$\" } };

		[Required]
		public string Repository { get; set; }

		[Required]
		public string LocalDir { get; set; }

		[Required]
		public string ParentLocation { get; set; }

		public int CancelTimeout { get; set; }

		public override bool Execute()
		{
			var localDir = new DirectoryInfo(Path.Combine(ParentLocation, LocalDir));
			if (!EnsureDirectoryEmpty(localDir))
				return false;
			
			var source = GetSourceLocation(Repository);
			
			if (source == null || !source.Exists)
				return false;

			var hgDir = source.GetDirectories(".hg").SingleOrDefault();
			if (hgDir == null || !hgDir.Exists)
				return false;
			Console.WriteLine("Cloning {0} to {1}, please wait", Repository, localDir);
			var errorOccurred = false;
			var wasCancelled = false;
			var targetDir = new DirectoryInfo(Path.Combine(localDir.FullName, ".hg"));
			try
			{
			    var task = new Task(() =>
					{
						try
						{
						    _totalSize = GetSize(hgDir);
                            _totalSizeString = HumanReadableSize(_totalSize.Value);
						}
// ReSharper disable EmptyGeneralCatchClause
						catch
// ReSharper restore EmptyGeneralCatchClause
						{
							// Oh well
						}
					});
				task.Start();
				_startTime = DateTime.UtcNow;
				CopyDirectory(hgDir, targetDir, out wasCancelled);
			}
			catch (Exception ex)
			{
				WriteError(ex.Message);
				errorOccurred = true;
			}
			Console.WriteLine();
			if (_startTime.HasValue)
			{
				var runningTime = DateTime.UtcNow - _startTime.Value;

				Console.WriteLine("{0} cloned in {1} ({2}/sec)", HumanReadableSize(_totalBytesCopied), runningTime,
                                  HumanReadableSize(_totalBytesCopied / runningTime.TotalSeconds));
			}
			if (wasCancelled && targetDir.Exists)
			{
				Console.Write("Cleaning Up...");
				targetDir.Delete(true);
			}
			return !errorOccurred && !wasCancelled;
		}

		private long GetSize(DirectoryInfo source)
		{
			var sourceInfos = source.GetFileSystemInfos();
			var fileSystemInfoComparer = new FileSystemInfoComparer();
			var sourceFiles = sourceInfos.Distinct(fileSystemInfoComparer)
											.GroupBy(f => f.FullName, StringComparer.InvariantCultureIgnoreCase)
											.Select(f => f.First()).OfType<FileInfo>();
			var sourceDirs = sourceInfos.Distinct(fileSystemInfoComparer)
							   .GroupBy(f => f.FullName, StringComparer.InvariantCultureIgnoreCase)
							   .Select(f => f.First()).OfType<DirectoryInfo>().ToArray();
			long size = 0;

			foreach (var file in sourceFiles)
			{
				if (_cancelRequested)
					return size;

				size += file.Length;
			}

			foreach (var sourceDir in sourceDirs)
			{
				if (_cancelRequested)
					return size;

				size += GetSize(sourceDir);
			}

			return size;
		}

		private void CopyDirectory(DirectoryInfo source, DirectoryInfo target, out bool cancelled)
		{
			if (_cancelRequested)
			{
				cancelled = true;
				return;
			}
			var fileSystemInfoComparer = new FileSystemInfoComparer();

			var sourceFiles = source.GetFileSystemInfos().Distinct(fileSystemInfoComparer).GroupBy(f => f.Name, StringComparer.InvariantCultureIgnoreCase).Select(f => new { f.Key, Files = f.ToArray() })
                .OrderByDescending(s => s.Files.Length).ThenBy(s => s.Files.First() is DirectoryInfo ? 0 : 1).ToArray();
			
				if (!target.Exists)
					target.Create();
			
			foreach (var sf in sourceFiles)
			{
				if(sf.Files.Length > 1)
					Console.WriteLine("Duplicate file name: {0}: ", string.Join(", ", sf.Files.Select(s => s.FullName)));
				var sourceFile = sf.Files.First();
				if (_cancelRequested)
				{
					cancelled = true;
					return;
				}

				var directory = sourceFile as DirectoryInfo;
				var file = sourceFile as FileInfo;
				bool wasCancelled;
				if (directory != null)
					CopyDirectory(directory, new DirectoryInfo(Path.Combine(target.FullName, directory.Name)), out wasCancelled);

				if (file == null) continue;

				var outputFile = Path.Combine(target.FullName, file.Name);
				var completed = CopyIncrementally(file, outputFile, bytesRead =>
				    {
                        _totalBytesCopied += bytesRead; 
                        var runningTime = _startTime.HasValue ? (DateTime.UtcNow - _startTime.Value) : default(TimeSpan?);
						Console.SetCursorPosition(0, Console.CursorTop);
						
                        var total = _totalSize.HasValue && !string.IsNullOrWhiteSpace(_totalSizeString)
							            ? string.Format("{0}/{1} ({2}%)", HumanReadableSize(_totalBytesCopied), _totalSizeString,
														(_totalBytesCopied * 100) / _totalSize.Value)
                                        : HumanReadableSize(_totalBytesCopied);

						var message = runningTime.HasValue
                                          ? string.Format("{0} copied ({1}/sec.)", total, HumanReadableSize(_totalBytesCopied / runningTime.Value.TotalSeconds))
							              : string.Format("{0} copied.", total);
							
						if (message.Length > Console.WindowWidth - 1)
							message = message.Substring(Console.WindowWidth - 1);
						var newMessageLength = message.Length;
						var blanksNeeded = Console.WindowWidth - newMessageLength - 1;
						var chars = new string(new char[blanksNeeded].Select(c => ' ').ToArray());
						message = string.Format("{0}{1}", message, chars);
						
						Console.Write(message);
						return _cancelRequested;
					});

			    if (completed) continue;

			    var fileCopied = new FileInfo(outputFile);
			    if (!fileCopied.Exists) continue;

			    _totalBytesCopied -= fileCopied.Length;
			    File.Delete(outputFile);
			}
			cancelled = false;
		}

		private static bool CopyIncrementally(FileInfo file, string targetFile, Func<long, bool> cancelCallback)
		{
			var buffer = new byte[4096];
				
			using(var input = file.Open(FileMode.Open, FileAccess.Read, FileShare.Read))
			using (var output = new FileStream(targetFile, FileMode.CreateNew, FileAccess.Write, FileShare.None))
			{
				while (input.Position < input.Length)
				{
					var bytesRead = input.Read(buffer, 0, buffer.Length);
					output.Write(buffer, 0, bytesRead);
					if (cancelCallback != null && cancelCallback(bytesRead))
						return false;
				}
			}
			return true;
		}

		private DirectoryInfo GetSourceLocation(string repository)
		{
			var prefix = _prefixes.SingleOrDefault(pre => repository.StartsWith(pre.Key, StringComparison.InvariantCultureIgnoreCase));
			
			if (prefix.Equals(default(KeyValuePair<string, string>)))
			{
				//WriteError(string.Format("Prefix must start with one of: {0}", string.Join(", ", _prefixes.Keys)));
				var dirInfo = new DirectoryInfo(repository);
				return dirInfo.Exists ? dirInfo : null;
			}

			return new DirectoryInfo(repository.Replace(prefix.Key, prefix.Value));
		}

		private bool EnsureDirectoryEmpty(DirectoryInfo localDir)
		{
			if (!localDir.Exists)
			{
				localDir.Create();
				return true;
			}

			var fsInfos = localDir.GetFileSystemInfos();
			
			if (fsInfos.Any())
			{
				WriteError(string.Format("Directory {0} is not empty", localDir.FullName));
				return false;
			}
			return true;
		}

		public void Cancel()
		{
			WriteError("Cancel requested by user");
			_cancelRequested = true;
		}
	}
}
