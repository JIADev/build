<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	11/22/2017 10:59
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployExtractRTEOnServer.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$rteDrive,
	[string]$rteDir,
	[string]$rteBAKSDir,
	[string]$pkgDir
)

$sharedPkgDir = "$($rteDrive):\$pkgDir" #"R:\$($cust)_PKGS"
$sharedBackupDir = "$($rteDrive):\$rteBAKSDir" #"R:\$($cust)_BAKS"
$sharedAppDir = "$($rteDrive):\$rteDir\Shared" #"R:\$($cust)_APPS\Shared"
$timestamp = Get-Date -Format "yyyyMMddhhmmss"
$sharedBakZip = "$($sharedBackupDir)\shared_preDeploy_$($timestamp)_bak"

#Zip current shared folder and copy to pkgs/CUST/latest folder
if ((Test-Path -Path $sharedAppDir))
{
	Compress-Archive -Path $sharedAppDir -DestinationPath $sharedBakZip
}
else
{
	throw "$sharedAppDir does not exist or access is denied."
}

#Find most recent zip file
$sharedZipfile = gci -Path $sharedPkgDir | where { $_ -like '*_Shared.zip' } | Sort LastAccessTime -Descending | select -First 1 | select -ExpandProperty FullName

#Clean up old PKGS in the PKGS dir.
#Get-ChildItem -Path $sharedPkgDir -Recurse -Exclude $sharedZipfile | where { $_ -like '*_Shared.zip' } | select -ExpandProperty FullName | ForEach-Object { Remove-Item $_ -Force }

#Get all the old sites and remove them.
gci -Path $sharedAppDir -Recurse | Remove-Item -Force -Recurse

#create temp staging folder for RTE on the C: drive. to avoid unresolved 2095 rte deployment errors.
if (!(Test-Path -Path "C:\RTEstage"))
{
	$stgDir = "C:\RTEstage"
	mkdir $stgDir
}

Write-host "Expanding RTE zip to from $sharedZipfile to $stgDir"
#Expand new RTE to stg folder
Expand-Archive -Path $sharedZipfile -DestinationPath $stgDir

Write-Host "Copying from $stgDir\* to $sharedAppDir"
#copy new shared rte files from stg to RTE Apps
Copy-Item -Path $stgDir\* -Destination $sharedAppDir -Force -Recurse

#Clean up stage dir.
Remove-Item -Path $stgDir -Recurse -Force

