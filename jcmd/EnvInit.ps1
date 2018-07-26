<#
.SYNOPSIS
  Completely (re)initializes a j6 environment from a fresh dev folder.
.DESCRIPTION
  Cleans, builds, creates websites, and configures environment.

  1. Checks to ensure that visual studio is not running to avoid code loss/corruption.
  2. Remove any existing configured websites (with the specified name)
  3. jcmd revertall
  4. jcmd configure
  5. jcmd buildinit
  6. jcmd flush
  7. jcmd webapps

.PARAMETER CustomerCode
  Should be "CUST" followed by 4 digit customer number followed by market identifier.
  Example: CUST2097PL
.PARAMETER DatabaseName
  Specifies datebase name to be used for connecting to main j6 data.
.PARAMETER CacheDBId
  Specifies the Redis DB ID to use, should be different for each customer and/or SQL DB.
  Valid values typically are 1-16, but this can be changed in the Redis configuration.
.PARAMETER websiteName
  Overrides the folder name when building the website FQDN.

  Example: -Name "test"
  Result: Website will be named "www.test.local".
.PARAMETER netPipe
  Switch that enables net.pipe protocols and configuration.
.PARAMETER ignoreVS
  Allows this script to run when Visual Studio is open.

  Note: This should only be used when there are OTHER projects open in VS.
.EXAMPLE
  PS C:\> jcmd envinit CUST1002 CUST1002-DB 10 -netPipe
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

function ValidateEnv()
{
  if (($ignoreVS -eq $false) -and ([bool](Get-Process devenv -ea "silentlycontinue"|where {$_.mainWindowTItle.StartsWith('all - Microsoft')} )))
  {
    Throw "Please close all Visual Studio intances for j6 (All.sln) before running this script!"
  }
}

#build webapps args accounting for optional params
$websiteRemoveArgs = @{}
$websiteRemoveArgs.commandName = "WebApps"
$websiteRemoveArgs.name = $websiteName
$websiteRemoveArgs.remove=$true

$websiteArgs = @{}
$websiteArgs.commandName = "WebApps"
$websiteArgs.name = $websiteName
$websiteArgs.netPipe = $netPipe

$jcmdPath = "$PSScriptRoot\..\jcmd.ps1"

$commands = @()
$commands += @{name="Checking State"; command="ValidateEnv"; args=@()}
$commands += @{name="Remove Existing Web Apps"; command=$jcmdPath; args=$websiteRemoveArgs}
$commands += @{name="RevertAll"; command=$jcmdPath; args=@("RevertAll")}
$commands += @{name="Configure"; command=$jcmdPath; args=@("Configure","$CustomerCode","$DatabaseName", "$CacheDBId")}
$commands += @{name="Build"; command=$jcmdPath; args=@("BuildInit")}
$commands += @{name="Flush"; command=$jcmdPath; args=@("Flush","all")}
$commands += @{name="Create Web Apps"; command=$jcmdPath; args=$websiteArgs}

ExecuteCommandsWithStatus $commands "EnvInit"