SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Repository](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Branch] [nvarchar](50) NOT NULL,
	[Feature] [nvarchar](50) NOT NULL,
	[URL] [nvarchar](500) NULL,
	[HarvestFlag] [bit] NULL,
 CONSTRAINT [PK_Repository] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[URL] [nvarchar](500) NULL,
	[HarvestFlag] [bit] NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerRepository](
	[Customer] [int] NOT NULL,
	[Repository] [int] NOT NULL,
 CONSTRAINT [PK_CustomerRepository] PRIMARY KEY CLUSTERED 
(
	[Customer] ASC,
	[Repository] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bookmark](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[Repository] [int] NOT NULL,
 CONSTRAINT [PK_Bookmark] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Branch](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[Repository] [int] NOT NULL,
 CONSTRAINT [PK_Branch] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Changeset](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](500) NOT NULL,
	[User] [nvarchar](100) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[Issue] [int] NULL,
 CONSTRAINT [PK_Changeset] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Changeset_Code] ON [dbo].[Changeset] 
(
	[Code] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Changeset_CreatedDateTime] ON [dbo].[Changeset] 
(
	[CreatedDateTime] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Changeset_Issue] ON [dbo].[Changeset] 
(
	[Issue] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RepositoryChangeset](
	[Repository] [int] NOT NULL,
	[Changeset] [int] NOT NULL,
 CONSTRAINT [PK_RepositoryChangeset] PRIMARY KEY CLUSTERED 
(
	[Repository] ASC,
	[Changeset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ChangesetFile](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Action] [char](1) NOT NULL,
	[FileSpec] [nvarchar](400) NOT NULL,
	[FileName] [nvarchar](400) NOT NULL,
	[Changeset] [int] NOT NULL,
 CONSTRAINT [PK_ChangesetFile] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
CREATE NONCLUSTERED INDEX [IX_ChangesetFile_Changeset] ON [dbo].[ChangesetFile] 
(
	[Changeset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ChangesetFile_FileName] ON [dbo].[ChangesetFile] 
(
	[FileName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ChangesetFile_FileSpec] ON [dbo].[ChangesetFile] 
(
	[FileSpec] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BranchChangeset](
	[Branch] [int] NOT NULL,
	[Changeset] [int] NOT NULL,
 CONSTRAINT [PK_BranchChangeset] PRIMARY KEY CLUSTERED 
(
	[Branch] ASC,
	[Changeset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookmarkChangeset](
	[Bookmark] [int] NOT NULL,
	[Changeset] [int] NOT NULL,
 CONSTRAINT [PK_BookmarkChangeset] PRIMARY KEY CLUSTERED 
(
	[Bookmark] ASC,
	[Changeset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Repository] ADD  CONSTRAINT [DF_Repository_HarvestFlag]  DEFAULT ((1)) FOR [HarvestFlag]
GO
ALTER TABLE [dbo].[Bookmark]  WITH CHECK ADD  CONSTRAINT [FK_Bookmark_Repository] FOREIGN KEY([Repository])
REFERENCES [dbo].[Repository] ([Id])
GO
ALTER TABLE [dbo].[Bookmark] CHECK CONSTRAINT [FK_Bookmark_Repository]
GO
ALTER TABLE [dbo].[BookmarkChangeset]  WITH CHECK ADD  CONSTRAINT [FK_BookmarkChangeset_Bookmark] FOREIGN KEY([Bookmark])
REFERENCES [dbo].[Bookmark] ([Id])
GO
ALTER TABLE [dbo].[BookmarkChangeset] CHECK CONSTRAINT [FK_BookmarkChangeset_Bookmark]
GO
ALTER TABLE [dbo].[BookmarkChangeset]  WITH CHECK ADD  CONSTRAINT [FK_BookmarkChangeset_Changeset] FOREIGN KEY([Changeset])
REFERENCES [dbo].[Changeset] ([Id])
GO
ALTER TABLE [dbo].[BookmarkChangeset] CHECK CONSTRAINT [FK_BookmarkChangeset_Changeset]
GO
ALTER TABLE [dbo].[Branch]  WITH CHECK ADD  CONSTRAINT [FK_Branch_Repository] FOREIGN KEY([Repository])
REFERENCES [dbo].[Repository] ([Id])
GO
ALTER TABLE [dbo].[Branch] CHECK CONSTRAINT [FK_Branch_Repository]
GO
ALTER TABLE [dbo].[BranchChangeset]  WITH CHECK ADD  CONSTRAINT [FK_BranchChangeset_Branch] FOREIGN KEY([Branch])
REFERENCES [dbo].[Branch] ([Id])
GO
ALTER TABLE [dbo].[BranchChangeset] CHECK CONSTRAINT [FK_BranchChangeset_Branch]
GO
ALTER TABLE [dbo].[BranchChangeset]  WITH CHECK ADD  CONSTRAINT [FK_BranchChangeset_Changeset] FOREIGN KEY([Changeset])
REFERENCES [dbo].[Changeset] ([Id])
GO
ALTER TABLE [dbo].[BranchChangeset] CHECK CONSTRAINT [FK_BranchChangeset_Changeset]
GO
ALTER TABLE [dbo].[Changeset]  WITH CHECK ADD  CONSTRAINT [FK_Changeset_issues] FOREIGN KEY([Issue])
REFERENCES [Redmine].[issues] ([id])
GO
ALTER TABLE [dbo].[Changeset] CHECK CONSTRAINT [FK_Changeset_issues]
GO
ALTER TABLE [dbo].[ChangesetFile]  WITH CHECK ADD  CONSTRAINT [FK_ChangesetFile_Changeset] FOREIGN KEY([Changeset])
REFERENCES [dbo].[Changeset] ([Id])
GO
ALTER TABLE [dbo].[ChangesetFile] CHECK CONSTRAINT [FK_ChangesetFile_Changeset]
GO
ALTER TABLE [dbo].[CustomerRepository]  WITH CHECK ADD  CONSTRAINT [FK_CustomerRepository_Customer] FOREIGN KEY([Customer])
REFERENCES [dbo].[Customer] ([Id])
GO
ALTER TABLE [dbo].[CustomerRepository] CHECK CONSTRAINT [FK_CustomerRepository_Customer]
GO
ALTER TABLE [dbo].[CustomerRepository]  WITH CHECK ADD  CONSTRAINT [FK_CustomerRepository_Repository] FOREIGN KEY([Repository])
REFERENCES [dbo].[Repository] ([Id])
GO
ALTER TABLE [dbo].[CustomerRepository] CHECK CONSTRAINT [FK_CustomerRepository_Repository]
GO
ALTER TABLE [dbo].[RepositoryChangeset]  WITH CHECK ADD  CONSTRAINT [FK_RepositoryChangeset_Changeset] FOREIGN KEY([Changeset])
REFERENCES [dbo].[Changeset] ([Id])
GO
ALTER TABLE [dbo].[RepositoryChangeset] CHECK CONSTRAINT [FK_RepositoryChangeset_Changeset]
GO
ALTER TABLE [dbo].[RepositoryChangeset]  WITH CHECK ADD  CONSTRAINT [FK_RepositoryChangeset_Repository] FOREIGN KEY([Repository])
REFERENCES [dbo].[Repository] ([Id])
GO
ALTER TABLE [dbo].[RepositoryChangeset] CHECK CONSTRAINT [FK_RepositoryChangeset_Repository]
GO
ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_HarvestFlag]  DEFAULT ((1)) FOR [HarvestFlag]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetReleaseNotes]
	@customer NVARCHAR(50),
	@fromBranch NVARCHAR(50),
	@toBranch NVARCHAR(50),
	@featureList NVARCHAR(4000),
	@branch NVARCHAR(50),
	@bookmark NVARCHAR(50),
	@audienceLevel NVARCHAR(50),
	@displayOrder NVARCHAR(50)
AS
BEGIN
	DECLARE @releaseTitleId INT
	SELECT @releaseTitleId = id FROM Redmine.custom_fields WHERE name = 'Release Title'

	DECLARE @releaseDescriptionId INT
	SELECT @releaseDescriptionId = id FROM Redmine.custom_fields WHERE name = 'Release Description'

	DECLARE @audienceLevelId INT
	SELECT @audienceLevelId = id FROM Redmine.custom_fields WHERE name = 'Audience Level'

	-- Add trailing comma for compare.
	SET @featureList = @featureList + ','

	-- Audience level Internal can see Internal and External.
	IF @audienceLevel = 'Internal' SET @audienceLevel = 'Internal,External'

	IF @displayOrder = 'Feature'
		-- Get release notes feature first.
		SELECT DISTINCT
			Repository.Branch,
			Repository.Feature,
			issues.id AS Issue,
			'http://jia-lnx1.jenkon.com/redmine/issues/' + CONVERT(NVARCHAR(50), issues.id) AS IssueURL,
			CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END AS Title,
			CONVERT(NVARCHAR(4000), rd.value) AS [Description]
		FROM Customer
		INNER JOIN CustomerRepository ON Customer.Id = CustomerRepository.Customer
		INNER JOIN Repository ON CustomerRepository.Repository = Repository.Id
		INNER JOIN RepositoryChangeset ON Repository.Id = RepositoryChangeset.Repository
		INNER JOIN Changeset ON RepositoryChangeset.Changeset = Changeset.Id
		INNER JOIN Redmine.issues ON Changeset.Issue = issues.id
		LEFT JOIN Redmine.custom_values rt ON (Changeset.Issue = rt.customized_id AND rt.custom_field_id = @releaseTitleId)
		LEFT JOIN Redmine.custom_values rd ON (Changeset.Issue = rd.customized_id AND rd.custom_field_id = @releaseDescriptionId)
		LEFT JOIN Redmine.custom_values al ON (Changeset.Issue = al.customized_id AND al.custom_field_id = @audienceLevelId)
		LEFT JOIN BookmarkChangeset ON Changeset.Id = BookmarkChangeset.Changeset
		LEFT JOIN Bookmark ON BookmarkChangeset.Bookmark = Bookmark.Id
		LEFT JOIN BranchChangeset ON Changeset.Id = BranchChangeset.Changeset
		LEFT JOIN Branch ON BranchChangeset.Branch = Branch.Id
		WHERE Customer.Code = @customer
		AND Repository.Branch >= @fromBranch
		AND Repository.Branch <= @toBranch
		AND CHARINDEX(Repository.Feature + ',', @featureList, 1) > 0
		AND CHARINDEX(CASE WHEN (al.value IS NOT NULL AND CONVERT(NVARCHAR(4000), al.value) <> '') THEN CONVERT(NVARCHAR(4000), al.value) ELSE 'Internal' END, @audienceLevel, 1) > 0
		AND ((@bookmark IS NULL) OR (@bookmark = '') OR (Bookmark.Code = @bookmark))
		AND ((@branch IS NULL) OR (@branch = '') OR (Branch.Code = @branch))
		ORDER BY
			Repository.Feature,
			Repository.Branch,
			issues.id,
			CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END
	ELSE
		-- Get release notes version first.
		SELECT DISTINCT
			Repository.Branch,
			Repository.Feature,
			issues.id AS Issue,
			'http://jia-lnx1.jenkon.com/redmine/issues/' + CONVERT(NVARCHAR(50), issues.id) AS IssueURL,
			CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END AS Title,
			CONVERT(NVARCHAR(4000), rd.value) AS [Description]
		FROM Customer
		INNER JOIN CustomerRepository ON Customer.Id = CustomerRepository.Customer
		INNER JOIN Repository ON CustomerRepository.Repository = Repository.Id
		INNER JOIN RepositoryChangeset ON Repository.Id = RepositoryChangeset.Repository
		INNER JOIN Changeset ON RepositoryChangeset.Changeset = Changeset.Id
		INNER JOIN Redmine.issues ON Changeset.Issue = issues.id
		LEFT JOIN Redmine.custom_values rt ON (Changeset.Issue = rt.customized_id AND rt.custom_field_id = @releaseTitleId)
		LEFT JOIN Redmine.custom_values rd ON (Changeset.Issue = rd.customized_id AND rd.custom_field_id = @releaseDescriptionId)
		LEFT JOIN Redmine.custom_values al ON (Changeset.Issue = al.customized_id AND al.custom_field_id = @audienceLevelId)
		LEFT JOIN BookmarkChangeset ON Changeset.Id = BookmarkChangeset.Changeset
		LEFT JOIN Bookmark ON BookmarkChangeset.Bookmark = Bookmark.Id
		LEFT JOIN BranchChangeset ON Changeset.Id = BranchChangeset.Changeset
		LEFT JOIN Branch ON BranchChangeset.Branch = Branch.Id
		WHERE Customer.Code = @customer
		AND Repository.Branch >= @fromBranch
		AND Repository.Branch <= @toBranch
		AND CHARINDEX(Repository.Feature + ',', @featureList, 1) > 0
		AND CHARINDEX(CASE WHEN (al.value IS NOT NULL AND CONVERT(NVARCHAR(4000), al.value) <> '') THEN CONVERT(NVARCHAR(4000), al.value) ELSE 'Internal' END, @audienceLevel, 1) > 0
		AND ((@bookmark IS NULL) OR (@bookmark = '') OR (Bookmark.Code = @bookmark))
		AND ((@branch IS NULL) OR (@branch = '') OR (Branch.Code = @branch))
		ORDER BY
			Repository.Branch,
			Repository.Feature,
			issues.id,
			CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END
END
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddRepositoryEntry]
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
					(Code, [Description], [User], CreatedDateTime)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime)
			ELSE
				-- Insert changeset.
				INSERT INTO Changeset
					(Code, [Description], [User], CreatedDateTime, Issue)
				VALUES
					(@mercurialChangesetId, @summary, @user, @createdDateTime, @issueId)

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
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DeleteCustomerRepositoryMap]
	@customerCode NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get customer id.
		DECLARE @customerId INT
		SELECT @customerId = Id
			FROM Customer
			WHERE Code = @customerCode

		-- Was customer not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

		-- Delete customer repository map records.
		DELETE
			FROM CustomerRepository
			WHERE Customer = @customerId
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
CREATE PROCEDURE [dbo].[AddCustomerRepositoryMap]
	@customerCode NVARCHAR(50),
	@branch NVARCHAR(50),
	@feature NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get customer id.
		DECLARE @customerId INT
		SELECT @customerId = Id
			FROM Customer
			WHERE Code = @customerCode

		-- Was customer not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN -1
		END

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

		-- Does customer repository map not exist?
		SELECT 1
			FROM CustomerRepository
			WHERE Customer = @customerId
			AND Repository = @repositoryId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert customer repository map.
			INSERT INTO CustomerRepository
				(Customer, Repository)
			VALUES
				(@customerId, @repositoryId)
		END
	END TRY
	BEGIN CATCH
		RETURN -1
	END CATCH

	RETURN 0
END
GO
