<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	1/19/2018 14:02
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployDatabaseRecreateDB.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env
)

$workingDirectory = "$($ENV:WORKSPACE)\RELEASE"
#$workingDirectory = "\\jia-jenkins1\d$\deploy\TEST_2095AU_hg_Deploy\RELEASE"

#get json config info for sql server and dbname and possibly backup drive.
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$dbname = $json.$driver.environments.$deploy_env.sql.dbName

[System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployPowerShellTasks.dll")
$recreatDBEngine = New-Object -TypeName jDeployPowerShellTasks.RecreateDB.PSRecreateDB


$request = New-Object -TypeName jDeployPowerShellTasks.RecreateDB.RecreateDBRequest
$request.WorkingFolder = "$workingDirectory"
$request.SqlSettingsFilePath = "$workingDirectory"
$request.DatabaseName = $dbname

try
{
	Write-Host "Marco"
	$result = $recreatDBEngine.Execute($request)
}
catch {Write-Host "Polo" }



