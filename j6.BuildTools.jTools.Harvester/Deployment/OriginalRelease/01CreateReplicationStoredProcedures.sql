CREATE SCHEMA [Redmine] AUTHORIZATION [dbo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateRowsInTableWithoutUpdatedField]
	@tableName NVARCHAR(128),
	@deleteFlag BIT
AS
BEGIN
	DECLARE @sql NVARCHAR(4000)

	DECLARE @tableNameNew NVARCHAR(128)
	SET @tableNameNew = @tableName + '_temp'

	-- Copy table from MySQL to temporary SQL Server table.
	BEGIN TRY
		SET @sql = 'SELECT * INTO Redmine.' + @tableNameNew + ' FROM OPENQUERY(REDMINE, ''SELECT * FROM ' + @tableName + ''')'
		EXEC (@sql)
		SET @sql = 'ALTER TABLE Redmine.' + @tableNameNew + ' ALTER COLUMN id INT NOT NULL'
		EXEC (@sql)
		SET @sql = 'ALTER TABLE Redmine.' + @tableNameNew + ' ADD CONSTRAINT PK_' + @tableNameNew + ' PRIMARY KEY (id)'
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	-- Get ordinal position for last field.
	DECLARE @maxOrdinalPos INT
	SELECT @maxOrdinalPos = MAX(ORDINAL_POSITION)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_SCHEMA = 'Redmine'
		AND TABLE_NAME = @tableName

	DECLARE fieldList CURSOR LOCAL FOR
		SELECT COLUMN_NAME, ORDINAL_POSITION
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_SCHEMA = 'Redmine'
			AND TABLE_NAME = @tableName
			AND COLUMN_NAME <> 'id'
			ORDER BY ORDINAL_POSITION

	DECLARE @fieldName NVARCHAR(128)
	DECLARE @ordinalPos INT

	-- Build update query.
	SET @sql = 'UPDATE Redmine.' + @tableName + ' SET' + CHAR(13)
	OPEN fieldList
	FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = @sql + CHAR(9) + @tableName + '.' + @fieldName + ' = ' + @tableNameNew + '.' + @fieldName + CASE WHEN @ordinalPos < @maxOrdinalPos THEN ',' ELSE '' END + CHAR(13)
		FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	END
	CLOSE fieldList
	SET @sql = @sql + 'FROM Redmine.' + @tableNameNew + CHAR(13)
	SET @sql = @sql + 'WHERE (' + CHAR(13)
	OPEN fieldList
	FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = @sql + CHAR(9) + 'CASE WHEN ' + @tableName + '.' + @fieldName + ' IS NULL THEN ''NULL'' ELSE CONVERT(NVARCHAR(4000), ' + @tableName + '.' + @fieldName + ') END <> CASE WHEN ' + @tableNameNew + '.' + @fieldName + ' IS NULL THEN ''NULL'' ELSE CONVERT(NVARCHAR(4000), ' + @tableNameNew + '.' + @fieldName + ') END' + CASE WHEN @ordinalPos < @maxOrdinalPos THEN ' OR' ELSE '' END + CHAR(13)
		FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	END
	CLOSE fieldList
	DEALLOCATE fieldList
	SET @sql = @sql + ')' + CHAR(13)
	SET @sql = @sql + 'AND ' + @tableName + '.id = ' + @tableNameNew + '.id'

	-- Update fields for records that have been updated.
	BEGIN TRY
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	IF @deleteFlag = 1
	BEGIN
		-- Remove deleted rows from SQL Server.
		BEGIN TRY
			SET @sql = 'DELETE FROM Redmine.' + @tableName + ' WHERE id NOT IN (SELECT id FROM Redmine.' + @tableNameNew + ')'
			EXEC (@sql)
		END TRY
		BEGIN CATCH
			SELECT
				ERROR_NUMBER() AS ErrorNumber,
				ERROR_MESSAGE() AS ErrorMessage;
			RETURN -1
		END CATCH
	END

	-- Drop temporary table from SQL Server.
	BEGIN TRY
		SET @sql = 'DROP TABLE Redmine.' + @tableNameNew
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	RETURN 0
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateRowsInTable]
	@tableName NVARCHAR(128),
	@deleteFlag BIT
AS
BEGIN
	DECLARE @sql NVARCHAR(4000)

	DECLARE @tableNameNew NVARCHAR(128)
	SET @tableNameNew = @tableName + '_temp'

	-- Copy table from MySQL to temporary SQL Server table.
	BEGIN TRY
		SET @sql = 'SELECT * INTO Redmine.' + @tableNameNew + ' FROM OPENQUERY(REDMINE, ''SELECT * FROM ' + @tableName + ''')'
		EXEC (@sql)
		SET @sql = 'ALTER TABLE Redmine.' + @tableNameNew + ' ALTER COLUMN id INT NOT NULL'
		EXEC (@sql)
		SET @sql = 'ALTER TABLE Redmine.' + @tableNameNew + ' ADD CONSTRAINT PK_' + @tableNameNew + ' PRIMARY KEY (id)'
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	-- Get ordinal position for last field.
	DECLARE @maxOrdinalPos INT
	SELECT @maxOrdinalPos = MAX(ORDINAL_POSITION)
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_SCHEMA = 'Redmine'
		AND TABLE_NAME = @tableName

	DECLARE fieldList CURSOR LOCAL FOR
		SELECT COLUMN_NAME, ORDINAL_POSITION
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_SCHEMA = 'Redmine'
			AND TABLE_NAME = @tableName
			AND COLUMN_NAME <> 'id'
			ORDER BY ORDINAL_POSITION

	DECLARE @fieldName NVARCHAR(128)
	DECLARE @ordinalPos INT

	-- Build update query.
	SET @sql = 'UPDATE Redmine.' + @tableName + ' SET' + CHAR(13)
	OPEN fieldList
	FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = @sql + CHAR(9) + @tableName + '.' + @fieldName + ' = ' + @tableNameNew + '.' + @fieldName + CASE WHEN @ordinalPos < @maxOrdinalPos THEN ',' ELSE '' END + CHAR(13)
		FETCH NEXT FROM fieldList INTO @fieldName, @ordinalPos
	END
	CLOSE fieldList
	DEALLOCATE fieldList
	SET @sql = @sql + 'FROM Redmine.' + @tableNameNew + CHAR(13)
	SET @sql = @sql + 'WHERE ' + @tableName + '.id IN (' + CHAR(13)
	SET @sql = @sql + CHAR(9) + 'SELECT ' + @tableNameNew + '.id' + CHAR(13)
	SET @sql = @sql + CHAR(9) + 'FROM Redmine.' + @tableNameNew + CHAR(13)
	SET @sql = @sql + CHAR(9) + 'INNER JOIN Redmine.' + @tableName + ' ON ' + @tableNameNew + '.id = ' + @tableName + '.id' + CHAR(13)
	SET @sql = @sql + CHAR(9) + 'WHERE ' + @tableNameNew + '.updated_on > ' + @tableName + '.updated_on' + CHAR(13)
	SET @sql = @sql + ')' + CHAR(13)
	SET @sql = @sql + 'AND ' + @tableName + '.id = ' + @tableNameNew + '.id'

	-- Update fields for records that have been updated.
	BEGIN TRY
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	IF @deleteFlag = 1
	BEGIN
		-- Remove deleted rows from SQL Server.
		BEGIN TRY
			SET @sql = 'DELETE FROM Redmine.' + @tableName + ' WHERE id NOT IN (SELECT id FROM Redmine.' + @tableNameNew + ')'
			EXEC (@sql)
		END TRY
		BEGIN CATCH
			SELECT
				ERROR_NUMBER() AS ErrorNumber,
				ERROR_MESSAGE() AS ErrorMessage;
			RETURN -1
		END CATCH
	END

	-- Drop temporary table from SQL Server.
	BEGIN TRY
		SET @sql = 'DROP TABLE Redmine.' + @tableNameNew
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	RETURN 0
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoadTableList]
AS
BEGIN
	-- Load list of tables to update.
	INSERT INTO #tableList VALUES (1000, 'issue_statuses', NULL)
	INSERT INTO #tableList VALUES (1010, 'trackers', NULL)
	INSERT INTO #tableList VALUES (1020, 'projects', NULL)
	INSERT INTO #tableList VALUES (1030, 'users', NULL)
	INSERT INTO #tableList VALUES (1040, 'enumerations', NULL)
	INSERT INTO #tableList VALUES (1050, 'issue_categories', NULL)
	INSERT INTO #tableList VALUES (1060, 'versions', NULL)
	INSERT INTO #tableList VALUES (1070, 'issues', NULL)
	INSERT INTO #tableList VALUES (1080, 'custom_fields', 'type = ''''IssueCustomField''''')
	INSERT INTO #tableList VALUES (1090, 'custom_values', 'customized_type = ''''Issue''''')
	INSERT INTO #tableList VALUES (1100, 'journals', 'journalized_type = ''''Issue'''' and id > 6') -- 'id > 6' to compensate for bad data.
	INSERT INTO #tableList VALUES (1110, 'journal_details', 'journal_id > 6') -- 'journal_id > 6' to compensate for bad data.
	INSERT INTO #tableList VALUES (1120, 'watchers', 'watchable_type = ''''Issue''''')
	INSERT INTO #tableList VALUES (1130, 'issue_relations', NULL)
	INSERT INTO #tableList VALUES (1140, 'time_entries', NULL)
	RETURN 0
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddRowsToTable]
	@tableName NVARCHAR(128),
	@whereClause NVARCHAR(4000)
