SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Portal](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Portal] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortalChangeset](
	[Portal] [int] NOT NULL,
	[Changeset] [int] NOT NULL,
 CONSTRAINT [PK_PortalChangeset] PRIMARY KEY CLUSTERED
(
	[Portal] ASC,
	[Changeset] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PortalChangeset]  WITH CHECK ADD  CONSTRAINT [FK_PortalChangeset_Changeset] FOREIGN KEY([Changeset])
REFERENCES [dbo].[Changeset] ([Id])
GO
ALTER TABLE [dbo].[PortalChangeset] CHECK CONSTRAINT [FK_PortalChangeset_Changeset]
GO
ALTER TABLE [dbo].[PortalChangeset]  WITH CHECK ADD  CONSTRAINT [FK_PortalChangeset_Portal] FOREIGN KEY([Portal])
REFERENCES [dbo].[Portal] ([Id])
GO
ALTER TABLE [dbo].[PortalChangeset] CHECK CONSTRAINT [FK_PortalChangeset_Portal]
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddPortal]
	@mercurialChangesetId NVARCHAR(50),
	@portal NVARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Get SQL Server changeset id (as opposed to Mercurial changeset id).
		DECLARE @changesetId INT
		SELECT @changesetId = Id
			FROM Changeset
			WHERE Code = @mercurialChangesetId

		-- Was SQL Server changeset not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- This is OK, because not all changesets are stored in database.
			RETURN 0
		END

		-- Get portal id.
		DECLARE @portalId INT
		SELECT @portalId = Id
			FROM Portal
			WHERE Code = @portal

		-- Was portal not found?
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert portal.
			INSERT INTO Portal
				(Code, [Description])
			VALUES
				(@portal, @portal)
			-- Get portal id.
			SELECT @portalId = Id
				FROM Portal
				WHERE Code = @portal
		END

		-- Does portal changeset map not exist?
		SELECT 1
			FROM PortalChangeset
			WHERE Portal = @portalId
			AND Changeset = @changesetId
		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Insert portal changeset map.
			INSERT INTO PortalChangeset
				(Portal, Changeset)
			VALUES
				(@portalId, @changesetId)
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
CREATE PROCEDURE [dbo].[GetReleaseNotes3]
	@customer NVARCHAR(50),
	@version NVARCHAR(50),
	@differenceFromVersion NVARCHAR(50),
	@portalList NVARCHAR(4000),
	@featureList NVARCHAR(4000),
	@fromDate DATE,
	@toDate DATE,
	@bookmark NVARCHAR(50),
	@audienceLevel NVARCHAR(50)
AS
BEGIN
	DECLARE @releaseTitleId INT
	SELECT @releaseTitleId = id FROM Redmine.custom_fields WHERE name = 'Release Title'

	DECLARE @releaseDescriptionId INT
	SELECT @releaseDescriptionId = id FROM Redmine.custom_fields WHERE name = 'Release Description'

	DECLARE @audienceLevelId INT
	SELECT @audienceLevelId = id FROM Redmine.custom_fields WHERE name = 'Audience Level'

	-- Add trailing comma for compare.
	SET @portalList = @portalList + ','
	SET @featureList = @featureList + ','

	-- Audience level Internal can see Internal and External.
	IF @audienceLevel = 'Internal' SET @audienceLevel = 'Internal,External'

	SELECT DISTINCT
		Repository.Feature,
		issues.id AS Issue,
		'http://redmine.jenkon.com/issues/' + CONVERT(NVARCHAR(50), issues.id) AS IssueURL,
		CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END AS Title,
		CONVERT(NVARCHAR(4000), rd.value) AS [Description]
	FROM Customer
	INNER JOIN CustomerRepository ON CustomerRepository.Customer = Customer.Id
	INNER JOIN Repository ON Repository.Id = CustomerRepository.Repository
	INNER JOIN Branch ON Branch.Repository = Repository.Id
	INNER JOIN BranchChangeset ON BranchChangeset.Branch = Branch.Id
	INNER JOIN Changeset ON Changeset.Id = BranchChangeset.Changeset
	INNER JOIN PortalChangeset ON PortalChangeset.Changeset = Changeset.Id
	INNER JOIN Portal ON Portal.Id = PortalChangeset.Portal
	INNER JOIN Redmine.issues ON issues.id = Changeset.Issue
	LEFT JOIN Redmine.custom_values rt ON ((rt.customized_id = issues.id) AND (rt.custom_field_id = @releaseTitleId))
	LEFT JOIN Redmine.custom_values rd ON ((rd.customized_id = issues.id) AND (rd.custom_field_id = @releaseDescriptionId))
	LEFT JOIN Redmine.custom_values al ON ((al.customized_id = issues.id) AND (al.custom_field_id = @audienceLevelId))
	LEFT JOIN Bookmark ON Bookmark.Repository = Repository.Id
	WHERE Customer.Code = @customer
	AND Branch.Code = @version
	AND Changeset.Id NOT IN (
		SELECT BranchChangeset.Changeset
		FROM Customer
		INNER JOIN CustomerRepository ON CustomerRepository.Customer = Customer.Id
		INNER JOIN Repository ON Repository.Id = CustomerRepository.Repository
		INNER JOIN Branch ON Branch.Repository = Repository.Id
		INNER JOIN BranchChangeset ON BranchChangeset.Branch = Branch.Id
		WHERE Customer.Code = @customer
		AND Branch.Code = @differenceFromVersion
	)
	AND CHARINDEX(Portal.Code + ',', @portalList, 1) > 0
	AND CHARINDEX(Repository.Feature + ',', @featureList, 1) > 0
	AND ((@fromDate IS NULL) OR (@fromDate <= Changeset.CreatedDateTime))
	AND ((@toDate IS NULL) OR (@toDate >= Changeset.CreatedDateTime))
	AND ((@bookmark IS NULL) OR (@bookmark = '') OR (Bookmark.Code = @bookmark))
	AND CHARINDEX(CASE WHEN (al.value IS NOT NULL AND CONVERT(NVARCHAR(4000), al.value) <> '') THEN CONVERT(NVARCHAR(4000), al.value) ELSE 'Internal' END, @audienceLevel, 1) > 0
	ORDER BY
		Repository.Feature,
		issues.id,
		CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END
END
GO
