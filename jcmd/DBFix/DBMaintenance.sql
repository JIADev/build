-- Sets Smpl Rcvry Mode, enables CLR, trunc logs, shrinks
------------------------------------------------------------------------------------
-- Default DB configuration
------------------------------------------------------------------------------------
DECLARE @dbconfiguresql NVARCHAR(2000)

-- Verify configured for CLR procedures --
IF NOT EXISTS(SELECT null FROM sys.configurations WHERE name = 'clr enabled' AND Value = 1)
BEGIN
	EXEC sp_configure 'clr enabled', 1
	RECONFIGURE
END

/* Using the sql proj to set the db options would force a single recovery mode with each deployment.
	* Since we use SIMPLE for Dev and QA, but FULL for Production (and some other customer environments),
	* the actual datbase options required must be specified here
	*/
-- Verify database is set for snapshot isolation and read committed snapshot
IF NOT EXISTS(SELECT null FROM sys.databases WHERE name = db_name() AND snapshot_isolation_state = 1)
BEGIN
	SELECT @dbconfiguresql = N'ALTER DATABASE [' + db_name() + '] SET ALLOW_SNAPSHOT_ISOLATION ON'
	EXEC sp_executesql @dbconfiguresql
END

IF NOT EXISTS(SELECT null FROM sys.databases WHERE name = db_name() AND is_read_committed_snapshot_on = 1)
BEGIN
	SELECT @dbconfiguresql = N'ALTER DATABASE [' + db_name() + '] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE'
	EXEC sp_executesql @dbconfiguresql
END
GO

------------------------------------------------------------------------------------
-- Set DB to simple recovery (no logs)
------------------------------------------------------------------------------------
PRINT 'Setting DB to simple recovery mode - NO LOGS!'
declare @db nvarchar(1000)
select @db = db_name()
EXEC('Alter database ['+@db+'] SET Recovery simple')
GO

------------------------------------------------------------------------------------
-- truncate the log to only the last 10,000 messages
------------------------------------------------------------------------------------
if object_id('dbo.RunMessage') is not null
begin
	PRINT 'Truncating dbo.RunMessage'
	delete from dbo.RunMessage where id < (select max(id)-9999 from dbo.RunMessage)
end

declare @truncatesql nvarchar(max)

set @truncatesql = ''
select @truncatesql=@truncatesql+'delete from ['+s.name+'].['+t.name+']'+CHAR(13)+CHAR(10) from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name  like 'Run[_]%[_]Audit'
select @truncatesql=@truncatesql+'delete from ['+s.name+'].['+t.name+']'+CHAR(13)+CHAR(10) from sys.tables t join sys.schemas s on t.schema_id = s.schema_id where t.name  like '%[_]Audit' and t.name not like 'Run[_]%[_]Audit'
Exec(@truncatesql)
GO

------------------------------------------
-- Truncate the DB logs
------------------------------------------
declare @logname nvarchar(1000)
SELECT @logname = [name] FROM [sys].[database_files]  where [type] = 1
EXEC('DBCC SHRINKFILE('''+@logname+''', 1)')
GO


------------------------------------------
-- Shrink database
------------------------------------------
declare @db nvarchar(1000)
select @db = db_name()
EXEC('dbcc shrinkdatabase('''+@db+''')')
GO