AS
BEGIN
	DECLARE @sql NVARCHAR(4000)

	-- Set default value for where clause if not specified.
	IF (@whereClause IS NULL) SET @whereClause = '1 = 1'

	-- Does table not exist?
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE (TABLE_SCHEMA = 'Redmine') AND (TABLE_NAME = @tableName))
	BEGIN
		-- Create table.
		BEGIN TRY
			SET @sql = 'SELECT * INTO Redmine.' + @tableName + ' FROM OPENQUERY(REDMINE, ''SELECT * FROM ' + @tableName + ' WHERE (1 = 0)'')'
			EXEC (@sql)
			SET @sql = 'ALTER TABLE Redmine.' + @tableName + ' ALTER COLUMN id INT NOT NULL'
			EXEC (@sql)
			SET @sql = 'ALTER TABLE Redmine.' + @tableName + ' ADD CONSTRAINT PK_' + @tableName + ' PRIMARY KEY (id)'
			EXEC (@sql)
		END TRY
		BEGIN CATCH
			SELECT
				ERROR_NUMBER() AS ErrorNumber,
				ERROR_MESSAGE() AS ErrorMessage;
			RETURN -1
		END CATCH
	END

	CREATE TABLE #result (MaximumId INT)
	DECLARE @maximumId INT

	-- Get maximum id value for SQL Server table.
	BEGIN TRY
		SET @sql = 'INSERT INTO #result SELECT MAX(id) FROM Redmine.' + @tableName
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH
	SELECT @maximumId = MaximumId FROM #result
	IF @maximumId IS NULL SET @maximumId = 0
	DROP TABLE #result

	-- Copy new rows from MySQL to SQL Server.
	BEGIN TRY
		SET @sql = 'INSERT INTO Redmine.' + @tableName + ' SELECT * FROM OPENQUERY(REDMINE, ''SELECT * FROM ' + @tableName + ' WHERE (id > ' + CONVERT(NVARCHAR, @maximumId) + ') AND (' + @whereClause + ')'')'
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage;
		RETURN -1
	END CATCH

	RETURN 0
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTables]
AS
BEGIN
	-- Create list of tables to update.
	CREATE TABLE #tableList (SortOrder INT, TableName NVARCHAR(128), WhereClause NVARCHAR(4000))
	EXEC LoadTableList

	DECLARE tableList CURSOR LOCAL FOR
		SELECT TableName, WhereClause FROM #tableList ORDER BY SortOrder

	DECLARE @tableName NVARCHAR(128)
	DECLARE @whereClause NVARCHAR(4000)

	-- Loop through tables.
	OPEN tableList
	FETCH NEXT FROM tableList INTO @tableName, @whereClause
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Add rows from MySQL to SQL Server.
		EXEC AddRowsToTable @tableName, @whereClause
		FETCH NEXT FROM tableList INTO @tableName, @whereClause
	END
	CLOSE tableList
	DEALLOCATE tableList
	DROP TABLE #tableList

	-- Get current list of custom values.
	SELECT * INTO #currentCustomValues FROM OPENQUERY(REDMINE, 'SELECT * FROM custom_values')
	ALTER TABLE #currentCustomValues ALTER COLUMN id INT NOT NULL
	ALTER TABLE #currentCustomValues ADD CONSTRAINT PK_CurrentCustomValues PRIMARY KEY (id)

	-- Update custom value(s) for issues that have been updated.
	UPDATE Redmine.custom_values
	SET custom_values.value = #currentCustomValues.value
	FROM #currentCustomValues
	WHERE custom_values.id = #currentCustomValues.id
	AND CONVERT(NVARCHAR(4000), custom_values.value) <> CONVERT(NVARCHAR(4000), #currentCustomValues.value)

	-- Delete custom value(s) that have been deleted from MySQL.
	DELETE FROM Redmine.custom_values
	WHERE id NOT IN (
		SELECT id
		FROM #currentCustomValues
	)

	DROP TABLE #currentCustomValues

	-- Update fields for records that have been updated.
	-- (These tables must have an updated_on field.)
	EXEC UpdateRowsInTable 'projects', 0
	EXEC UpdateRowsInTable 'users', 0
	EXEC UpdateRowsInTable 'versions', 0
	EXEC UpdateRowsInTable 'issues', 0
	EXEC UpdateRowsInTable 'time_entries', 1

	-- Update fields for records that have been updated.
	-- (These tables do not have an updated_on field.)
	EXEC UpdateRowsInTableWithoutUpdatedField 'issue_statuses', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'trackers', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'enumerations', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'issue_categories', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'journals', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'journal_details', 0
	EXEC UpdateRowsInTableWithoutUpdatedField 'watchers', 1
	EXEC UpdateRowsInTableWithoutUpdatedField 'issue_relations', 1

	RETURN 0
END
GO
