<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	1/15/2018 13:45
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsDBUpdateAppSettings.ps1
	===========================================================================
	.DESCRIPTION
		This script will update the AppSettings of the DB to the specific values needed for this client.
		It will be done by creating a sproc on the DB that updates the appSettings and then executing the sproc.
		After it executes the sproc, it will drop the sproc to clean up after itself.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env,
	[string]$ps_scripts_dir
)

$deployPSScriptDir = "$ps_scripts_dir"

#format $driver into <env_####> format
#$cust = $driver.Substring(4)
#$custENV = $deploy_env + "_" + $cust

#get json config
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$sqlserver = $json.$driver.environments.$deploy_env.sql.hostname
$dbName = $json.$driver.environments.$deploy_env.sql.dbName
$rptURL = $json.$driver.environments.$deploy_env.reports.reportURL
$custPrefix = $json.$driver.environments.$deploy_env.custPrefix
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$custURL = $json.$driver.environments.$deploy_env.url

#execute sproc creation on the DB
$appSettingScript = gci -Path "$deployPSScriptDir" -Recurse | where { $_ -like 'usp*AppSetting*.sql' } | select -ExpandProperty FullName
& SQLCMD -S "$sqlserver" -d "$dbName" -i "$appSettingScript" -e

#execute the sproc to update appSettings
$proc = (Get-Item $appSettingScript).Basename
$sqlCMD = "EXEC dbo.$proc '$custPrefix', '$custURL', '$rptURL'" 
& SQLCMD -S "$sqlserver" -d "$dbName" -Q "$sqlCMD" -e

#execute drop of sproc
$sqlCMD = "DROP PROCEDURE dbo.$proc"
& SQLCMD -S "$sqlserver" -d "$dbName" -Q "$sqlCMD" -e

