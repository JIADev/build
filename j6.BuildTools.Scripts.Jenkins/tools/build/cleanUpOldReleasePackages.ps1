<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	11/9/2017 11:31
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	cleanUpOldReleasePackages.ps1
	===========================================================================
	.DESCRIPTION
		This script cleans up old release packages on the Jenkins server to avoid running out of space.
#>

$limit = (Get-Date).AddDays(-60)
$path = "E:\Jenkins\pkgs"

# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
