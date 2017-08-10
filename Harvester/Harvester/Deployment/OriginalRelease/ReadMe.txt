Configure a Linked Server called REDMINE that connects to the Redmine MySQL database.

Create an empty database.

Run the 01CreateReplicationStoredProcedures.sql script on the database.

Run the UpdateTables stored procedure on the database.

Run the 02CreateReleaseNotesObjects.sql script on the database.

Run the 03AdjustRedmineObjects.sql script on the database.

Run the 04CreateOldReportObjects.sql script on the database.

Run the 05LoadCalendarDayTable.sql script on the database.

Run the 06LoadConfigurationTables.sql script on the database.

Configure a SQL Server Agent job that calls the UpdateTables stored procedure regularly.

Configure Customer, CustomerRepository and Repository tables and maintain these tables over time.

Schedule Harvester to run regularly.
