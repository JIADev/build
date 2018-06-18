<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/20/2017 13:23
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsNewDBInstallDB.ps1
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

<# Debug locally
$driver = "CUST2095AU"
$config_json = "\\jia-jenkins1\d$\secrets\deployConfig.json"
$deploy_env = "JC"
$build_time = "20180227111911"
$ENV:WORKSPACE = "C:\TestJenkins\workspace\2095AU_hg"
$ENV:ps_scripts_dir = "C:\dev\code\build\jenkins"

#>

$workingDirectory = "$($ENV:WORKSPACE)\RELEASE"
#$workingDirectory = "C:\JCJenkins\workspace\1002\RELEASE"
$schemaUpdateDir = "$workingDirectory\SchemaUpdate"
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$sqlserver = $json.$driver.environments.$deploy_env.sql.hostname
$dbName = $json.$driver.environments.$deploy_env.sql.dbName
$schemaUpdateScript = "SchemaUpdate.$dbName.$($build_time).sql"
$scriptDacPacsScriptPath = "$($ENV:ps_scripts_dir)\deploy\database\deployJenkinsNewDBScriptDacPacs.ps1"

#Import the j6DeployMsBuildTask.dll to use for PatchLoader.
#$x = [System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployMsBuildTasks.dll")
[System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployPowerShellTasks.dll")

#Make sure PatchLoader is present and assign to process variable.
#if (-not (test-path "$workingDirectory\Bootstrap\PatchLoader.exe")) { throw "$workingDirectory\RELEASE\Bootstrap\PatchLoader.exe" }
#$patchLoader = "$workingDirectory\Bootstrap\PatchLoader.exe"
#
#$preSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose "
#$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --skip-xml"
#$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --phase=PreSchemaUpdate"
#
#$schemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"
#$schemaUpdateSwitches = "$schemaUpdateSwitches" + "--phase=SchemaUpdate"
#$schemaUpdateSwitches = "$schemaUpdateSwitches" + ""
#
#$postSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"

$additionalPatchDirs = "$schemaUpdateDir"


#if ((Test-Path -Path "$schemaUpdateDir\$existingSchemaUpdateFiles") -and $patches -gt 0)
#{
#	Write-Host "We want the schema update files to be re-geerated if there were PreSchemaUpdate patches run."
#	gci -Path "$schemaUpdateDir\$existingSchemaUpdateFiles" -Recurse | Remove-Item -Recurse
#}

$PSPatchEngine = New-Object -TypeName jDeployPowerShellTasks.DeployPatches.PSDeployPatches
$PatchRequest = New-Object -TypeName jDeployPowerShellTasks.DeployPatches.DeployPatchesRequest
$PatchRequest.WorkingFolder = "$workingDirectory"

#Run PreSchema Phase
try
{
	$PatchRequest.Phases = @("PreSchemaUpdate")
	$result = $PSPatchEngine.Execute($PatchRequest)
}
catch { Write-Error "Preschema FAILED." }


#Regenerate SchemaUpdate scripts

$scriptArgs = "$driver $config_json $deploy_env $build_time $workingDirectory"
Invoke-Command -ComputerName "JIA-JENKINS1" { "$($ENV:ps_scripts_dir)\deploy\database\deployJenkinsNewDBScriptDacPacs.ps1" } -ArgumentList $driver,$config_json,$deploy_env,$build_time,$workingDirectory

	#Invoke-Command "$($ENV:ps_scripts_dir)\deploy\database\deployJenkinsNewDBScriptDacPacs.ps1 -driver $driver -config_json $config_json -deploy_env $deploy_env -build_time $build_time -workingDirectory $workingDirectory"
#	& $scriptDacPacsScriptPath $scriptArgs

#Run SchemaUpdate and DataPatch (PostSchema) phases
try
{
	
	$PatchRequest.Phases = @("SchemaUpdate", "DataPatch")
	$result = $PSPatchEngine.Execute($PatchRequest)
}
catch {Write-Error "SchemaUpdate FAILED"}



