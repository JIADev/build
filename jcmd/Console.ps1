<#
.SYNOPSIS
  Starts a j6 development console
.DESCRIPTION
  Starts a j6 development console
.EXAMPLE
  PS C:\> jcmd console
.NOTES
  Created by Richard Carruthers on 10/02/18
#>

. "$PSScriptRoot\_Shared\common.ps1"

# -- MAIN CODE SECTION --
Ensure-IsPowershellMinVersion4
Ensure-IsJ6DevRootFolder

#set-consoleicon ([string](join-path (split-path (gcm j6.ps1).Definition) "Jenkon.ico"))

# Import-Module "$PSScriptRoot\..\scripts\core.ps1" -Function * -force -Global -Verbose
# Import-Module "$PSScriptRoot\..\scripts\build.ps1" -Function "j" -force -Global -Verbose
# Import-Module "$PSScriptRoot\..\scripts\sql-utils.ps1" -Function * -force -Global -Verbose

Import-Module "c:\dev\build\scripts\core.psm1" -force -Global -WarningAction silentlyContinue
Import-Module "c:\dev\build\scripts\build.psm1" -force -Global -WarningAction silentlyContinue
Import-Module "c:\dev\build\scripts\sql-utils.psm1" -force -Global -WarningAction silentlyContinue
Import-Module "c:\dev\build\scripts\powershell_prompt.psm1" -force -Global -WarningAction silentlyContinue

## load env variables for visual studio
## LOAD VS variables

function load-vcvars {
	param(
		$vsver = "11.0",
		$vscpu = "",
		$vsfolder = "Microsoft Visual Studio {0}\VC",
		$vsparent = "Program Files{0}",
		$vsdrive = "C:\",
		$vsargs = "x86"
	)
	$vsfolder = ($vsfolder -f $vsver)
	$vsparent = ($vsparent -f $vscpu)
	$vs = join-path (join-path $vsdrive $vsparent) $vsfolder
  $vc = join-path $vs "\vcvarsall.bat"
	if(test-path $vc) {
		#Set environment variables for Visual Studio Command Prompt
		pushd $vs
		cmd /c "vcvarsall.bat&set" |
			foreach {
			  if ($_ -match "=") {
				$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
			  }
			}
		popd
		write-host ("`nVisual Studio {0} Command Prompt variables set." -f $vsver) -ForegroundColor Cyan
	}
	if($vsver = "14.0")
	{
		$env:Path += (";{0}{1}\MSBuild\{2}\bin;{0}{1}\{3}" -f $vsdrive, $vsparent, $vsver, $vsfolder)
	}
}
function load-visualstudio {
	param($vsver = "11.0")
	[System.IO.DriveInfo]::GetDrives() | ?{ $_.DriveType -eq "Fixed" } | %{
		$drive = $_.Name
		""," (x86)" | %{ load-vcvars -vsver $vsver -vscpu $_ -vsdrive $drive }
	}
}
function load-vs2015 { load-visualstudio -vsver "14.0" }
function load-vs2012 { load-visualstudio -vsver "11.0" }
function load-vs2010 { load-visualstudio -vsver "10.0" }
function load-vs2008 { load-visualstudio -vsver "9.0" }
function load-vs2005 { load-visualstudio -vsver "8" }

if (-not (Test-Path env:VisualStudioVersion))
{ 
  if ($args -contains "-2005") { load-vs2005 }
  elseif ($args -contains "-2008") { load-vs2008 }
  elseif ($args -contains "-2010") { load-vs2010 }
  elseif ($args -contains "-2015") { load-vs2015 }
  else { load-vs2012 }
  "Console Version loaded: $((Get-ChildItem Env:VisualStudioVersion).Value)"
}
else
{
  "Console Visual Studio Version was already loaded: $((Get-ChildItem Env:VisualStudioVersion).Value)"
}


$sql_settings = $null
& {
  $sql_settings =  get-sqlsettings
  $sql_settings.settings.sql | fl
}
