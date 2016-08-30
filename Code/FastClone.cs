using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
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
			long bytesRead = 0;
			var errorOccurred = false;
			var startTime = default(DateTime?);
			var wasCancelled = false;
			var targetDir = new DirectoryInfo(Path.Combine(localDir.FullName, ".hg"));
			try
			{
				var totalToCopy = default(long?);
				var task = new Task(() =>
					{
						try
						{
							totalToCopy = GetSize(hgDir);
							return;
						}
// ReSharper disable EmptyGeneralCatchClause
						catch
// ReSharper restore EmptyGeneralCatchClause
						{
							// Oh well
						}
					});
				task.Start();
				startTime = DateTime.UtcNow;
				bytesRead = CopyDirectory(hgDir, targetDir, out wasCancelled, ref totalToCopy, startTime.Value);
			}
			catch (Exception ex)
			{
				WriteError(ex.Message);
				errorOccurred = true;
			}
			Console.WriteLine();
			if (startTime.HasValue)
			{
				var runningTime = DateTime.UtcNow - startTime.Value;

				Console.WriteLine("{0} cloned in {1} ({2}/sec)", HumanReadableSize(bytesRead), runningTime,
				                  HumanReadableSize(bytesRead/runningTime.TotalSeconds));
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
			long[] size = {0};

			foreach (var file in sourceFiles)
			{
				if (_cancelRequested)
					return size[0];

				size[0] += file.Length;
			}

			var index = 0;
			const int take = 2;
			while(index < sourceDirs.Length)
			{
				var dirs = sourceDirs.Skip(index).Take(take).ToArray();
				dirs.AsParallel().ForAll(sourceDir =>
								   {
									   if (_cancelRequested)
										   return;
									   
									   size[0] += GetSize(sourceDir);
								   });
				index += dirs.Length;
			}
			
			return size[0];
		}

		private long CopyDirectory(DirectoryInfo source, DirectoryInfo target, out bool cancelled, ref long? totalSize, DateTime? startTime = default(DateTime?))
		{
			if (_cancelRequested)
			{
				cancelled = true;
				return 0;
			}

			var sourceFiles = source.GetFileSystemInfos();

				if (!target.Exists)
					target.Create();
				var fileSystemInfoComparer = new FileSystemInfoComparer();
			long bytesCopied = 0;
			var totalSizeString = totalSize.HasValue
				                      ? HumanReadableSize(totalSize.Value)
				                      : default(string);
			foreach (var sourceFile in sourceFiles.Distinct(fileSystemInfoComparer).GroupBy(f => f.FullName, StringComparer.InvariantCultureIgnoreCase).Select(f => f.First()))
			{
				if (_cancelRequested)
				{
					cancelled = true;
					return bytesCopied;
				}

				var directory = sourceFile as DirectoryInfo;
				var file = sourceFile as FileInfo;
				bool wasCancelled;
				if (directory != null)
					bytesCopied += CopyDirectory(directory, new DirectoryInfo(Path.Combine(target.FullName, directory.Name)), out wasCancelled, ref totalSize, startTime);

				if (file == null) continue;

				var outputFile = Path.Combine(target.FullName, file.Name);
				var completed = CopyIncrementally(file, outputFile, bytesCopied, startTime, ref totalSize, ref totalSizeString, (bytesRead, runningTime, totSize, totSizeString) =>
					{
						Console.SetCursorPosition(0, Console.CursorTop);
						if (totSizeString == default(string) && totSize.HasValue)
							totSizeString = HumanReadableSize(totSize.Value);
						var total = totSize.HasValue
							            ? string.Format("{0}/{1} ({2}%)", HumanReadableSize(bytesRead), totSizeString,
														(bytesRead * 100) / totSize.Value)
							            : HumanReadableSize(bytesRead);

						var message = runningTime.HasValue 
							              ? string.Format("{0} copied ({1}/sec.)", total, HumanReadableSize(bytesRead/runningTime.Value.TotalSeconds))
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
				if(completed)
					bytesCopied += file.Length;
				else if(File.Exists(outputFile))
					File.Delete(outputFile);
			}
			cancelled = false;
			return bytesCopied;
		}

		private bool CopyIncrementally(FileInfo file, string targetFile, long bytesCopied, DateTime? startTime, ref long? totalSize, ref string totalSizeString, Func<long, TimeSpan?, long?, string, bool> cancelCallback)
		{
			var buffer = new byte[4096];
				
			using(var input = file.Open(FileMode.Open, FileAccess.Read, FileShare.Read))
			using (var output = new FileStream(targetFile, FileMode.CreateNew, FileAccess.Write, FileShare.None))
			{
				while (input.Position < input.Length)
				{
					var bytesRead = input.Read(buffer, 0, buffer.Length);
					output.Write(buffer, 0, bytesRead);
					if (cancelCallback != null && cancelCallback(bytesCopied + input.Position, startTime.HasValue ? (DateTime.UtcNow - startTime.Value) : default(TimeSpan?), totalSize, totalSizeString))
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
