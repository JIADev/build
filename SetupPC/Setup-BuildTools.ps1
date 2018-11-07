param(
	[string]$userNameOverride
)

. "$PSScriptRoot\_setupfunctions.ps1"

$global:userName = $userNameOverride
if (!$global:userName)
{
	$global:userName = $env:UserName
}


function Ensure-MercurialSettings()
{
	Write-Host "Ensuring Mercurial INI Setup" -ForegroundColor Yellow
	$target = Join-Path -path $env:USERPROFILE -ChildPath "Mercurial.ini"
	#if mercurial ini already exists, ask the user if they want to reset it?
	if (Test-Path $target)
	{
		$prompt = "Mercurial Ini file already exists, overwrite (y/N)"
		$answer = Read-Host $prompt

		if ($answer -ne "y")
		{
			return;
		}
		Rename-Item -Path $target "$target.$(((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ")).old"
	}

	Ensure-ProperUserName

	$template = "$PSScriptRoot\SupportFiles\Mercurial.ini"

	$content = [Io.File]::ReadAllText($template)
	
	$content = $content.Replace("[USERNAME]",$global:userName);

	[Io.File]::WriteAllText($target, $content);
}

function Ensure-DevFolder()
{
	Write-Host "Ensuring C:\Dev folder" 
	#only makes the folder if it doesnt exist, no output
	$null = New-Item -ItemType Directory -Force -Path C:\Dev | Out-Null
}

function Ensure-BuildToolsFolder()
{
	Write-Host "Ensuring Build Repository" -ForegroundColor Yellow
	Push-Location
	try
	{
		if (!(Test-Path "c:\Dev\Build"))
		{
			cd C:\Dev
			& git clone https://github.com/JIADev/build.git build
		}
	}
	finally
	{
		Pop-Location
	}
	Add-PermanentPathFolder "c:\Dev\Build"
}

function Enable-NugetPackageRestore
{
	Write-Host "Setting EnableNuGetPackageRestore Evironment Variable"
	[Environment]::SetEnvironmentVariable("EnableNuGetPackageRestore", "TRUE", "Machine");

	Write-Host "Copying Nuget Config File"
	Copy-Item "$PSScriptRoot\SupportFiles\NuGet.Config" "$env:AppData\NuGet\NuGet.Config" -Force
}

function Install-FixForSQLPackage
{
	Write-Host "Installing Microsoft.SqlServer.TransactSql.ScriptDom 14 to fix SSDT."

	Push-Location
	try
	{
		$sqlPackagePath = "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"

		#cant fix the SQL package if it isnt installed
		if (Test-Path $sqlPackagePath)
		{
			#create a temp folder to hold the dll download
			$tempFolder = New-RandomTemporaryDirectory
			Set-Location $tempFolder

			#use nuget to download the new dll
			& nuget install "Microsoft.SqlServer.TransactSql.ScriptDom" -Version 14.0.3811.1

			#make a string that points to the dll
			$dllFile = Join-Path $tempFolder "Microsoft.SqlServer.TransactSql.ScriptDom.14.0.3811.1\lib\net40\Microsoft.SqlServer.TransactSql.ScriptDom.dll"

			#register the dll
			Install-AssemblyToGAC $dllFile 

			#replace the existing assembly binding with one that points to version 14 of ScriptDom
			Copy-Item "$PSScriptRoot\SupportFiles\sqlpackage.exe.config" "$sqlPackagePath\sqlpackage.exe.config" -Force
		}
		else
		{
				Write-Host "Cannot find SQLPackage.EXE -- Skipping fix" -ForegroundColor Green
		}
	}
	finally
	{
		Pop-Location
	}
}


function Ensure-ProperUserName()
{
	if (Test-JenkonDomain -or $userNameOverride)
	{
		return
	}
	else
	{
		$promptUserName=Read-Host "Enter Jenkon Username (without domain)"
		$promptUserNameConfirm=Read-Host "Confirm Jenkon Username"

		if ($promptUserName -ne $promptUserNameConfirm)
		{
			Write-Host "User names did not match!" -ForegroundColor Red
			EXIT 1
		}

		$global:userName = $promptUserName
		
		#set the override so that if this function is called a second time, it will not re-prompt
		$userNameOverride = $global:userName
	}
}


try
{
	Write-Host "Beginning Setup of Build Tools..." -ForegroundColor Yellow

	#Main Code
	Ensure-Is64BitProcess
	Ensure-IsPowershellMinVersion4
	Ensure-IsAdmin

	if (Test-PendingReboot)
	{
		Write-Host "This machine has a pending required reboot. Please reboot and then re-run this script."
		Exit 1
	}

	Ensure-J6NetworkConnected


	Ensure-MercurialSettings

	Ensure-DevFolder
	Ensure-BuildToolsFolder
	Enable-NugetPackageRestore
	#Install-FixForSQLPackage

	Write-Host "Build Tools Setup Complete." -ForegroundColor Green
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}