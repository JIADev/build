. "$PSScriptRoot\_setupfunctions.ps1"

function Ensure-SQLCLREnabled
{
	Write-Host "Enabling CLR on database..."		 
	#intentionally spread across three lines
	$queryCommand = "
	exec sp_configure 'clr enabled', 1
	reconfigure
	"
	Invoke-SqlCommand -Serverinstance "localhost" -Database "master" -Query $queryCommand 
}

function Ensure-SQLCLRRemoveStrict
{
	Write-Host "Disabling CLR strict security on database..." -ForegroundColor Yellow
	#intentionally spread across three lines
	$queryCommand = "
	sp_configure 'show advanced options', 1
	reconfigure
	exec sp_configure 'clr strict security', 0
	reconfigure
	"
	Invoke-SqlCommand -Serverinstance "localhost" -Database "master" -Query $queryCommand 
}

function Test-LocalSQLConnection
{
	try
	{
		#intentionally spread across three lines
		$queryCommand = "SELECT @@VERSION AS 'SQL Server Version'"
		$null = Invoke-SqlCommand -Serverinstance "localhost" -Database "master" -Query $queryCommand 
		return $true
	}
	catch
	{
		return $false
	}
}


function Ensure-SQLUserIsAdmin
{
	$user = $env:UserName
	if ($user -notlike "*\*")
	{
		$user = "jenkon\"+$env:UserName
	}

	Write-Host "Adding $user as SQL SysAdmin..." -ForegroundColor Yellow

	#intentionally spread across three lines
	$queryCommand = "
	EXEC sp_grantlogin '$user'
	EXEC sp_addsrvrolemember '$user','sysadmin'
	"
	Invoke-SqlCommand -Serverinstance "localhost" -Database "master" -Query $queryCommand
}

try
{
	Write-Host "Beginning Database Setup..." -ForegroundColor Yellow


	#Main Code
	Ensure-Is64BitProcess
	Ensure-IsPowershellMinVersion4
	Ensure-IsAdmin

	if (Test-PendingReboot)
	{
		Write-Host "This machine has a pending required reboot. Please reboot and then re-run this script."
		Exit 1
	}

	Ensure-SQLCLREnabled
	Ensure-SQLCLRRemoveStrict
	Ensure-SQLUserIsAdmin

	Write-Host "Database Setup Complete." -ForegroundColor Green
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}