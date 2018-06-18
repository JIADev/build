SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetFeatureList](
	@issueId INT,
	@branchCode NVARCHAR(50))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @featureList VARCHAR(MAX)

	DECLARE @tempFeatureList TABLE (
		Feature NVARCHAR(50)
	)

	INSERT INTO @tempFeatureList (Feature)
	SELECT DISTINCT Repository.Feature
	FROM Changeset
	INNER JOIN BranchChangeset ON BranchChangeset.Changeset = Changeset.Id
	INNER JOIN Branch ON Branch.Id = BranchChangeset.Branch
	INNER JOIN Repository ON Repository.Id = Branch.Repository
	WHERE Changeset.Issue = @issueId
	AND Branch.Code = @branchCode
	ORDER BY Repository.Feature

	SELECT @featureList = COALESCE(@featureList + ', ', '') + Feature
	FROM @tempFeatureList

	RETURN @featureList
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetReleaseNotes3]
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
		issues.id AS Issue,
		'http://redmine.jenkon.com/issues/' + CONVERT(NVARCHAR(50), issues.id) AS IssueURL,
		CASE WHEN (rt.value IS NOT NULL AND CONVERT(NVARCHAR(4000), rt.value) <> '') THEN CONVERT(NVARCHAR(4000), rt.value) ELSE issues.[subject] END AS Title,
		CONVERT(NVARCHAR(4000), rd.value) AS [Description],
		dbo.GetFeatureList(issues.id, @version) AS Feature
	FROM Customer
	INNER JOIN CustomerRepository ON CustomerRepository.Customer = Customer.Id
	INNER JOIN Repository ON Repository.Id = CustomerRepository.Repository
	INNER JOIN Branch ON Branch.Repository = Repository.Id
	INNER JOIN BranchChangeset ON BranchChangeset.Branch = Branch.Id
	INNER JOIN Changeset ON Changeset.Id = BranchChangeset.Changeset
	INNER JOIN PortalChangeset ON PortalChangeset.Changeset = Changeset.Id
	INNER JOIN Portal ON Portal.Id = PortalChangeset.Portal
	INNER JOIN Redmine.issues ON issues.id = Changeset.Issue
	INNER JOIN Redmine.issue_statuses ON issue_statuses.id = issues.status_id
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
	AND issue_statuses.is_closed = 1
	ORDER BY
		issues.id
END
GO
