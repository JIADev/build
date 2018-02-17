﻿<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/20/2017 13:23
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsInstallDB.ps1
	===========================================================================
	.DESCRIPTION
		A script for Jenkins to execute patch loader.  Previous execution was through msbuild in the deployment.proj file with the InstallDB target.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env,
	[string]$build_time
)

$workingDirectory = "$($ENV:WORKSPACE)\RELEASE"
#$workingDirectory = "C:\JCJenkins\workspace\1002\RELEASE"
$schemaUpdateDir = "$workingDirectory\SchemaUpdate"
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$sqlserver = $json.$driver.environments.$deploy_env.sql | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$dbName = $json.$driver.environments.$deploy_env.sql.dbName
$schemaUpdateScript = "SchemaUpdate.$dbName.$($build_time).sql"

#Import the j6DeployMsBuildTask.dll to use for PatchLoader.
[System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployMsBuildTasks.dll")

#Make sure PatchLoader is present and assign to process variable.
if (-not (test-path "$workingDirectory\Bootstrap\PatchLoader.exe")) { throw "$workingDirectory\RELEASE\Bootstrap\PatchLoader.exe" }
$patchLoader = "$workingDirectory\Bootstrap\PatchLoader.exe"

$preSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"
$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --skip-xml"
$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --phase=PreSchemaUpdate"

$schemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"
$schemaUpdateSwitches = "$schemaUpdateSwitches" + "--phase=SchemaUpdate"
$schemaUpdateSwitches = "$schemaUpdateSwitches" + ""

$postSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"

$packagesLocation = "$workingDirectory"
$additionalPatchDirs = "$schemaUpdateDir"

if (Test-Path -Path "$schemaUpdateDir")
{
	$existingSchemaUpdateFiles = gci -Path "$schemaUpdateDir" -Recurse
}

#Count Patches
if (Test-Path -Path "$schemaUpdateDir\$schemaUpdateScript")
{
	$countPatches = New-Object jDeployMsBuildTasks.PatchCount
	#$countPatches.Execute = $true
	$patches = $countPatches.Count($packagesLocation, $null, $preSchemaUpdateSwitches, $additionalPatchDirs, $true)
	Write-Host "$patches"
}

if ((Test-Path -Path "$schemaUpdateDir\$existingSchemaUpdateFiles") -and $patches -ne 0)
{
	gci -Path "$schemaUpdateDir\$existingSchemaUpdateFiles" -Recurse | Remove-Item -Recurse
}

#Run pre-schema update scripts
Start-Process -FilePath "$patchLoader" -ArgumentList $preSchemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait -RedirectStandardError "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"

##Run schema update scripts
Start-Process -FilePath "$patchLoader" -ArgumentList $schemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait -RedirectStandardError "$schemaUpdateDir\PatchLoader_SchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_SchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"
#
##Run post-schema update scripts
Start-Process -FilePath "$patchLoader" -ArgumentList $postSchemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait -RedirectStandardError "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_postSchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"

Write-Host "Install Database Completed."
#Need to mimic functionality from deploy.targets with the below targets that are called by the deploy target in deployment.proj in the order below.
