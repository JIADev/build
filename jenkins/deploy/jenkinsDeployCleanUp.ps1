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

#Clean up PKGS on web

#clean up >6 month BAKS on web

#Clean up PKGS on RTE

#clean up >6 month BAKS on web

#Clean up "temp" on RTE

