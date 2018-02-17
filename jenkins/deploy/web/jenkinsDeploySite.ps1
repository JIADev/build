<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/16/2017 14:55
	 Created by:   	jcollins
	 Organization: 	JIA Inc.
	 Filename:     	jenkinsDeploySite.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


param
(
	[Parameter(Mandatory = $true)]
	[string]$ps_scripts_dir,
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env,
	[string]$sitePkgDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -LiteralPath $(if ($PSVersionTable.PSVersion.Major -ge 3) { $PSCommandPath }
	else { & { $MyInvocation.ScriptName } })

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#$deploySitePkgScriptPath = "C:\dev\Repos\build\jenkins\deploy\web\jenkinsDeployExtractSiteOnServer.ps1" #will be changed to a version from the passed in path in PRD.
$deploySitePkgScriptPath = "$ps_scripts_dir\deploy\web\jenkinsDeployExtractSiteOnServer.ps1"

try
{
	#	$cust = $driver.Substring(4,($driver.Length - 4))
	
	#Get list of web servers from config.
	#get the contents of the JSON file with the server list in it.
	$json = Get-Content $config_json -Raw | ConvertFrom-Json
	$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
	$deployPkgDir = $json.$driver.environments.$deploy_env.pkgDir
	$siteReleasePkgPath = gci -Path "$sitePkgDir\LatestSite" -Recurse | where { $_ -like '*_Site.zip' } | select -ExpandProperty FullName
	
	#Loop through each web server
	#Copy site to correct directory on each web server and extract.
	foreach ($webserver in $webservers)
	{
		try
		{
			$hostname = $json.$driver.environments.$deploy_env.webservers.$webserver.hostname
			$ip = $json.$driver.environments.$deploy_env.webservers.$webserver.ip
			$siteDrive = $json.$driver.environments.$deploy_env.appDrive
			$siteDir = $json.$driver.environments.$deploy_env.appDir
			$siteBAKSDir = $json.$driver.environments.$deploy_env.siteBAKSDir
			#	Write-Host $hostname
			#	Write-Host $ip
			$deployPkgPath = "\\$ip\$($siteDrive)$\$deployPkgDir"
			Write-Host "Copying $siteReleasePkgPath to $deployPkgPath on $hostname"
			$psdrive = "$($hostname)SiteDeploy"
			#			$psdrive = ls function:[d-z]: -n | ?{ !(test-path $_) } | random
			New-PSDrive -Name $psdrive -PSProvider FileSystem -Root $deployPkgPath #-Persist
			#			Copy-Item -Path "$siteReleasePkgPath" -Destination "$($psdrive):\" -Force -Recurse -Verbose
			Copy-Item -Path "$siteReleasePkgPath" -Destination "$($psdrive):\" -Force -Recurse -Verbose
			Write-Host "File copy complete."
			Invoke-Command -ComputerName $hostname -FilePath "$deploySitePkgScriptPath" -ArgumentList $siteDrive, $siteDir, $siteBAKSDir, $deployPkgDir
		}
		finally
		{
			Remove-PSDrive -Name $psdrive
			
		}
	}
}
finally
{
	Write-Output "Done! $($stopwatch.Elapsed)"
}