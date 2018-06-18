using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace DeploymentMsBuildTasks
{
	public class DatabaseRestore : Task
	{
		[Required]
		public string DatabaseName { get; set; }

		[Required]
		public string DatabaseServer { get; set; }

		[Required]
		public string RestoreLocation { get; set; }

		public string SqlInstance { get; set; }

		[Required]
		public string BackupFileName { get; set; }

		public override bool Execute()
		{
			var sqlInstance = string.IsNullOrWhiteSpace(SqlInstance)
				                   ? DatabaseServer
				                   : string.Format("{0}\\{1}", DatabaseServer, SqlInstance);
			Console.WriteLine("Restoring database {0} on {1}", DatabaseName, sqlInstance);
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

					using (var setSingleUser = new SqlCommand(string.Format("ALTER DATABASE [{0}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE", DatabaseName), connection))
						setSingleUser.ExecuteNonQuery();

					using (var restoreDb =
						new SqlCommand(
							string.Format("RESTORE DATABASE [{0}] FROM DISK = N'{1}\\{2}.bak' WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 5",
							              DatabaseName,
							              RestoreLocation,
							              BackupFileName),
							connection))
					{
						restoreDb.ExecuteNonQuery();
					}
					
					using (var setMultiUser = new SqlCommand(string.Format("ALTER DATABASE [{0}] SET MULTI_USER", DatabaseName), connection))
						setMultiUser.ExecuteNonQuery();
					
					
					connection.Close();
				}
			}
			catch (Exception ex)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.Error.WriteLine("Error during restore of database {0} on {1}: {2}", DatabaseName, sqlInstance, ex.Message);
				Console.ResetColor();
				return false;
			}
			Console.WriteLine("Completed restore of database {0} on {1}", DatabaseName, sqlInstance);
			return true;
		}
	}
}
