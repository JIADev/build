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
[System.Reflection.Assembly]::LoadFrom("$workingDirectory\Bootstrap\jDeployMsBuildTasks.dll")

#Make sure PatchLoader is present and assign to process variable.
if (-not (test-path "$workingDirectory\Bootstrap\PatchLoader.exe")) { throw "$workingDirectory\RELEASE\Bootstrap\PatchLoader.exe" }
$patchLoader = "$workingDirectory\Bootstrap\PatchLoader.exe"

$preSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose "
$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --skip-xml"
$preSchemaUpdateSwitches = "$preSchemaUpdateSwitches" + " --phase=PreSchemaUpdate"

$schemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"
$schemaUpdateSwitches = "$schemaUpdateSwitches" + "--phase=SchemaUpdate"
$schemaUpdateSwitches = "$schemaUpdateSwitches" + ""

$postSchemaUpdateSwitches = "--noninteractive --exit-for-noop --verbose"

$packagesLocation = "$workingDirectory"
$additionalPatchDirs = "$schemaUpdateDir"

Write-Host "SchemaUpdate dir is $schemaUpdateDir"

if (Test-Path -Path "$schemaUpdateDir")
{
	$existingSchemaUpdateFiles = gci -Path "$schemaUpdateDir" -Recurse
}

#Count Patches
Write-Host "schemaUpdateDir\schemaUpdateScript is $schemaUpdateDir\$schemaUpdateScript"
$test = (Test-Path "$schemaUpdateDir\$schemaUpdateScript")
Write-Host "Test-Path results: $test"
if (Test-Path "$schemaUpdateDir\$schemaUpdateScript")
{
	Write-Host "Counting Patches."
	$countPatches = New-Object jDeployMsBuildTasks.CountPatchesPSWrapper -Property @{
		'PackagesLocation'  = "$packagesLocation";
		'Switches'		    = $preSchemaUpdateSwitches;
		'Verbose'		    = $true;
		
	}
	if ($countPatches.PatchCount -ge 0)
	{
		$patches = $countPatches.PatchCount
		Write-Host "There are $patches patches."
	}
	else
	{
		Write-Error "There was an issue counting patches."	
	}
}

if ((Test-Path -Path "$schemaUpdateDir\$existingSchemaUpdateFiles") -and $patches -gt 0)
{
	Write-Host "We want the schema update files to be re-geerated if there were PreSchemaUpdate patches run."
	gci -Path "$schemaUpdateDir\$existingSchemaUpdateFiles" -Recurse | Remove-Item -Recurse
}

Write-Host "Run preschema updates."
& $($patchLoader) $($preSchemaUpdateSwitches)



#Write-Host "Run pre-schema update scripts"
##Start-Process -FilePath "$patchLoader" -ArgumentList $preSchemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait #-RedirectStandardError "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"
#$pinfo = New-Object System.Diagnostics.ProcessStartInfo
#$pinfo.FileName = "$patchLoader"
#$pinfo.RedirectStandardError = $true
#$pinfo.RedirectStandardOutput = $true
#$pinfo.UseShellExecute = $false
#$pinfo.Arguments = "$preSchemaUpdateSwitches"
#$p = New-Object System.Diagnostics.Process
#$p.StartInfo = $pinfo
#$p.Start() | Out-Null
#$stdout = $p.StandardOutput.ReadToEnd()
#$stderr = $p.StandardError.ReadToEnd()
#$p.WaitForExit()
#Write-Host "$stdout"
#Write-Host "$stderr" -ForegroundColor Red
#Write-Host "exit code: " + $p.ExitCode

if ($patches -ne 0 -or (!(Test-Path "$schemaUpdateDir\$schemaUpdateScript")))
	{
		Write-Host "Regenerate schema update files."
	#		Invoke-Command -ComputerName "JIA-jenkins1" -FilePath "$scriptDacPacsScriptPath" -ArgumentList "$driver", "$config_json", "$deploy_env", "$build_time", "$workingDirectory"
		$scriptArgs = "$driver $config_json $deploy_env $build_time $workingDirectory"
		& $scriptDacPacsScriptPath $scriptArgs
}

Write-Host "Run Schema Updates"
& $($patchLoader) $($preSchemaUpdateSwitches)

Write-Host "Run Post Schema Updates"
& $($patchLoader) $($postSchemaUpdateSwitches)

<#Write-Host "Run schema update scripts"
#Start-Process -FilePath "$patchLoader" -ArgumentList $schemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait #-RedirectStandardError "$schemaUpdateDir\PatchLoader_SchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_SchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"
#$pinfo = New-Object System.Diagnostics.ProcessStartInfo
#$pinfo.FileName = "$patchLoader"
#$pinfo.RedirectStandardError = $true
#$pinfo.RedirectStandardOutput = $true
#$pinfo.UseShellExecute = $false
$pinfo.Arguments = "$schemaUpdateSwitches"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"
Write-Host "exit code: " + $p.ExitCode

#Write-Host "Run post-schema update scripts"
#Start-Process -FilePath "$patchLoader" -ArgumentList $postSchemaUpdateSwitches -WorkingDirectory "$workingDirectory" -PassThru -Wait #-RedirectStandardError "$schemaUpdateDir\PatchLoader_preSchemaUpdate_$($ENV:BUILD_TIMESTAMP)_Error.log" -RedirectStandardOutput "$schemaUpdateDir\PatchLoader_postSchemaUpdate_$($ENV:BUILD_TIMESTAMP).log"
#$pinfo = New-Object System.Diagnostics.ProcessStartInfo
#$pinfo.FileName = "$patchLoader"
#$pinfo.RedirectStandardError = $true
#$pinfo.RedirectStandardOutput = $true
#$pinfo.UseShellExecute = $false
$pinfo.Arguments = "$postSchemaUpdateSwitches"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"
Write-Host "exit code: " + $p.ExitCode

<#
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "$patchLoader"
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "$preSchemaUpdateSwitches"
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"
Write-Host "exit code: " + $p.ExitCode
#>