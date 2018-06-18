<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	11/21/2017 08:34
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployExtractSiteOnServer.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$siteDrive,
	[string]$siteDir,
	[string]$siteBAKSDir,
	[string]$pkgDir
)

$sitePkgDir = "$($siteDrive):\$pkgDir" #"E:\$($cust)_PKGS"
$siteAppDir = "$($siteDrive):\$siteDir\Site" #"E:\$($cust)_APPS\Site"
#$siteAppDir = "C:\Temp\$($cust)_APPS\Site"
$siteBackupDir = "$($siteDrive):\$siteBAKSDir" #"E:\$($cust)_BAKS"
#$siteBackupDir = "C:\Temp2\$($cust)_BAKS"
#$siteZipFile = "c:\Temp2\1002_PKGS\RELEASE_CUST1002-7.7.0.0-20171120100829_109_Site.zip" #this will be removed in production and use the path passed in as param
$timestamp = Get-Date -Format "yyyyMMddhhmmss"
$oldSiteZipFile = "$($siteBackupDir)\site_preDeploy_$($timestamp)_bak"
#$zipFile = Split-Path $siteZipFile -Leaf
#$zipPkgsPath = "E:\$($cust)_PKGS\$($zipFile)"

#Zip current site folder and copy to pkgs/CUST/latest folder
if ((Test-Path -Path $siteAppDir))
	{
		Compress-Archive -Path $siteAppDir -DestinationPath $oldSiteZipFile
}
else
{
	throw "$siteAppDir does not exist or access is denied."
}

#Find most recent zip file
$siteZipFile = gci -Path $sitePkgDir | where { $_ -like '*_Site.zip' } | Sort LastAccessTime -Descending | select -First 1 | select -ExpandProperty FullName

#Clean up old PKGS in the PKGS dir.
#Get-ChildItem -Path $sitePkgDir -Recurse -Exclude $siteZipFile | where { $_ -like '*_Site.zip' } | select -ExpandProperty FullName | ForEach-Object { Remove-Item $_ -Force }

#Get all the old sites and remove them.
gci -Path $siteAppDir -Directory -Recurse | Remove-Item -Force -Recurse

#unzip new sites to APPS folder
if ((Test-Path -Path $siteZipFile))
{
	if ((Test-Path -Path $siteAppDir))
	{
		Expand-Archive -Path $siteZipFile -DestinationPath $siteAppDir -Force
	}
	else { throw "$siteAppDir does not exist or access is denied."}
}
else { throw "$siteZipFile does not exist or access is denied."}
