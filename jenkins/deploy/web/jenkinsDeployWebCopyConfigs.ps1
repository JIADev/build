<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
	 Created on:   	1/31/2018 09:16
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployWebCopyConfigs.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$deploy_env,
	[string]$siteDir
)

#$siteDir should resolve to workingDirectory\Release\Site

$configRepo = "\\jia-jenkins1\E$\webConfigs"
$configDir = "$configRepo\$driver\$deploy_env\Site"

robocopy /S /Z /E $configDir $siteDir web.config
#gci -Path $configDir -Name web.config -Recurse -Force | Copy-Item -Destination $siteDir
#$configs = gci -Path $configDir -Recurse #| where { $_ -like 'web.config' } | select -ExpandProperty FullName