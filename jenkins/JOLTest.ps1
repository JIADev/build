<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
	 Created on:   	4/4/2018 16:20
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	JOLTest.ps1
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

$json = Get-Content $config_json -Raw | ConvertFrom-Json
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$deployPkgDir = "test"

$siteReleasePkgPath = gci -Path "$sitePkgDir\LatestSite" -Recurse | where { $_ -like '*_Site.zip' } | select -ExpandProperty FullName

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
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Write-Error $ErrorMessage
	}
	finally
	{
		Remove-PSDrive -Name $psdrive
		
	}
}