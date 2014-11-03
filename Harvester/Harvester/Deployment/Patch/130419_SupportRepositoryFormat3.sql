BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Changeset
	DROP CONSTRAINT FK_Changeset_issues
GO
ALTER TABLE Redmine.issues SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Changeset
	(
	Id int NOT NULL IDENTITY (1, 1),
	Code nvarchar(50) NOT NULL,
	Description nvarchar(500) NOT NULL,
	[User] nvarchar(100) NOT NULL,
	CreatedDateTime datetime NOT NULL,
	BranchCode nvarchar(50) NULL,
	Issue int NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Changeset SET (LOCK_ESCALATION = TABLE)
GO
SET IDENTITY_INSERT dbo.Tmp_Changeset ON
GO
IF EXISTS(SELECT * FROM dbo.Changeset)
	 EXEC('INSERT INTO dbo.Tmp_Changeset (Id, Code, Description, [User], CreatedDateTime, Issue)
		SELECT Id, Code, Description, [User], CreatedDateTime, Issue FROM dbo.Changeset WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_Changeset OFF
GO
ALTER TABLE dbo.RepositoryChangeset
	DROP CONSTRAINT FK_RepositoryChangeset_Changeset
GO
ALTER TABLE dbo.ChangesetFile
	DROP CONSTRAINT FK_ChangesetFile_Changeset
GO
ALTER TABLE dbo.BranchChangeset
	DROP CONSTRAINT FK_BranchChangeset_Changeset
GO
ALTER TABLE dbo.BookmarkChangeset
	DROP CONSTRAINT FK_BookmarkChangeset_Changeset
GO
DROP TABLE dbo.Changeset
GO
EXECUTE sp_rename N'dbo.Tmp_Changeset', N'Changeset', 'OBJECT' 
GO
ALTER TABLE dbo.Changeset ADD CONSTRAINT
	PK_Changeset PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX IX_Changeset_Code ON dbo.Changeset
	(
	Code
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_Changeset_CreatedDateTime ON dbo.Changeset
	(
	CreatedDateTime
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_Changeset_Issue ON dbo.Changeset
	(
	Issue
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.Changeset ADD CONSTRAINT
	FK_Changeset_issues FOREIGN KEY
	(
	Issue
	) REFERENCES Redmine.issues
	(
	id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.BookmarkChangeset ADD CONSTRAINT
	FK_BookmarkChangeset_Changeset FOREIGN KEY
	(
	Changeset
	) REFERENCES dbo.Changeset
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BookmarkChangeset SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.BranchChangeset ADD CONSTRAINT
	FK_BranchChangeset_Changeset FOREIGN KEY
	(
	Changeset
	) REFERENCES dbo.Changeset
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.BranchChangeset SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.ChangesetFile ADD CONSTRAINT
	FK_ChangesetFile_Changeset FOREIGN KEY
	(
	Changeset
	) REFERENCES dbo.Changeset
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.ChangesetFile SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.RepositoryChangeset ADD CONSTRAINT
	FK_RepositoryChangeset_Changeset FOREIGN KEY
	(
	Changeset
	) REFERENCES dbo.Changeset
	(
	Id
	) ON UPDATE  NO ACTION 
	 ON DELETE  NO ACTION 
	
GO
ALTER TABLE dbo.RepositoryChangeset SET (LOCK_ESCALATION = TABLE)
GO
COMMIT


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBookmark]
	@branch NVARCHAR(50),
	@feature NVARCHAR(50),
	@mercurialChangesetId NVARCHAR(50),
	@mercurialBookmark NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get repository id.
		DECLARE @repositoryId INT
		SELECT @repositoryId = Id
			FROM Repository
			WHERE Branch = @branch
			AND Feature = @feature

		-- Was repository not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

		-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
		DECLARE @changesetId INT
		SELECT @changesetId = Id
			FROM Changeset
			WHERE Code = @mercurialChangesetId

		-- Was SQL Server changeset not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

		-- Get bookmark id.
		DECLARE @bookmarkId INT
		SELECT @bookmarkId = Id
			FROM Bookmark
			WHERE Code = @mercurialBookmark
			AND Repository = @repositoryId

		-- Was bookmark not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert bookmark.
			INSERT INTO Bookmark
				(Code, [Description], Repository)
			VALUES
				(@mercurialBookmark, @mercurialBookmark, @repositoryId)
			-- Get bookmark id.
			SELECT @bookmarkId = Id
				FROM Bookmark
				WHERE Code = @mercurialBookmark
				AND Repository = @repositoryId
		END

		-- Does bookmark changeset map not exist?
		SELECT 1
			FROM BookmarkChangeset
			WHERE Bookmark = @bookmarkId
			AND Changeset = @changesetId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert bookmark changeset map.
			INSERT INTO BookmarkChangeset
				(Bookmark, Changeset)
			VALUES
				(@bookmarkId, @changesetId)
		END
	END TRY
	BEGIN CATCH
		RETURN -1
	END CATCH

	RETURN 0
END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBranch]
	@branch NVARCHAR(50),
	@feature NVARCHAR(50),
	@mercurialChangesetId NVARCHAR(50),
	@mercurialBranch NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get repository id.
		DECLARE @repositoryId INT
		SELECT @repositoryId = Id
			FROM Repository
			WHERE Branch = @branch
			AND Feature = @feature

		-- Was repository not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

		-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
		DECLARE @changesetId INT
		SELECT @changesetId = Id
			FROM Changeset
			WHERE Code = @mercurialChangesetId

		-- Was SQL Server changeset not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

		-- Get branch id.
		DECLARE @branchId INT
		SELECT @branchId = Id
			FROM Branch
			WHERE Code = @mercurialBranch
			AND Repository = @repositoryId

		-- Was branch not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert branch.
			INSERT INTO Branch
				(Code, [Description], Repository)
			VALUES
				(@mercurialBranch, @mercurialBranch, @repositoryId)
			-- Get branch id.
			SELECT @branchId = Id
				FROM Branch
				WHERE Code = @mercurialBranch
				AND Repository = @repositoryId
		END

		-- Does branch changeset map not exist?
		SELECT 1
			FROM BranchChangeset
			WHERE Branch = @branchId
			AND Changeset = @changesetId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert branch changeset map.
			INSERT INTO BranchChangeset
				(Branch, Changeset)
			VALUES
				(@branchId, @changesetId)
		END
	END TRY
	BEGIN CATCH
		RETURN -1
	END CATCH

	RETURN 0
END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddChangeset]
	@customerCode NVARCHAR(50),
	@repositoryURL NVARCHAR(200),
	@branch NVARCHAR(50),
	@feature NVARCHAR(50),
	@mercurialChangesetId NVARCHAR(50),
	@user NVARCHAR(100),
	@createdDateTime DATETIME,
	@summary NVARCHAR(500),
	@files NVARCHAR(MAX),
	@mercurialChangesetBranch NVARCHAR(50),
	@issueNumber NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get repository id.
		DECLARE @repositoryId INT
		SELECT @repositoryId = Id
			FROM Repository
			WHERE Branch = @branch
			AND Feature = @feature

		-- Was repository not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert repository.
			INSERT INTO Repository
				(Branch, Feature, URL, HarvestFlag)
			VALUES
				(@branch, @feature, @repositoryURL, 1)
			-- Get repository id.
			SELECT @repositoryId = Id
				FROM Repository
				WHERE Branch = @branch
				AND Feature = @feature
			-- Add customer repository map.
			EXEC dbo.AddCustomerRepositoryMap
				@customerCode = @customerCode,
				@branch = @branch,
				@feature = @feature
		END

		-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
		DECLARE @changesetId INT
		SELECT @changesetId = Id
			FROM Changeset
			WHERE Code = @mercurialChangesetId

		-- Was SQL Server changeset not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Get issue id.
			DECLARE @issueId INT
			SELECT @issueId = id
				FROM Redmine.issues
				WHERE id = @issueNumber

			-- Was issue not found?
			IF (@@ROWCOUNT = 0)
				-- Insert changeset.
				INSERT INTO Changeset
					(Code, [Description], [User], CreatedDateTime, BranchCode)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime, @mercurialChangesetBranch)
			ELSE
				-- Insert changeset.
				INSERT INTO Changeset
					(Code, [Description], [User], CreatedDateTime, BranchCode, Issue)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime, @mercurialChangesetBranch, @issueId)

			-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
			SELECT @changesetId = Id
				FROM Changeset
				WHERE Code = @mercurialChangesetId

			DECLARE @fileStartPos INT
			DECLARE @fileEndPos INT
			DECLARE @action CHAR(1)
			DECLARE @file NVARCHAR(400)

			DECLARE @slashPos INT
			DECLARE @fileLength INT
			DECLARE @fileName NVARCHAR(400)

			-- Loop through changeset file specifications.
			SET @fileStartPos = 1
			SET @fileEndPos = CHARINDEX('*^*', @files, @fileStartPos)
			WHILE @fileEndPos > 0
			BEGIN
				-- Extract file specification from list.
				SET @file = SUBSTRING(@files, @fileStartPos, @fileEndPos - @fileStartPos)
				SET @action = SUBSTRING(@file, 1, 1)
				SET @file = SUBSTRING(@file, 3, 400)

				-- Extract file name from file specification.
				SET @slashPos = PATINDEX('%[/\]%', REVERSE(@file))
				SET @fileLength = LEN(@file)
				IF @slashPos > 0
					SET @fileName = SUBSTRING(@file, @fileLength - @slashPos + 2, 400)
				ELSE
					SET @fileName = @file

				-- Insert changeset file.
				INSERT INTO ChangesetFile
					([Action], FileSpec, [FileName], Changeset)
				VALUES
					(@action, @file, @fileName, @changesetId)

				-- Move on to next file specification.
				SET @fileStartPos = @fileEndPos + 3
				SET @fileEndPos = CHARINDEX('*^*', @files, @fileStartPos)
			END
		END

		-- Does repository changeset map not exist?
		SELECT 1
			FROM RepositoryChangeset
			WHERE Repository = @repositoryId
			AND Changeset = @changesetId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert repository changeset map.
			INSERT INTO RepositoryChangeset
				(Repository, Changeset)
			VALUES
				(@repositoryId, @changesetId)
		END
	END TRY
	BEGIN CATCH
		RETURN -1
	END CATCH

	RETURN 0
END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[AddRepositoryEntry]
	@customerCode NVARCHAR(50),
	@repositoryURL NVARCHAR(200),
	@branch NVARCHAR(50),
	@feature NVARCHAR(50),
	@mercurialChangesetId NVARCHAR(50),
	@user NVARCHAR(100),
	@createdDateTime DATETIME,
	@summary NVARCHAR(500),
	@files NVARCHAR(MAX),
	@branches NVARCHAR(MAX),
	@bookmarks NVARCHAR(MAX),
	@mercurialChangesetBranch NVARCHAR(50),
	@issueNumber NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get repository id.
		DECLARE @repositoryId INT
		SELECT @repositoryId = Id
			FROM Repository
			WHERE Branch = @branch
			AND Feature = @feature

		-- Was repository not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert repository.
			INSERT INTO Repository
				(Branch, Feature, URL, HarvestFlag)
			VALUES
				(@branch, @feature, @repositoryURL, 1)
			-- Get repository id.
			SELECT @repositoryId = Id
				FROM Repository
				WHERE Branch = @branch
				AND Feature = @feature
			-- Add customer repository map.
			EXEC dbo.AddCustomerRepositoryMap
				@customerCode = @customerCode,
				@branch = @branch,
				@feature = @feature
		END

		-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
		DECLARE @changesetId INT
		SELECT @changesetId = Id
			FROM Changeset
			WHERE Code = @mercurialChangesetId

		-- Was SQL Server changeset not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Get issue id.
			DECLARE @issueId INT
			SELECT @issueId = id
				FROM Redmine.issues
				WHERE id = @issueNumber

			-- Was issue not found?
			IF (@@ROWCOUNT = 0)
				-- Insert changeset.
				INSERT INTO Changeset
					(Code, [Description], [User], CreatedDateTime, BranchCode)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime, @mercurialChangesetBranch)
			ELSE
				-- Insert changeset.
				INSERT INTO Changeset
					(Code, [Description], [User], CreatedDateTime, BranchCode, Issue)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime, @mercurialChangesetBranch, @issueId)

			-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
			SELECT @changesetId = Id
				FROM Changeset
				WHERE Code = @mercurialChangesetId

			DECLARE @fileStartPos INT
			DECLARE @fileEndPos INT
			DECLARE @action CHAR(1)
			DECLARE @file NVARCHAR(400)

			DECLARE @slashPos INT
			DECLARE @fileLength INT
			DECLARE @fileName NVARCHAR(400)

			-- Loop through changeset file specifications.
			SET @fileStartPos = 1
			SET @fileEndPos = CHARINDEX('*^*', @files, @fileStartPos)
			WHILE @fileEndPos > 0
			BEGIN
				-- Extract file specification from list.
				SET @file = SUBSTRING(@files, @fileStartPos, @fileEndPos - @fileStartPos)
				SET @action = SUBSTRING(@file, 1, 1)
				SET @file = SUBSTRING(@file, 3, 400)

				-- Extract file name from file specification.
				SET @slashPos = PATINDEX('%[/\]%', REVERSE(@file))
				SET @fileLength = LEN(@file)
				IF @slashPos > 0
					SET @fileName = SUBSTRING(@file, @fileLength - @slashPos + 2, 400)
				ELSE
					SET @fileName = @file

				-- Insert changeset file.
				INSERT INTO ChangesetFile
					([Action], FileSpec, [FileName], Changeset)
				VALUES
					(@action, @file, @fileName, @changesetId)

				-- Move on to next file specification.
				SET @fileStartPos = @fileEndPos + 3
				SET @fileEndPos = CHARINDEX('*^*', @files, @fileStartPos)
			END
		END

		-- Does repository changeset map not exist?
		SELECT 1
			FROM RepositoryChangeset
			WHERE Repository = @repositoryId
			AND Changeset = @changesetId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert repository changeset map.
			INSERT INTO RepositoryChangeset
				(Repository, Changeset)
			VALUES
				(@repositoryId, @changesetId)
		END

		DECLARE @branchStartPos INT
		DECLARE @branchEndPos INT
		DECLARE @mercurialBranch NVARCHAR(400)

		-- Loop through Mercurial branches (as opposed to j6 branches).
		SET @branchStartPos = 1
		SET @branchEndPos = CHARINDEX('*^*', @branches, @branchStartPos)
		WHILE @branchEndPos > 0
		BEGIN
			-- Extract branch from list.
			SET @mercurialBranch = SUBSTRING(@branches, @branchStartPos, @branchEndPos - @branchStartPos)

			-- Get branch id.
			DECLARE @branchId INT
			SELECT @branchId = Id
				FROM Branch
				WHERE Code = @mercurialBranch
				AND Repository = @repositoryId

			-- Was branch not found?
			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Insert branch.
				INSERT INTO Branch
					(Code, [Description], Repository)
				VALUES
					(@mercurialBranch, @mercurialBranch, @repositoryId)
				-- Get branch id.
				SELECT @branchId = Id
					FROM Branch
					WHERE Code = @mercurialBranch
					AND Repository = @repositoryId
			END

			-- Does branch changeset map not exist?
			SELECT 1
				FROM BranchChangeset
				WHERE Branch = @branchId
				AND Changeset = @changesetId
			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Insert branch changeset map.
				INSERT INTO BranchChangeset
					(Branch, Changeset)
				VALUES
					(@branchId, @changesetId)
			END

			-- Move on to next branch.
			SET @branchStartPos = @branchEndPos + 3
			SET @branchEndPos = CHARINDEX('*^*', @branches, @branchStartPos)
		END

		DECLARE @bookmarkStartPos INT
		DECLARE @bookmarkEndPos INT
		DECLARE @bookmark NVARCHAR(400)

		-- Loop through bookmarks.
		SET @bookmarkStartPos = 1
		SET @bookmarkEndPos = CHARINDEX('*^*', @bookmarks, @bookmarkStartPos)
		WHILE @bookmarkEndPos > 0
		BEGIN
			-- Extract bookmark from list.
			SET @bookmark = SUBSTRING(@bookmarks, @bookmarkStartPos, @bookmarkEndPos - @bookmarkStartPos)

			-- Get bookmark id.
			DECLARE @bookmarkId INT
			SELECT @bookmarkId = Id
				FROM Bookmark
				WHERE Code = @bookmark
				AND Repository = @repositoryId

			-- Was bookmark not found?
			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Insert bookmark.
				INSERT INTO Bookmark
					(Code, [Description], Repository)
				VALUES
					(@bookmark, @bookmark, @repositoryId)
				-- Get bookmark id.
				SELECT @bookmarkId = Id
					FROM Bookmark
					WHERE Code = @bookmark
					AND Repository = @repositoryId
			END

			-- Does bookmark changeset map not exist?
			SELECT 1
				FROM BookmarkChangeset
				WHERE Bookmark = @bookmarkId
				AND Changeset = @changesetId
			IF (@@ROWCOUNT = 0)
			BEGIN
				-- Insert bookmark changeset map.
				INSERT INTO BookmarkChangeset
					(Bookmark, Changeset)
				VALUES
					(@bookmarkId, @changesetId)
			END

			-- Move on to next bookmark.
			SET @bookmarkStartPos = @bookmarkEndPos + 3
			SET @bookmarkEndPos = CHARINDEX('*^*', @bookmarks, @bookmarkStartPos)
		END
	END TRY
	BEGIN CATCH
		RETURN -1
	END CATCH

	RETURN 0
END
GO
