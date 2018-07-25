<#
.SYNOPSIS
  Completely initializes and builds a j6 development folder.
.DESCRIPTION
  Completely initializes and builds a j6 development folder.

  1. Checks to ensure that visual studio is not running to avoid code loss/corruption.
  2. j clean
  3. Clean up schema update folder
  4. j bootstrap
  5. j ensuredb
  6. j setup
  7. j patch
  8. j build (with hidden warnings)
  9. runs webpack on PWS (if needed)

.PARAMETER ignoreVS
  Allows this script to run when Visual Studio is open.

  Note: This should only be used when there are OTHER projects open in VS.
.EXAMPLE
  PS C:\> jcmd BuildInit
.NOTES
  Created by Richard Carruthers on 07/19/18
#>
param(
	[Parameter(Mandatory=$true)][string]$CustomerCode,
	[Parameter(Mandatory=$true)][string]$DatabaseName,
	[Parameter(Mandatory=$true)][int]$CacheDBId,
  [string]$websiteName = "",
  [switch]$netPipe = $false,
  [switch]$ignoreVS = $false
)

. "$PSScriptRoot\_shared\jposhlib\Common-Process.ps1"

$statusActivity = "BuildInit"
function ValidateEnv()
{
  if (($ignoreVS -eq $false) -and ([bool](Get-Process devenv -ea "silentlycontinue"|where {$_.mainWindowTItle.StartsWith('all - Microsoft')} )))
  {
    Throw "Please close all Visual Studio intances for j6 (All.sln) before running this script!"
  }
}

#build webapps args accounting for optional params
$websiteArgs = @()
$websiteArgs+= "WebApps"
if ($websiteName)
{
  $websiteArgs+= "-name"
  $websiteArgs+= $websiteName
}
if ($netPipe)
{
  $websiteArgs+= "-netPipe"
}
$websiteArgs+="-updateDb"

$commands = @()
$commands += @{name="Checking State"; command="ValidateEnv"; args=@()}
$commands += @{name="Remove Existing Web Apps"; command="$PSScriptRoot\..\jcmd.ps1"; args=@("WebApps","-remove")}
$commands += @{name="RevertAll"; command="$PSScriptRoot\..\jcmd.ps1"; args=@("RevertAll")}
$commands += @{name="Configure"; command="$PSScriptRoot\..\jcmd.ps1"; args=@("Configure","$CustomerCode","$DatabaseName", "$CacheDBId")}
$commands += @{name="Build"; command="$PSScriptRoot\..\jcmd.ps1"; args=@("BuildInit")}
$commands += @{name="Flush"; command="$PSScriptRoot\..\jcmd.ps1"; args=@("Flush","all")}
$commands += @{name="Create Web Apps"; command="$PSScriptRoot\..\jcmd.ps1"; args=$websiteArgs}


ExecuteCommandsWithStatus $commands

