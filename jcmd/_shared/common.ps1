function Write-ColorOutput
{
    [CmdletBinding()]
    Param(
         [Parameter(Mandatory=$true)][Object] $Object,
         [Parameter(Mandatory=$false)][ConsoleColor] $ForegroundColor,
         [Parameter(Mandatory=$false)][ConsoleColor] $BackgroundColor
    )

    # Save previous colors
    $previousForegroundColor = $host.UI.RawUI.ForegroundColor
    $previousBackgroundColor = $host.UI.RawUI.BackgroundColor

    # Set BackgroundColor if available
    if($BackgroundColor -ne $null)
    {
       $host.UI.RawUI.BackgroundColor = $BackgroundColor
    }

    # Set $ForegroundColor if available
    if($ForegroundColor -ne $null)
    {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    # Always write (if we want just a NewLine)
    if($null -eq $Object)
    {
        $Object = ""
    }

    Write-Output $Object

    # Restore previous colors
    $host.UI.RawUI.ForegroundColor = $previousForegroundColor
    $host.UI.RawUI.BackgroundColor = $previousBackgroundColor
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

function Ensure-IsPowershellMinVersion5()
{
	If($PSVersionTable.PSVersion.Major -lt 5) 
	{
		Write-Host "This script requires Powershell v5 or greater!"
		exit 1
	}
}

function Test-IsAdmin {
	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
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

function Ensure-VisualStudioNotRunning([string] $slnName="")
{
    $vsProcesses = Get-Process | Where-Object {($_.Name -eq "devenv") -and ($slnName -eq "" -or $_.mainWindowTItle.StartsWith("$slnName - Microsoft")) }
    if ($vsProcesses)
    {
        Write-Host "Please close all Visual Studio intances for j6 (All.sln) before running this script!"
        Exit 1
    }
}

function Ensure-IsJ6DevRootFolder()
{
	$isValid = $true;
	$path = Get-Location
	$sitePath = Join-Path $path "j6"
	$isValid = $isValid -and (Test-Path $sitePath -pathType container)
	$sitePath = Join-Path $path "customers"
	$isValid = $isValid -and (Test-Path $sitePath -pathType container)

#ensure this is a path with a j6 style /site/ folder
	if (!$isValid)
	{
		Throw "This is not a valid folder. Call this command from the root of a j6 source repository. Be sure to build first!"
		exit 1;
	}
}

function Ensure-J6SiteFolder()
{
	$isValid = $true;
	$path = Get-Location
	$sitePath = Join-Path $path "Site"
	$isValid = $isValid -and (Test-Path $sitePath -pathType container)

#ensure this is a path with a j6 style /site/ folder
	if (!$isValid)
	{
		Throw "This is not a valid folder. Call this command from the root of a j6 source repository. Be sure to build first!"
		exit 1;
	}
}


function Ensure-IsJ6Console()
{
	$isValid = $true;

    #todo: determine test for this 
    
	if (!$isValid)
	{
		Throw "This script must be executed from within a j6 console. Please run 'J6 Console' from the command line!"
		exit 1;
	}
}
