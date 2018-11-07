#
# 

#variables used to cache system state between calls
$global:localPackages = @{}
$global:localFeatures = @{}
$global:localInstalledApps = @{}
$global:localNpmPackages = @{}

function Ensure-IsJ6DevRootFolder()
{
	$isValid = $true;
	$isValid = $isValid -and (Test-Path "$path\Site" -pathType container)

#ensure this is a path with a j6 style /site/ folder
	if (!$isValid)
	{
		Throw "This is not a valid folder. Call this command from the root of a j6 source repository. Be sure to build first!"
		exit 1;
	}
}

function Test-J6NetworkConnected()
{
	return Test-Connection source.jenkon.com -count 1 -quiet
}

function Test-JenkonDomain()
{
	$domain=(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
	$domainName=(Get-WmiObject -Class Win32_ComputerSystem).Domain

	return $domain -and ($domainName -ieq "jenkon")
}


function Ensure-J6NetworkConnected()
{
	if (!(Test-J6NetworkConnected))
	{
		Write-Host "This script requires a connection to the Jenkon Network - please connect directly or through a VPN!"
		exit 1	
	}
}

function Test-NpmGlobalPackageInstalled([string] $package)
{
	if (!($global:localNpmPackages.Count -gt 0))
	{
		Write-Debug "Loading NPM Global Packages...."
		$global:localNpmPackages = npm list -g -depth 0 -parseable true | split-path -leaf | % {$_.ToLower()}
		Write-Debug "$($global:localNpmPackages.Count) NPM packages loaded."
	}
	
	Write-Debug "Checking for $package"
	$installed = $global:localNpmPackages -contains $package;
	Write-Debug "$package installed = $installed"
	return $installed;
}

function Test-AppInstalled([string] $app)
{
	if (!($global:localInstalledApps.Count -gt 0))
	{
		Write-Debug "Loading Installed Applications...."
		$global:localInstalledApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | % DisplayName
		Write-Debug "$($global:localInstalledApps.Count) applications loaded."
	}

	Write-Debug "Checking for $app"
	$installed = $global:localInstalledApps -contains $app;
	Write-Debug "$app installed = $installed"
	return $installed;
}

function Test-PackageInstalled([string] $package)
{
	if (!($global:localPackages.Count -gt 0))
	{
		Write-Debug "Loading Packages...."
		$global:localPackages = choco list -lo| % {($_ -split " ")[0].ToLower()}
		Write-Debug "$($global:localPackages.Count) packages loaded."
	}
	
	Write-Debug "Checking for $package"
	$installed = $global:localPackages -contains $package;
	Write-Debug "$package installed = $installed"
	return $installed;
}

function Test-FeatureInstalled([string] $feature)
{
	if (!($global:localFeatures.Count -gt 0))
	{
		Write-Debug "Loading Features...."
		$global:localFeatures = Get-WindowsOptionalFeature -online | Where {$_.State -eq "Enabled"} | ForEach {"$($_.FeatureName)"}
		Write-Debug "$($global:localFeatures.Count) features loaded."
	}
	
	Write-Debug "Checking for $feature"
	$installed = $global:localFeatures -contains $feature;
	Write-Debug "$feature installed = $installed"
	return $installed;
}

function Ensure-Package([string] $package)
{
	if (!(Test-PackageInstalled $package))
	{
		choco install $package -y --allow-empty-checksums

		Ensure-Reboot #check to see if this installation requires a reboot
		Refresh-CommandSessionPathVariable
	}
}

function Ensure-Feature([string] $feature)
{
	if (!(Test-FeatureInstalled $feature))
	{
		Write-Host -NoNewline "Enabling $feature...."
		$result = Enable-WindowsOptionalFeature -online -all -FeatureName $feature
		if ($result.Online)
		{
			Write-Host "Success."
	
			Ensure-Reboot #check to see if this installation requires a reboot
		}
		else
		{
			Write-Host "FAIL!" -ForegroundColor Red
		}
		
	}
}

function Ensure-Reboot()
{
	if (Test-PendingReboot)
	{
		Write-Host "THE SETUP SCRIPT REQUIRES A REBOOT AT THIS POINT!" -ForegroundColor Red
		Write-Host "Please reboot and re-run the script to resume from this point"
		Exit 0
	}
}


function Ensure-Is64BitProcess()
{
	if ([Environment]::Is64BitProcess -ne "True")
	{
		"You must use the 64 bit version of Powershell to run this script!"
		exit 1
	}
}

function Ensure-IsPowershellMinVersion4()
{
	If($PSVersionTable.PSVersion.Major -lt 4) 
	{
		Write-Host "This script requires Powershell v4 or greater!"
		exit 1
	}
}

function Ensure-IsAdmin()
{
	Ensure-ElevatedPermissions	
}

function Ensure-ElevatedPermissions()
{
If(!(Test-IsAdmin))
	{
		Write-Host "This script requires elevated permissions!"
		exit 1
	}
}


function Ensure-ExecutionPolicy()
{
	$policy = Get-ExecutionPolicy
	if ($policy -eq "Restricted")
	{
		Write-Host "Please unrestrict your PowerShell environment by executing this command:"
		Write-Host "Set-ExecutionPolicy AllSigned"

		exit 1
	}
}


function Test-IsAdmin {
	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}


function Install-AssemblyToGAC([string] $assemblyFileName)
{
	#Note that you should be running PowerShell as an Administrator
	[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")            
	$publish = New-Object System.EnterpriseServices.Internal.Publish            
	$publish.GacInstall($assemblyFileName)
}

function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}

function Ensure-DotNet462
{
	Write-Host "Ensuring DotNet 4.6.2."
	Ensure-MicrosoftDownload "https://www.microsoft.com/net/download/thank-you/net462?survey=false" "NDP462-KB3151802-Web.exe" ".net" "/passive /norestart"
}

function Ensure-Service([string] $service)
{
	Write-Host "Checking Service $service."
	$serviceObj = Get-Service $service

	if ($serviceObj.Status -ne "Running")
	{
		Write-Host "Starting Service $service."
		Start-Service $service
	}

	if ($serviceObj.StartType -ne "Automatic")
	{
		Write-Host "Setting Service $service to Automatic Start."
		Set-Service -Name $service -StartupType "Automatic"
	}
}

function Ensure-MicrosoftDownload([string] $downloadPage, [string] $fileName, [string] $installedName, [string] $launchParams)
{
	Write-Host "Ensuring $installedName"

	if (!(Test-AppInstalled $installedName))
	{
		$tempFolder = New-TemporaryDirectory $installedName
		$setupExe = Join-Path $tempFolder $fileName

		if (Test-Path $setupExe)
		{
			Write-Host "$installedName installer ($fileName) found on disk. --Skipping download!" -ForegroundColor Green
		}
		else
		{
			#get the download link from Microsoft
			Write-Host "Retrieving installer download link for $fileName from $downloadPage" -ForegroundColor Green
			$rep=Invoke-WebRequest $downloadPage -MaximumRedirection 0 -UseBasicParsing
			$downloadLink = $rep.Links | where {$_.href -like "*"+$fileName} |select -expand href 
			Write-Host "Link retrieved: $downloadLink" -ForegroundColor Green

			#get the installer from MS
			Write-Host "Downloading $fileName from $downloadLink"
			Invoke-WebRequest -Uri $downloadLink -OutFile $setupExe
		}

		Write-Host "Launching unattended installation of $installedName ..."		 
		Write-Host "$setupExe $launchParams"
		
		Start-Process $setupExe -ArgumentList $launchParams -Wait

		Ensure-Reboot #check to see if this installation requires a reboot
	}
	else
	{
		Write-Host "$installedName already installed! --Skipping" -ForegroundColor Green
	}
	
}

function Refresh-CommandSessionPathVariable()
{
	$env:Path = ([System.Environment]::GetEnvironmentVariable("Path","Machine").Trim() + ";" + [System.Environment]::GetEnvironmentVariable("Path","User").Trim()).Replace(";;",";");
}


#
# Common_SQL.ps1
#


function Expand-EnvironmentVariables($unexpanded) {
    $previous = ''
    $expanded = $unexpanded
    while($previous -ne $expanded) {
        $previous = $expanded       
        $expanded = [System.Environment]::ExpandEnvironmentVariables($previous)
    }
    return $expanded 
}

function Set-ExpandableEnvironmentVariable([string] $key, [string] $value, [bool] $userOnly = $false)
{
	if ($userOnly)
	{
		Set-ItemProperty HKCU:\Environment $key $value -Type ExpandString
	} else
	{
		Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' $key $value -Type ExpandString
	}
}

function Test-PathContainsFolder([string] $path, [string] $folder)
{
	$parts = $path.ToLower().Split(';');
	return $parts.Contains($folder.ToLower());
}


function Set-PermanentPath([string] $newPath)
{
	set-item -force -path "env:Path" -value $newPath;
	#[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine");
	
	Set-ExpandableEnvironmentVariable "Path" $newPath

	Send-EnvironmentChangeMessage
}

function Add-PermanentPathFolder([string] $newPath)
{
	$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine");
	if (!(Test-PathContainsFolder $machinePath $newPath))
	{
		$machinePath = $machinePath, $newPath -join ";"
		$machinePath = $machinePath -replace ";;",";"
		#[Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine");
		Set-ExpandableEnvironmentVariable "Path" $machinePath
	}
	$currentPath = $env:Path
	if (!(Test-PathContainsFolder $currentPath $newPath))
	{
		$currentPath = $currentPath, $newPath -join ";"
		$currentPath = $currentPath -replace ";;",";"
		#set-item -force -path "env:Path" -value $currentPath;	
		$env:Path = $currentPath
	}
	
	Send-EnvironmentChangeMessage
}

function Send-EnvironmentChangeMessage {
    # Broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon. 
    if (-not ('Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods' -as [type])) {
        Add-Type -Namespace Microsoft.PowerShell.Commands.PowerShellGet.Win32 `
                -Name NativeMethods `
                -MemberDefinition @'
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessageTimeout(
                        IntPtr hWnd,
                        uint Msg,
                        UIntPtr wParam,
                        string lParam,
                        uint fuFlags,
                        uint uTimeout,
                        out UIntPtr lpdwResult);
'@
    }

    $HWND_BROADCAST = [System.IntPtr]0xffff;
    $WM_SETTINGCHANGE = 0x1a;
    $result = [System.UIntPtr]::zero

    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms644952(v=vs.85).aspx
    $returnValue = [Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, 
                                                                                                        $WM_SETTINGCHANGE,
                                                                                                        [System.UIntPtr]::Zero, 
                                                                                                        'Environment',
                                                                                                        2, 
                                                                                                        5000,
                                                                                                        [ref]$result);
    # A non-zero result from SendMessageTimeout indicates success.
    if($returnValue) {
        Write-Host 'Successfully broadcasted the Environment variable changes.'
    } else {
        Write-Host 'Error in broadcasting the Environment variable changes.'
    }
}

function New-RandomTemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    $folder = New-Item -ItemType Directory -Path (Join-Path $parent $name)
	return $folder.FullName
}

