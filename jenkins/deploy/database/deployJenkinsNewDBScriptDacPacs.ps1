﻿<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	11/22/2017 13:46
	 Created by:   	jcollins
	 Organization: 	JIA, Inc.
	 Filename:     	deployJenkinsNewDBScriptDacPacs.ps1
	===========================================================================
	.DESCRIPTION
		This is the new version of the ScriptDacPacs script from the Jenkins deploy.  This should accept the workspace and do the dacpac and schemaupdate creation in the directory structure passed in.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	#[string]$config_json, - from old file, to be deleted
	[string]$deploy_env,
	[string]$build_time,
	[string]$workingdir #Added in the version
)

if (-not (test-path "$env:ProgramFiles\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\SqlPackage.exe")) { throw "$env:ProgramFiles\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\SqlPackage.exe" }
$exe = '"' + 'C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\SqlPackage.exe' + '"'

#$workingDirectory = "$($ENV:WORKSPACE)" -from old file, to be deleted
$workingDirectory = $workingdir
$dacpacFile = "$workingDirectory\DacPacs\$driver.Database.dacpac"
Write-Host "Working Directory is $workingDirectory" -foreground Green
Write-Output ('$dacpacFile : ' + $dacpacFile)

#$json = Get-Content $config_json -Raw | ConvertFrom-Json - no longer passing in $config_json, using $($ENV:config_json) from the Jenkins global variables
$json = Get-Content "$($ENV:config_json)" -Raw | ConvertFrom-Json
$sqlserver = $json.$driver.environments.$deploy_env.sql.hostname
$dbName = $json.$driver.environments.$deploy_env.sql.dbName
$schemaUpdateDir = "$workingDirectory\SchemaUpdate"
$schemaUpdateScript = "SchemaUpdate.$dbName.$($build_time).sql"
$deployReportXML = "DeployReport.$($build_time).xml"

$prependLines = "--SchemaUpdate Script generated by SqlPackage.exe"
$prependLines = $prependLines + "--patch-date: 1976-07-04"
$prependLines = $prependLines + "--SqlCmd: true"
$prependLines = $prependLines + "--phase: SchemaUpdate"
$prependLines = $prependLines + "--transaction: false"

if (Test-Path -Path "$schemaUpdateDir")
{
	$schemaUpdateFileCount = (Get-ChildItem -Path $schemaUpdateDir -Recurse | Measure-Object)
	if ($schemaUpdateFileCount.count -ge 1)
	{
		gci -Path "$schemaUpdateDir" -Recurse | Remove-Item
	}
	else
	{
		Write-Host "There are no Schema Update Scripts."
	}
}

$sf = "$dacpacFile"
$scriptOP = "$schemaUpdateDir\$schemaUpdateScript"
$reportOP = "$schemaUpdateDir\$deployReportXML"
$cs = ('"' + $env:ConnectionString + '"')

$scriptAction = "Script"
$scriptParam = "/Action:$scriptAction /SourceFile:$sf /tsn:$($sqlserver) /tdn:$($dbName) /OutputPath:$scriptOP"
Write-Output "Generate Change Script"
Write-Output "Args: $scriptParam"
Write-Output ("$exe" + " " + $scriptParam)
Start-Process -FilePath "$exe" -ArgumentList $scriptParam -PassThru -Wait -RedirectStandardError "$schemaUpdateDir\SchemaUpdate_$dbName_$($build_time).log"

if (Test-Path -path "$schemaUpdateDir\$schemaUpdateScript")
{
	$path = "$schemaUpdateDir\$schemaUpdateScript"
	$prependLines + (Get-Content $path -Raw) | Set-Content $path
}

$reportAction = "DeployReport"
$reportParam = "/Action:$reportAction /SourceFile:$sf /tsn:$sqlserver /tdn:$dbName /OutputPath:$reportOP"
Write-Output "Generate DeployReport"
Write-Output "Args: $reportParam"
Write-Output ("$exe" + " " + $reportParam)
Start-Process -FilePath "$exe" -ArgumentList $reportParam -PassThru -Wait -RedirectStandardError "$schemaUpdateDir\DeployReport_$($build_time).log"

