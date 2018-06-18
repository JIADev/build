<#	
	.NOTES
	===========================================================================
	 Created with: 	Notepad ++
	 Created on:   	06/12/2018
	 Created by:   	rcarruthers
	 Organization: 	
	 Filename:     	ensurePackageFoldersExist.ps1
	===========================================================================
	.DESCRIPTION
		Checks the e:\jenkins folder for the existence of the required package folders for this build, and creates
		them if necessary.
#>

# -- for local testing
#$packageRootPath = "c:\temp\pkgs"
#$workingDirectory = "c:\temp\testjenkins"

# -- build server
$packageRootPath = "E:\Jenkins\pkgs"
$workingDirectory = "$($ENV:WORKSPACE)"

$buildName = Split-Path $workingDirectory -Leaf

Write-Host "Ensuring Package Folders for '$buildName'" -foreground Green

$buildPackagePath = Join-Path $packageRootPath $buildName

$archivePath = Join-Path $buildPackagePath "ArchiveSite"
$latestPath = Join-Path $buildPackagePath "LatestSite"
$releasePath = Join-Path $buildPackagePath "ReleasePkg"
$stagingPath = Join-Path $buildPackagePath "Staging"

if (!(Test-Path $archivePath)) { New-Item -ItemType Directory -Force -Path $archivePath | Out-Null }
if (!(Test-Path $latestPath)) { New-Item -ItemType Directory -Force -Path $latestPath | Out-Null }
if (!(Test-Path $releasePath)) { New-Item -ItemType Directory -Force -Path $releasePath | Out-Null }
if (!(Test-Path $stagingPath)) { New-Item -ItemType Directory -Force -Path $stagingPath | Out-Null }
