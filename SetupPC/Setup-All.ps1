param(
	[switch]$recommendedTools = $false,
	[switch]$VS2015 = $false,
	[switch]$VS2017 = $false,
	[string]$userNameOverride
)

try
{
	#Main Code
	& "$PSScriptRoot\Setup-Database.ps1"
	if ($LASTEXITCODE)
	{
		Write-Host "Setup-Database did not exit properly - Exit Code = $LASTEXITCODE" -ForegroundColor Red
		Exit 1
	}

	& "$PSScriptRoot\Setup-Software.ps1" $recommendedTools $VS2015 $VS2017
	if ($LASTEXITCODE)
	{
		Write-Host "Setup-Software did not exit properly - Exit Code = $LASTEXITCODE" -ForegroundColor Red
		Exit 1
	}

	& "$PSScriptRoot\Setup-BuildTools.ps1" $userNameOverride
	if ($LASTEXITCODE)
	{
		Write-Host "Setup-BuildTools did not exit properly - Exit Code = $LASTEXITCODE" -ForegroundColor Red
		Exit 1
	}

	Write-Host "Everything is installed!" -ForegroundColor Green

	Write-Host "YOU MUST REBOOT TO COMPLETE SOME INSTALLATIONS!" -ForegroundColor Yellow
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}