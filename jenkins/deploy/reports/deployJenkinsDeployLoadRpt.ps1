<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/20/2017 13:25
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsDeployLoadRpt.ps1
	===========================================================================
	.DESCRIPTION
		This is the script for Jenkins to load reports to the new report server usinf ReportLoader.exe.  Will be creating a new solution that moves all reports to 'Report' folder 
		and then uses PS and SSRS proxy to load the reports, but it is unfinished.
#>

$workingDirectory = "$($ENV:WORKSPACE)"
#$workingDirectory = "C:\JCJenkins\workspace\1002\RELEASE"

#Make sure LoadReport.exe is present and assign to process variable.
if (-not (test-path "$workingDirectory\Shared\LoadReport.exe")) { throw "$workingDirectory\Shared\LoadReport.exe" }
$loadReport = "$workingDirectory\Shared\LoadReport.exe"


#Run ReportLoader.exe
#$process = Start-Process -FilePath "$loadReport" -WorkingDirectory "$workingDirectory" -PassThru -Wait
#Write-Host $process.StandardOutput
Write-Host "Currenty Directory: $PWD"
Write-Host "Working Directory: $workingDirectory"
Set-Location -Path $workingDirectory
& "$workingDirectory\Shared\LoadReport.exe"