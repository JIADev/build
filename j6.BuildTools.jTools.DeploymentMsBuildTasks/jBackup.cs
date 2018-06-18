using System;
using System.IO;
using System.Linq;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using DeploymentTool;
// ReSharper disable RedundantStringFormatCall

namespace DeploymentMsBuildTasks
{
// ReSharper disable InconsistentNaming
	public class jBackup : Task
// ReSharper restore InconsistentNaming
	{
		[Required]
		public string[] AppServers { get; set; }

		public bool SkipNonExistant { get; set; }

		public override bool Execute()
		{
			if(!AppServers.Any())
				throw new ArgumentException("No AppServers Specified for jBackup");
			var appServers = MsBuild.DeserializeServers<AppServer>(AppServers);
			var moves = appServers.Select(
				ap =>
				new
					{
						AppLocation = Path.Combine("\\\\" + ap.HostName, ap.AppLocation.Replace(':', '$')),
						BackupLocation = Path.Combine("\\\\" + ap.HostName, ap.BackupLocation.Replace(':', '$'))
					}).ToArray();
			var returnValue = true;
			foreach(var path in moves.Where(m => !Directory.Exists(m.AppLocation)))
			{
				if (SkipNonExistant)
				{
					Console.ForegroundColor = ConsoleColor.Yellow;
					Console.WriteLine(string.Format("Path does not exist: {0}, skipping", path.AppLocation));
					Console.ResetColor();
				}
				else
				{
					Console.ForegroundColor = ConsoleColor.Red;
					Console.Error.WriteLine(string.Format("Path does not exist: {0}", path.AppLocation));
					Console.ResetColor();
					returnValue = false;
				}
			}
			if (!returnValue)
				return false;

			moves.Where(m => Directory.Exists(m.AppLocation)).AsParallel().ForAll(move =>
				{
					var success = Move(move.AppLocation, move.BackupLocation);
					returnValue = returnValue && success;
				});

			return returnValue;
		}

		private bool Move(string source, string target)
		{
			string targetPath = null;
			try
			{
				var sourceInfo = new DirectoryInfo(source);

				var targetInfo = new DirectoryInfo(Path.Combine(target, DateTime.UtcNow.ToString("yyyy-MM-dd")));
				if (targetInfo.Exists)
					targetInfo = new DirectoryInfo(Path.Combine(target, DateTime.UtcNow.ToString("yyyy-MM-dd_HHmmss")));
				targetInfo.Create();
				targetPath = Path.Combine(targetInfo.FullName, sourceInfo.Name);
				Console.WriteLine(string.Format("Moving {0} to {1}", sourceInfo.FullName, targetPath));
				sourceInfo.MoveTo(targetPath);
				return true;
			}
			catch (Exception ex)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.Error.WriteLine(string.Format("Error moving {0} to {1}: {2}", source, targetPath ?? target, ex.Message));
				Console.ResetColor();
				return false;
			}
		}
	}
}
