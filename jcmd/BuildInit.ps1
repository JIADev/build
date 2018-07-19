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
	[switch]$ignoreVS = $false
)

$statusActivity = "BuildInit"
$oldtitle = $host.ui.RawUI.WindowTitle

function UpdateStatus([int] $step, [int] $totalSteps, [string] $stepName)
{
  # [int]$pct = [math]::Round(($step / $totalSteps) * 100)
  # [int]$barLen = 20
  # [int]$barCompleted = [math]::Round(($barLen * ($pct/100)))
  # [int]$barRemaining = $barLen - $barCompleted
  # $progressBarString = ("#" * $barCompleted) + ("-" * $barRemaining)

  # $host.ui.RawUI.WindowTitle = "$statusActivity - $pct% Complete [$progressBarString] : $stepName"

  $host.ui.RawUI.WindowTitle = "$statusActivity - Step $step of $totalSteps : $stepName"
}

function ValidateEnv()
{
  if (($ignoreVS -eq $false) -and ([bool](Get-Process devenv -ea "silentlycontinue"|where {$_.mainWindowTItle.StartsWith('all - Microsoft')} )))
  {
    Throw "Please close all Visual Studio intances for j6 (All.sln) before running this script!"
  }
}

function CheckWebpack()
{
  if (Test-Path ".\Site\WebPWS\WebPWS.csproj") {
    & "msbuild.exe" "Site\WebPWS\WebPWS.csproj","/t:Webpack"
  }
}

$commands = @()
$commands += @{name="Checking State"; command="ValidateEnv"; args=@()}
$commands += @{name="j clean"; command="msbuild.exe"; args=@("/nologo","/t:clean","j6.proj")}
$commands += @{name="Remove Schema Update"; command="Remove-Item"; args=@(".\SchemaUpdate\*.*")}
$commands += @{name="j bootstrap"; command="msbuild.exe"; args=@("/nologo","/t:bootstrap","j6.proj")}
$commands += @{name="j ensuredb"; command="msbuild.exe"; args=@("/nologo","/t:ensuredb","j6.proj")}
$commands += @{name="j setup"; command="msbuild.exe"; args=@("/nologo","/t:setup","j6.proj")}
$commands += @{name="j patch"; command="msbuild.exe"; args=@("/nologo","/t:patch","j6.proj")}
$commands += @{name="j build"; command="msbuild.exe"; args=@("/nologo","/t:build","j6.proj")}
$commands += @{name="Check Webpack"; command="CheckWebpack"}

$RebuildStartTime = Get-Date -format HH:mm:ss

$totalSteps = $commands.Count
$step = 0

try {
  for ($i = 0; $i -lt $totalSteps; $i++) {

    $commandKey = $commands[$i].name
    $command = $commands[$i].command
    $args = $commands[$i].args

    UpdateStatus $($i+1) $totalSteps $commandKey

    try {
      #$command += '; return $LASTEXITCODE;'
      #$exitCode = Invoke-Expression $command -OutBuffer

      & $command $args

      $exitCode = $LASTEXITCODE
      if ($exitCode -gt 0)
      {
        Write-Output "The command '$commandKey' exited with error code: $exitCode"
        Exit $exitCode
      }
    }
    catch {
      $ec = $LASTEXITCODE
      Write-Output "The command '$commandKey' exited with error code: $ec"
      Write-Output $_.Exception|format-list -force
      if ($ec -eq 0) {$ec = 1} #dont exit with 0 code if there was a problem
      Exit $ec
    }
  }
}
finally {
  $host.ui.RawUI.WindowTitle = $oldtitle

  "------------------------------------------------------------"
  "Start Rebuild Time: $RebuildStartTime" 
  "End Rebuild Time: $RebuildEndTime" 
  "Elapsed Branch Rebuild Time: $Difference" 
  "------------------------------------------------------------"
}

