param(
	[string]$userNameOverride
)

. "$PSScriptRoot\_setupfunctions.ps1" 

$global:userName = $userNameOverride
if (!$global:userName)
{
	$global:userName = $env:UserName
}


function CopyFixConfig([string] $sqlVersion, [string] $sqlPackagePath)
{
    #cant fix the SQL package if it isnt installed
    if (Test-Path $sqlPackagePath)
    {
        #replace the existing assembly binding with one that points to version 14 of ScriptDom
        Copy-Item "$PSScriptRoot\SupportFiles\sqlpackage.exe.$sqlVersion.config" "$sqlPackagePath\sqlpackage.exe.config" -Force
    }
    else
    {
            Write-Host "Path doesnt exist! --Skipping: $sqlPackagePath" -ForegroundColor Green
    }
}

function Install-FixForSQLPackage
{
	Write-Host "Installing Microsoft.SqlServer.TransactSql.ScriptDom 14 to fix SSDT."

	Push-Location
	try
	{
		$scriptDomFileName = "Microsoft.SqlServer.TransactSql.ScriptDom.dll"
		#try to find a new SQL Package scriptdom DLL

		$searchPaths = @(
			"C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\140",
			"C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin"
		)

		$foundDll = $null
		
		foreach ($path in $searchPaths)
		{
			$testFile = Join-Path $path $scriptDomFileName
			if (Test-Path $testFile)
			{
				Write-Host "Located $scriptDomFileName in $path" -ForegroundColor Yellow
				$foundDll = $testFile
				break;
			}
		}

		if ($null -eq $foundDll)
		{
			#create a temp folder to hold the dll download
			$tempFolder = New-RandomTemporaryDirectory
			Set-Location $tempFolder

			#use nuget to download the new dll
			& nuget install "Microsoft.SqlServer.TransactSql.ScriptDom" -Version 14.0.3811.1

			#make a string that points to the dll
			$foundDll = Join-Path $tempFolder "Microsoft.SqlServer.TransactSql.ScriptDom.14.0.3811.1\lib\net40\Microsoft.SqlServer.TransactSql.ScriptDom.dll"
		}

        #register the dll
        Install-AssemblyToGAC $foundDll

		Write-Host "Fixing v130 SQLPackage configurations..."
		CopyFixConfig 130 "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130"
        CopyFixConfig 130 "C:\Program Files (x86)\Microsoft SQL Server\130\DAC\bin"
	}
	finally
	{
		Pop-Location
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

	Install-FixForSQLPackage

	Write-Host "Fix for SQL Package Installed." -ForegroundColor Green
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}