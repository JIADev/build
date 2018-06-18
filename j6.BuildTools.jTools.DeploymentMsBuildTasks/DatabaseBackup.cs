using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace DeploymentMsBuildTasks
{
	public class DatabaseBackup : Task
	{
		[Required]
		public string DatabaseName { get; set; }

		[Required]
		public string DatabaseServer { get; set; }

		[Required]
		public string BackupLocation { get; set; }

		public string SqlInstance { get; set; }

		public string BackupFileSuffix { get; set; }

		public DatabaseBackup()
		{
			BackupFileSuffix = "PriorToRelease";
		}
		public override bool Execute()
		{
			var sqlInstance = string.IsNullOrWhiteSpace(SqlInstance)
				                   ? DatabaseServer
				                   : string.Format("{0}\\{1}", DatabaseServer, SqlInstance);
			Console.WriteLine("Backing up database {0} on {1}", DatabaseName, sqlInstance);
			try
			{
				var stringBuilder = new SqlConnectionStringBuilder
					{
						ApplicationName = "j6 Deployment Task",
						DataSource = sqlInstance,
						InitialCatalog = "master",
						IntegratedSecurity = true
					};

				using (var connection = new SqlConnection(stringBuilder.ConnectionString))
				{
					connection.Open();
					using (var command =
						new SqlCommand(string.Format(
							"BACKUP DATABASE [{0}] TO DISK = N'{1}\\{0}_{2}_{3:yyyy-MM-dd_HHmmss}.bak' WITH COPY_ONLY, NOFORMAT, NOINIT, NAME=N'{0}-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 5",
							DatabaseName,
							BackupLocation,
							BackupFileSuffix,
							DateTime.UtcNow),
						               connection))
					{
						command.ExecuteNonQuery();
					}
					connection.Close();
				}
			}
			catch (Exception ex)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.Error.WriteLine("Error during backup of database {0} on {1}: {2}", DatabaseName, sqlInstance, ex.Message);
				Console.ResetColor();
				return false;
			}
			Console.WriteLine("Completed backup of database {0} on {1}", DatabaseName, sqlInstance);
			return true;
		}
	}
}
