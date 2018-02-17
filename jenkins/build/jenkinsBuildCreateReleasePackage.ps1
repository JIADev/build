<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	12/7/2017 10:39
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsBuildCreateReleasePackage.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$workingDirectory = "$($ENV:WORKSPACE)"
Write-Host "Working Directory is $workingDirectory" -foreground Green
$releasePath = "$workingDirectory\RELEASE"
Write-Host "Release Path is $releasePath" -foreground Green
$unprotectedReleasePath = "$workingDirectory\RELEASE-UNPROTECTED"
Write-Host "Unprotected Release path is $unprotectedReleasePath" -foreground Green
$latestSitePkgDest = "$($ENV:pkgs_dir)\$($ENV:driver)\LatestSite"
Write-Host "Latest site package directory is $latestSitePkgDest" -foreground Green
$archiveSitePkgDest = "$($ENV:pkgs_dir)\$($ENV:driver)\ArchiveSite"
Write-Host "Archive site directory is $archiveSitePkgDest" -foreground Green
$releasePkgDest = "$($ENV:pkgs_dir)\$($ENV:driver)\ReleasePkg"
Write-Host "Release package destination is $releasePkgDest" -foreground Green
$protect = "$($ENV:protect)"
Write-Host "Protection is set to $protect" -foreground Green

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
	$j6_version = $ENV:j6_version.Replace(".", "-")
	if ($protect = $false)
	{
		Write-Host "Protection is set to False."
		
		if ((Test-Path -Path "$unprotectedReleasePath" -PathType container))
		{
			
			#Zip RELEASE-UNPROTECTED folder and copy to pkgs/CUST/latest folder
			$unprotectedReleaseZipPath = "$releasePkgDest\$($ENV:BUILD_NUMBER)\RELEASE_$($ENV:driver)-$j6_version-0-$($ENV:BUILD_TIMESTAMP)_UNPROTECTED_$($ENV:BUILD_NUMBER)"
			if (!(Test-Path -Path $unprotectedReleaseZipPath))
			{
				mkdir $unprotectedReleaseZipPath
			}
			Compress-Archive -Path "$unprotectedReleasePath\*" -DestinationPath "$unprotectedReleaseZipPath"
		}
	}
	elseif ($protect = $true)
	{
		Write-Host "Protection is set to True."
		
		if ((Test-Path -Path $releasePath -PathType container))
		{
			#Zip RELEASE folder and copy to pkgs/artifacts folder
			Write-Host "Zip RELEASE folder and copy to pkgs/artifacts folder"
			$releaseZipPath = "$releasePkgDest\$($ENV:BUILD_NUMBER)\RELEASE_$($ENV:driver)-$j6_version-0-$($ENV:BUILD_TIMESTAMP)_$($ENV:BUILD_NUMBER)"
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
	Write-Host "Release Package Created."
}