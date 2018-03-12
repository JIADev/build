<#	
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
$sqlserver = $json.$driver.environments.$deploy_env.sql.hostname
$dbName = $json.$driver.environments.$deploy_env.sql.dbName
$schemaUpdateScript = "SchemaUpdate.$dbName.$($build_time).sql"
$scriptDacPacsScriptPath = "$($ENV:ps_scripts_dir)\deploy\database\deployJenkinsNewDBScriptDacPacs.ps1"

#Import the j6DeployMsBuildTask.dll to use for PatchLoader.
System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployPowerShellTasks.dll")

#Make sure PatchLoader is present and assign to process variable.


$additionalPatchDirs = "$schemaUpdateDir"




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



