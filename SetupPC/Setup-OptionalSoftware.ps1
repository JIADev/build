. "$PSScriptRoot\_setupfunctions.ps1"


function Install-RecommendedTools()
{
	Write-Host "Ensuring Recommended Tools" -ForegroundColor Yellow

	Ensure-Package "agentransack"

	Ensure-Package "VisualStudioCode"
	Ensure-Package "vscode-powershell"
	Ensure-Package "vscode-csharp"
	Ensure-Package "vscode-mssql"
	Ensure-Package "vscode-markdownlint"
	Ensure-Package "vscode-jshint"
	#Ensure-Package "resharper"

	Ensure-Package "SourceTree"
}



try
{
	Write-Host "Beginning Software Setup..." -ForegroundColor Yellow

	#Main Code
	Ensure-Is64BitProcess
	Ensure-IsPowershellMinVersion4
	Ensure-IsAdmin

	if (Test-PendingReboot)
	{
		Write-Host "This machine has a pending required reboot. Please reboot and then re-run this script."
		Exit 1
	}

    Install-RecommendedTools

	#do this last, so that we know the path is ready to be processed
	#FYI, this is a critical step, otherwise the path is >2000 characters and 
	#powershell will not be able to find all the proper tools
	#specifically, this presents as "Cannot locate msbuild.exe"

	#Ensure-PathIsNotTooLong

	Write-Host "Software Setup Complete." -ForegroundColor Green
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}