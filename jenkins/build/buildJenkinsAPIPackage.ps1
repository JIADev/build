<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.153
	 Created on:   	9/12/2018 08:57
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	buildJenkinsAPIPackage.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


$workingDirectory = "$($ENV:WORKSPACE)"
Write-Host "Working Directory is $workingDirectory" -foreground Green
$releasePath = "$workingDirectory\RELEASE"
Write-Host "Release Path is $releasePath" -foreground Green
$latestSitePkgDest = "$($ENV:pkgs_dir)\$($ENV:JOB_NAME)\LatestSite"
Write-Host "Latest site package directory is $latestSitePkgDest" -foreground Green
$archiveSitePkgDest = "$($ENV:pkgs_dir)\$($ENV:JOB_NAME)\ArchiveSite"
Write-Host "Archive site directory is $archiveSitePkgDest" -foreground Green
$releasePkgDest = "$($ENV:pkgs_dir)\$($ENV:JOB_NAME)\ReleasePkg"
Write-Host "Release package destination is $releasePkgDest" -foreground Green

if (!(Test-Path -Path $workingDirectory))
{
	Write-Error -Message "Unable to find working directory. Please check path: $workingDirectory"
	
	if (!(Test-Path -Path $latestSitePkgDest))
	{
		Write-Error -Message "Unable to locate latest site package directory. Please check check the path: $latestSitePkgDest"
	}
	
	if (!(Test-Path -Path $archiveSitePkgDest))
	{
		Write-Error -Message "Unable to locate archive site package directory. Please check check the path: $archiveSitePkgDest"
	}
	
	if (!(Test-Path -Path $releasePkgDest))
	{
		Write-Error -Message "Unable to locate release package directory. Please check check the path: $releasePkgDest"
	}
	
}
else
{
	
	if ((Test-Path -Path $releasePath -PathType container))
	{
		#Zip RELEASE folder and copy to pkgs/artifacts folder
		Write-Host "Zip RELEASE folder and copy to pkgs/artifacts folder"
		$releaseZipPath = "$releasePkgDest\$($ENV:BUILD_NUMBER)\RELEASE_$($ENV:JOB_NAME)-Build$($ENV:BUILD_NUMBER)_$($ENV:BUILD_TIMESTAMP)"
		if (!(Test-Path -Path $releaseZipPath))
		{
			mkdir $releaseZipPath
		}
		Compress-Archive -path "$releasePath\*" -DestinationPath "$releaseZipPath"
		
	}
	else
	{
		Write-Error -Message "Error: Release path ""$releasePath"" cannot be found or access is denied."
	}
}