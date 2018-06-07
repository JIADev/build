<#	
	.NOTES
	===========================================================================
	 Created on:   	10/9/2017 09:13
	 Created by:   	jcollins
	 Organization: 	JIA Inc.
	 Filename:     	jenkinsDeployCreateSitePackage.ps1
	===========================================================================
	.DESCRIPTION
		This script is called by Jenkins to create the website release package to be deployed to the web servers.
#>

#Write-Host "$ENV:WORKSPACE" -foreground Green
param
(
	[Parameter(Mandatory = $true)]
	[string]$ps_scripts_dir,
	[string]$build_time
)
#
$deployPSScriptDir = "$ps_scripts_dir\deploy\web\"

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
		Write-Error -Message "Unalble to locate latest site package directory. Please check check the path: $latestSitePkgDest"
	}
	
	if (!(Test-Path -Path $archiveSitePkgDest))
	{
		Write-Error -Message "Unalble to locate archive site package directory. Please check check the path: $archiveSitePkgDest"
	}
	
	if (!(Test-Path -Path $releasePkgDest))
	{
		Write-Error -Message "Unalble to locate release package directory. Please check check the path: $releasePkgDest"
	}
	
}
else
{
	$j6_version = $ENV:j6_version.Replace(".", "-")
	if ((Test-Path -Path $releasePath -PathType container))
	{
		#Make temp Web deployment package working directory
		Write-Host "Make temp Web deployment package working directory"
		$siteDir = "$releasePath\Site"
		if (!(Test-Path -Path $siteDir -PathType container))
		{
			mkdir $siteDir
		}
		
		#Move previous Latest site and shared release to Archive
		Write-Host "Move previous Latest release to Archive"
		Move-Item -Path "$latestSitePkgDest\*.zip" -Destination $archiveSitePkgDest -Force
		
		#create DB dacpac folder structure for deployment.
		Write-Host "Copy dacpacs."
		
		if (!(Test-Path -Path "$releasePath\DacPacs"))
		{
			mkdir "$releasePath\DacPacs"
		}
		if (!(Test-Path -Path "$releasePath\SchemaUpdate"))
		{
			mkdir "$releasePath\SchemaUpdate"
		}

		#Copy the deployment.proj and deploy.target file to the RELEASE folder
		#gci -Path $workingDirectory | ? { $_.FullName -like "*deployment.proj*" -or $_.FullName -like "*deploy.target*"} | % { Copy-Item -Path $_.FullName -Destination $releasePath -Force }
		#gci $workingDirectory -Recurse -Include deployment.proj, deploy.targets | Copy-Item -Destination $releasePath
		
		#Copy the dacpac files to the appropriate folder.
		gci -Path "$releasePath" -Recurse | Where-Object { $_.FullName -like "*Assembly\*.dacpac" } | % { Copy-Item -Path $_.FullName -Destination "$releasePath\DacPacs" -Force }
		
		#start creating web deployment package. Delete everything except the portal zip files and the Shared folder
		Write-Host "start creating web deployment package. Delete everything except the portal zip files and the Shared folder"
		#gci -Path "$releasePath" -Recurse | select -ExpandProperty FullName | where { $_ -notlike '*MSDeploy*' -and $_ -notlike '*Shared*' -and $_ -notlike '*Site*' -and $_ -notlike '*DacPacs*' -and $_ -notlike '*SchemaUpdate*' -and $_ -notlike '*Bootstrap*' } | Remove-Item -Force -Recurse
		gci $releasePath -Recurse -Include Business.zip, Corporate.zip, Integration.zip, WebPWS.zip, version.txt | Copy-Item -Destination $releasePath
		Remove-Item $releasePath\MSDeploy -Force -Recurse
		
		#Extract portal files to a clean directory structure.
		Write-Host "Extract portal files to a clean directory structure."
#		$portalZips = gci -Path $releasePath -Recurse | where { $_ -like '*.zip' -and $_ -notlike 'Shared\*' -and $_ -notlike '*DacPacs*' -and $_ -notlike '*SchemaUpdate*' } | select -ExpandProperty FullName
		$portalZips = gci -Path $releasePath | where { $_ -like '*.zip' } | select -ExpandProperty FullName
#		$portalZips = gci -Path $releasePath -Include Business.zip, Corporate.zip, Integration.zip, WebPWS.zip | select -ExpandProperty FullName
		
		foreach ($portal in $portalZips)
		{
			#	Write-Host $portal
			$portalName = Split-Path -Path $portal -Leaf
			Write-Host "Extracting $portalName zip file."
			$sitePath = $releasePath + "\" + $portalName.Substring(0, $portalName.LastIndexOf('.'))
			Expand-Archive -Path "$portal" -DestinationPath "$sitePath" -Force
		}
		
		gci $releasePath -Recurse -Include Business.zip, Corporate.zip, Integration.zip, WebPWS.zip | Remove-Item -Force -Recurse
		
		#Copy site files to Site folder. *Maybe add the correct web.config*
		Write-Host "Copy site files to Site folder."
		#$sites = gci $releasePath | select -ExpandProperty FullName | where { $_ -notlike '*Shared*' -and $_ -notlike '*Site*' -and $_ -notlike '*DacPacs*' -and $_ -notlike '*SchemaUpdate*' -and $_ -notlike '*deploy.targets*' -and $_ -notlike '*deployment.proj*' }
		$sites = gci $releasePath | where { ($_ -like 'Business' -or $_ -like 'Corporate' -or $_ -like 'Integration' -or $_ -like 'WebPWS') -and $_.PSIsContainer -eq $true } | select -ExpandProperty FullName
		
		foreach ($site in $sites)
		{
			$sourcePath = gci -Path $site PackageTmp -Recurse -Directory | select -ExpandProperty FullName
			$destPath = $siteDir + "\" + (Split-Path -Path $site -Leaf)
			Copy-Item -Path $sourcePath -Recurse -Destination $destPath -Container
			
		}
		
		#*****Here is where we will add the logic to call the jenkinsDeployExpandWebConfig.ps1 file before we zip the Site folder.*****
		Write-Host "Injecting environment specific web.configs"
		$configScriptPath = "$deployPSScriptDir\jenkinsDeployWebCopyConfigs.ps1"
		Invoke-Command -ComputerName $env:COMPUTERNAME -FilePath "$configScriptPath" -ArgumentList $env:driver, $env:deploy_env, $siteDir
		
		$versionPath = "$siteDir\version.txt"
		$releaseZipPath | Out-File -FilePath $versionPath -Force
		
		#Zip site folder.
		Write-Host "Zip site folder."
		$zipFileSite = "$latestSitePkgDest\RELEASE_$($ENV:driver)-$j6_version-0-$($build_time)_$($ENV:BUILD_NUMBER)_Site"
		Compress-Archive -Path "$siteDir\*" -DestinationPath "$zipFileSite" -Force
		
		#Zip Shared folder.
		Write-Host "Zip Shared folder."
		$zipFileShared = "$latestSitePkgDest\RELEASE_$($ENV:driver)-$j6_version-0-$($build_time)_$($ENV:BUILD_NUMBER)_Shared"
		Compress-Archive -Path "$releasePath\Shared\*" -DestinationPath "$zipFileShared" -Force
		
		#Copy sql-settings.xml file to latestSite directory for deployment.
		if (Test-Path -Path "$workingDirectory\RELEASE\sql-settings.xml")
		{
			gci -Path "$workingDirectory\RELEASE\sql-settings.xml" -File | Copy-Item -Destination $latestSitePkgDest
		}
		else
		{
			Write-Error -Message "sql-settings.xml file does not exist in $workingDirectory"
		}
		
	}
	else
	{
		Write-Error -Message "Error: Release path ""$releasePath"" cannot be found or access is denied."
	}
	Write-Host "Release Package Created."
}



