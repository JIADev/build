<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	2/8/2018 13:25
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployWebCreateReleasePackageStructure.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$driver
)

Write-Host "Checking Jenkins for Deployment package directory structure for this driver."
#Look for root path, if not there, create. -- E:\Jenkins\pkgs\${JOB_NAME}
$pkgsPath = "E:\Jenkins\pkgs\$driver"

if (!(Test-Path -Path $pkgsPath))
{
	Write-Host "$pkgsPath does not exist for this driver, creating it."
	
	mkdir $pkgsPath
	
	if (!(Test-Path -Path "$pkgsPath\ArchiveSite"))
	{
		Write-Host "$pkgsPath\ArchiveSite does not exist for this driver, creating it."
		mkdir "$pkgsPath\ArchiveSite"
	}
	else { Write-Host "$pkgsPath\ArchiveSite created."}
	
	
	if (!(Test-Path -Path "$pkgsPath\LatestSite"))
	{
		Write-Host "$pkgsPath\LatestSite does not exist for this driver, creating it."
		mkdir "$pkgsPath\LatestSite"
	}
	else { Write-Host "$pkgsPath\LatestSite created."}
	
	if (!(Test-Path -Path "$pkgsPath\ReleasePkg"))
	{
		Write-Host "$pkgsPath\ReleasePkg does not exist for this driver, creating it."
		mkdir "$pkgsPath\ReleasePkg"
	}
	else { Write-Host "$pkgsPath\ReleasePkg created."}
	
	if (!(Test-Path -Path "$pkgsPath\Staging"))
	{
		Write-Host "$pkgsPath\Staging does not exist for this driver, creating it."
		mkdir "$pkgsPath\Staging"
	}
	else { Write-Host "$pkgsPath\Staging created."}
}
else {Write-Host "Deployment package directory structure exists in Jenkins for this driver."}
