<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	11/22/2017 10:59
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployRTE.ps1
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

$deploySharedExtractRTEScriptPath = "$ps_scripts_dir\deploy\rte\jenkinsDeployExtractRTEOnServer.ps1"
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$rteHostname = $json.$driver.environments.$deploy_env.rte.hostname
$rteIP = $json.$driver.environments.$deploy_env.rte.ip
$rteDir = $json.$driver.environments.$deploy_env.rte.rteDir
$rteDrive = $json.$driver.environments.$deploy_env.rte.rteDrive
$pkgDir = $json.$driver.environments.$deploy_env.pkgDir
$rteBAKSDir = $json.$driver.environments.$deploy_env.siteBAKSDir
$sharedPkgPath = gci -Path "$($ENV:pkgs_dir)\$($ENV:buildJobName)\LatestSite" -Recurse | where { $_ -like '*_Shared.zip' } | select -ExpandProperty FullName
$rtePkgPath = "\\$rteIP\$($rteDrive)$\$pkgDir"

try
{
	#	$psdrive = ls function:[d-z]: -n | ?{ !(test-path $_) } | random
	$psdrive = "$($hostname)RteDeploy"
	New-PSDrive -Name $psdrive -PSProvider FileSystem -Root $rtePkgPath -Credential $credential #-Persist
	Copy-Item -Path "$sharedPkgPath" -Destination "$($psdrive):\" -Force -Recurse -Verbose -Credential $credential
	Invoke-Command -ComputerName $rteHostname -Credential $credential -FilePath "$deploySharedExtractRTEScriptPath" -ArgumentList "$rteDrive", "$rteDir", "$rteBAKSDir", "$pkgDir"
}
finally
{
	Remove-PSDrive -Name $psdrive
	Write-Host "$sharedPkgPath copied to $rtePkgPath"
}