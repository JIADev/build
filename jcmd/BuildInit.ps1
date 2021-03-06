<#
.SYNOPSIS
  Completely initializes and builds a j6 development folder.
.DESCRIPTION
  Completely initializes and builds a j6 development folder.

  1. Checks to ensure that visual studio is not running to avoid code loss/corruption.
  2. Clean up schema update folder
  3. j bootstrap
  4. j ensuredb
  5. j setup
  6. j patch
  7. j build (with hidden warnings)
  8. runs webpack on PWS (if needed)

.PARAMETER ignoreVS
  Allows this script to run when Visual Studio is open.

  Note: This should only be used when there are OTHER projects open in VS.
.EXAMPLE
  PS C:\> jcmd BuildInit
.NOTES
  Created by Richard Carruthers on 07/19/18
#>
param(
	[switch]$ignoreVS = $false
)
. "$PSScriptRoot\_shared\common.ps1"
. "$PSScriptRoot\_shared\jposhlib\Common-Process.ps1"

function ValidateEnv()
{
  if ($ignoreVS -eq $false)
  {
    $vsProcesses = Get-Process | Where-Object {($_.Name -eq "devenv") -and ($_.mainWindowTItle.StartsWith('all - Microsoft')) }
    if ($vsProcesses)
    {
      Throw "Please close all Visual Studio intances for j6 (All.sln) before running this script!"
    }
  }
}

function CheckWebpack()
{
  if (Test-Path ".\Site\WebPWS\WebPWS.csproj") {
    & "msbuild.exe" "Site\WebPWS\WebPWS.csproj" "/t:Webpack"
  }
}

function Remove-SchemaUpdate()
{
  if (Test-Path ".\SchemaUpdate\") {
    Remove-Item ".\SchemaUpdate\*.*" -Force -Recurse
  }
}


$commands = @()
$commands += @{name="Checking State"; command="ValidateEnv"; args=@()}
#$commands += @{name="j clean"; command="msbuild.exe"; args=@("/nologo","/t:clean","j6.proj")}
$commands += @{name="Remove Schema Update"; command="Remove-SchemaUpdate"; args=@()}
$commands += @{name="j bootstrap"; command="msbuild.exe"; args=@("/nologo","/t:bootstrap","j6.proj")}
$commands += @{name="j ensuredb"; command="msbuild.exe"; args=@("/nologo","/t:ensuredb","j6.proj")}
$commands += @{name="j setup"; command="msbuild.exe"; args=@("/nologo","/t:setup","j6.proj")}
$commands += @{name="j patch"; command="msbuild.exe"; args=@("/nologo","/t:patch","j6.proj")}
$commands += @{name="j build"; command="msbuild.exe"; args=@("/nologo","/t:build","j6.proj")}
$commands += @{name="Check Webpack"; command="CheckWebpack"; args=@()}

Ensure-IsPowershellMinVersion5
Ensure-IsJ6DevRootFolder
Ensure-IsJ6Console
Ensure-VisualStudioNotRunning "all"

ExecuteCommandsWithStatus $commands "BuildInit"