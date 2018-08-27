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

#create PSCred object for PSRemoting
$user = "jenkon\ccnet_new"
$secPW = (Get-Content "$($ENV:secrets_dir)\ccnet.txt") | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($user, $secPW)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -LiteralPath $(if ($PSVersionTable.PSVersion.Major -ge 3) { $PSCommandPath }
	else { & { $MyInvocation.ScriptName } })

#$deploySitePkgScriptPath = "C:\dev\Repos\build\jenkins\deploy\web\jenkinsDeployExtractSiteOnServer.ps1" #will be changed to a version from the passed in path in PRD.
$deploySitePkgScriptPath = "$ps_scripts_dir\deploy\web\jenkinsDeployExtractSiteOnServer.ps1"

#	$cust = $driver.Substring(4,($driver.Length - 4))

#Get list of web servers from config.
#get the contents of the JSON file with the server list in it.
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$deployPkgDir = $json.$driver.environments.$deploy_env.pkgDir
$siteReleasePkgPath = gci -Path "$($ENV:pkgs_dir)\$($ENV:buildJobName)\LatestSite" -Recurse | where { $_ -like '*_Site.zip' } | select -ExpandProperty FullName

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
		$deployPkgPath = "\\$ip\$($siteDrive)$\$($deployPkgDir)"
		Write-Host "Copying $siteReleasePkgPath to $deployPkgPath on $hostname"
		Write-Host "You are here."
		Write-Host "Driver $($driver)"
		Write-Host "Build Number $($ENV:BUILD_NUMBER)"
		$psdrive = "$($driver)_$($ENV:BUILD_NUMBER)SiteDeploy"
		Write-Host	"You are here. psdrive is $($psdrive)"
		New-PSDrive -Name $psdrive -PSProvider FileSystem -Root $deployPkgPath -Credential $credential #-Persist 
		#			Copy-Item -Path "$siteReleasePkgPath" -Destination "$($psdrive):\" -Force -Recurse -Verbose
		Write-Host "Now you are here. PSDrive supposedly created."
		Copy-Item -Path "$siteReleasePkgPath" -Destination "$($psdrive):\" -Force -Recurse -Verbose
		Write-Host "File copy complete."
		Invoke-Command -ComputerName $hostname -Credential $credential -FilePath "$deploySitePkgScriptPath" -ArgumentList $siteDrive, $siteDir, $siteBAKSDir, $deployPkgDir
		Write-Host "Now the extraction has been complete."
	}
	catch
	{
		Write-Host "In the catch"
		$ErrorMessage = $_.Exception.Message
		Write-Host $ErrorMessage
	}
	finally
	{
		Write-Host "Hit the finally"
		Remove-PSDrive -Name $psdrive
		
	}
}
