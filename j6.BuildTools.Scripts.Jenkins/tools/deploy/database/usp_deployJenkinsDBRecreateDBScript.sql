IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.usp_deployJenkinsDBRecreateDBScript'))
   exec('CREATE PROCEDURE [dbo].[usp_deployJenkinsDBRecreateDBScript] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[usp_deployJenkinsDBRecreateDBScript] @env varchar(25), @driver varchar(255)

AS

DECLARE
@dbName varchar(25),
@serviceUser varchar(25),
@custID varchar(25)

SELECT @custID = 
SELECT @dbName = ''

--USE [$($dbName)] GO; 

--Enable broker for any database
ALTER DATABASE [@dbName] SET NEW_BROKER WITH ROLLBACK IMMEDIATE

GO

---Enable CLR

EXEC sp_configure 'clr enabled', 1
go
RECONFIGURE
go
EXEC sp_configure 'clr enabled'
go

---Enable Security

--USE QAS_2095_AU

exec sp_adduser @loginame = 'jenkon\QAS2095_rte'
exec sp_addrolemember @rolename = 'db_owner', @membername = 'Jenkon\QAS2095_rte'

exec sp_adduser @loginame = 'jenkon\QAS2095_wp'
exec sp_addrolemember @rolename = 'db_owner', @membername = 'Jenkon\QAS2095_wp'
/*
	DECLARE 
	@ReportServerPathPrefix varchar(100),
	@ReportServerUrl varchar(255),
	@ConsultantWebSiteBaseURL varchar(255),
	@EmployeeWebSiteBaseURL varchar(255),
	@PersonalWebSiteBaseURL varchar(255),
	@PWS3_APIPath varchar(255),
	@PWS3_SitePath varchar(255)

	SELECT @ReportServerPathPrefix = '/' + @env + '/',
	@ReportServerUrl = @rptURL,
	@ConsultantWebSiteBaseURL = @custURL + '/Business/',
	@EmployeeWebSiteBaseURL = @custURL + '/Corporate/',
	@PersonalWebSiteBaseURL = @custURL + '/WebPWS/',
	@PWS3_APIPath = @custURL + '/WebPWS/API',
	@PWS3_SitePath = @custURL + '/WebPWS/'

	-- Update @ReportServerPathPrefix
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'ReportServerPathPrefix') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @ReportServerPathPrefix, 0, 1 from AppSetting where name = 'ReportServerPathPrefix'

	-- Update @ReportServerUrl
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'ReportServerUrl') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @ReportServerUrl, 0, 1 from AppSetting where name = 'ReportServerUrl'

	-- Update @ConsultantWebSiteBaseURL
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'ConsultantWebSiteBaseURL') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @ConsultantWebSiteBaseURL, 0, 1 from AppSetting where name = 'ConsultantWebSiteBaseURL'

	-- Update @EmployeeWebSiteBaseURL
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'EmployeeWebSiteBaseURL') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @EmployeeWebSiteBaseURL, 0, 1 from AppSetting where name = 'EmployeeWebSiteBaseURL'

	-- Update @PersonalWebSiteBaseURL
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'PersonalWebSiteBaseURL') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @PersonalWebSiteBaseURL, 0, 1 from AppSetting where name = 'PersonalWebSiteBaseURL'

	-- Update @PWS3_APIPath
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'PWS3_APIPath') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @PWS3_APIPath, 0, 1 from AppSetting where name = 'PWS3_APIPath'
	
	-- Update @PWS3_SitePath
	DELETE AppSettingValue WHERE AppSetting = (select id from AppSetting where name = 'PWS3_SitePath') AND (IsOverride = 'True' OR UserOverride = 'True')
	Insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride)
		Select id, @PWS3_SitePath, 0, 1 from AppSetting where name = 'PWS3_SitePath'

GO


*/