function New-TemporaryDirectory ([string] $folderName)
{
    $parent = [System.IO.Path]::GetTempPath()
	$newFolder = Join-Path $parent $folderName
    if (!(Test-Path $newFolder))
	{
		$folder = New-Item -ItemType Directory -Path $newFolder
	}
	return $newFolder
}


<#
.SYNOPSIS
    Performs a SQL query and returns an array of PSObjects.
.NOTES
    Author: Jourdan Templeton - hello@jourdant.me
.LINK 
    https://blog.jourdant.me/post/simple-sql-in-powershell
#>
function Invoke-SqlCommand() {
    [cmdletbinding(DefaultParameterSetName="integrated")]Param (
        [Parameter(Mandatory=$true)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory=$true)][string]$Database,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Username,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Password,
        [Parameter(Mandatory=$false, ParameterSetName="integrated")][switch]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory=$true)][string]$Query,
		[Parameter(Mandatory=$false)][bool]$ReturnsRows=$true,
        [Parameter(Mandatory=$false)][int]$CommandTimeout=0
    )
    
    #build connection string
    $connstring = "Server=$Server; Database=$Database; "
    If ($PSCmdlet.ParameterSetName -eq "not_integrated") { $connstring += "User ID=$username; Password=$password;" }
    ElseIf ($PSCmdlet.ParameterSetName -eq "integrated") { $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;" }
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()
    
    #build query object
    $command = $connection.CreateCommand()
    $command.CommandTimeout = $CommandTimeout
    
    if ($ReturnsRows -eq $true)
	{
	    $command.CommandText = $Query
	
			#run query
		$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
		$dataset = New-Object System.Data.DataSet
		$adapter.Fill($dataset) | out-null
    
		#return the first collection of results or an empty array
		If ($dataset.Tables[0] -ne $null) {$table = $dataset.Tables[0]}
		ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }
	}    
	else
	{
		$commands = $Query -isplit "[\r\n]go[\r\n]"
		
		$commands.Length
		foreach ($cmd in $commands)
		{
			$command.CommandText = $cmd
			$command.ExecuteNonQuery()
		}
	}

    $connection.Close()
    if ($ReturnsRows -eq $true) { return $table }
	else { return $null }
}
