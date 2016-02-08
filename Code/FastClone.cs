using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
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
		private List<Thread> _runningThreads = new List<Thread>(); 
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
			return CopyDirectory(hgDir, new DirectoryInfo(Path.Combine(localDir.FullName, ".hg")));
		}

		private bool CopyDirectory(DirectoryInfo source, DirectoryInfo target)
		{
			if (!_runningThreads.Contains(Thread.CurrentThread))
				lock (_runningThreads)
				{
					_runningThreads.Add(Thread.CurrentThread);
				}

			try
			{
				Console.Write(".");
				var sourceFiles = source.GetFileSystemInfos();

				if (!target.Exists)
					target.Create();

				foreach (var sourceFile in sourceFiles)
				{
					if (_cancelRequested)
					{
						return false;
					}

					var directory = sourceFile as DirectoryInfo;
					var file = sourceFile as FileInfo;

					if (directory != null)
						CopyDirectory(directory, new DirectoryInfo(Path.Combine(target.FullName, directory.Name)));

					if (file != null)
						file.CopyTo(Path.Combine(target.FullName, file.Name));
				}
			}
			catch (Exception ex)
			{
				WriteError(ex.Message);
				return false;
			}
			return true;
		}

		private DirectoryInfo GetSourceLocation(string repository)
		{
			var prefix = _prefixes.SingleOrDefault(pre => repository.StartsWith(pre.Key, StringComparison.InvariantCultureIgnoreCase));
			
			if (prefix.Equals(default(KeyValuePair<string, string>)))
			{
				WriteError(string.Format("Prefix must start with one of: {0}", string.Join(", ", _prefixes.Keys)));
				return null;
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

			var timeout = DateTime.UtcNow.AddSeconds(CancelTimeout);
			
			while (_runningThreads.Any(t => t.IsAlive) && DateTime.UtcNow < timeout)
				Thread.Sleep(100);

			var livingThread = _runningThreads.FirstOrDefault(t => t.IsAlive);
			timeout = DateTime.UtcNow.AddSeconds(CancelTimeout);
			while (livingThread != null && DateTime.UtcNow < timeout)
			{
				livingThread.Abort();
				Thread.Sleep(100);
				livingThread = _runningThreads.FirstOrDefault(t => t.IsAlive);
			}
			var currentProcess = Process.GetCurrentProcess();
			WriteError(string.Format("Killing {0} (PID {1})", currentProcess.ProcessName, currentProcess.Id));
			currentProcess.Kill();
		}
	}
}
