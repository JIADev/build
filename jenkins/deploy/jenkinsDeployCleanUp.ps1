<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	2/14/2018 15:26
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployCleanUp.ps1
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

$sitePkgLimit = (Get-Date).AddMonths(-2) #months
$siteBaksLimit = (Get-Date).AddMonths(-6) #months
$rtePkgLimit = (Get-Date).AddMonths(-2) #months
$rteBaksLimit = (Get-Date).AddMonths(-6) #months

$json = Get-Content $config_json -Raw | ConvertFrom-Json
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$rteServer = $json.$driver.environments.$deploy_env.rte.hostname
$appDrive = $json.$driver.environments.$deploy_env.appDrive
$rteDrive = $json.$driver.environments.$deploy_env.rte.rteDrive
$appDeployPkgDir = $json.$driver.environments.$deploy_env.pkgDir
$appBaksPkgDir = $json.$driver.environments.$deploy_env.siteBAKSDir
$rteDeployPkgDir = $json.$driver.environments.$deploy_env.siteBAKSDir
$rteBaksPkgDir = $json.$driver.environments.$deploy_env.siteBAKSDir

$rteTempDir = "RTEstage"
$siteReleasePkgPath = gci -Path "$sitePkgDir\LatestSite" -Recurse | where { $_ -like '*_Site.zip' } | select -ExpandProperty FullName

#Clean up PKGS on web

#delete PKGS older than 2 months
$webCleanUpPath = "$($appDrive):\$appDeployPkgDir"
gci -Path $webCleanUpPath -Recurse -File *.zip | ? { !$_.PSIsContainer -and $_.CreationTime -lt $sitePkgLimit } | Remove-Item -Force -Recurse

#delete BAKS older than 6 months
$webCleanUpPath = "$($appDrive):\$appBaksPkgDir"
gci -Path $webCleanUpPath -Recurse -File *.zip | ? { !$_.PSIsContainer -and $_.CreationTime -lt $siteBaksLimit } | Remove-Item -Force -Recurse


#Clean up PKGS on RTE

#delete PKGS older than 2 months
$rteCleanUpPath = "$($rteDrive):\$rteDeployPkgDir"
gci -Path $rteCleanUpPath -Recurse -File *.zip | ? { !$_.PSIsContainer -and $_.CreationTime -lt $rtePkgLimit } | Remove-Item -Force -Recurse

#delete BAKS older than 6 months
$rteCleanUpPath = "$($rteDrive):\$rteBaksPkgDir"
gci -Path $rteCleanUpPath -Recurse -File *.zip | ? { !$_.PSIsContainer -and $_.CreationTime -lt $rteBaksLimit } | Remove-Item -Force -Recurse

#Clean up "temp" on RTE if it exists

if (Test-Path -Path "C:\$rteTempDir")
{
	gci -Path "C:\" $rteTempDir | Remove-Item -Force -Recurse
}
