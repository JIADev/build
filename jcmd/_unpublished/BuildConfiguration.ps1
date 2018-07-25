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
  [Parameter(Mandatory=$true)][string]$configuration,
	[switch]$ignoreVS = $false
)

$statusActivity = "BuildConfiguration"
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

function SetConfiguration()
{
  & msbuild /t:Configure /p:Configuration=$configuration j6.proj | Out-Null
}

function ResetConfiguration()
{
  & msbuild /t:Configure /p:Configuration=$configuration j6.proj | Out-Null
}

$commands = @()
$commands += @{name="Changing Configuration"; command="SetConfiguration"; args=@()}
$commands += @{name="j BuildAll $configuration"; command="msbuild.exe"; args=@("/nologo","/t:buildall","j6.proj")}

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
  ResetConfiguration
  $host.ui.RawUI.WindowTitle = $oldtitle

  "------------------------------------------------------------"
  "Start Rebuild Time: $RebuildStartTime" 
  "End Rebuild Time: $RebuildEndTime" 
  "Elapsed Branch Rebuild Time: $Difference" 
  "------------------------------------------------------------"
}

