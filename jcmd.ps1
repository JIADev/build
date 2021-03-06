<#
.SYNOPSIS
  jcmd offers a consistent way to organize, access, and document scripts 
  created by Jenkon developers. 
.DESCRIPTION
  jcmd is a simple powershell script that looks for matching command scripts
  in the .\jcmd folder and forwards any arguments passed to that script.

  Commands can be in the root of the .\jcmd folder, or they can be in a 
  subfolder with a matching name such as .\jcmd\revertall\revertall.ps1
    
  In this way, script folders may also contain other files that are 
  referenced by the script such as .ps1 include files, 
  executables, or config files.

  Common include scripts and tools referenced by multiple command scripts may
  be placed beneath the .\jcmd\_shared folder.
.EXAMPLE
  PS C:\> jcmd listcommands

  Shows a list of all available commands.
.EXAMPLE
  PS C:\> jcmd help listcommands

  Shows the help information for "ListCommands"
.EXAMPLE
  PS C:\> jcmd revertall -LongPathCheck

  Executes the RevertAll command with the -LongPathCheck argument.
  Note: This is the same as executing .\jcmd\revertall.ps1 -LongPathCheck 
  (assuming the current folder is the jcmd.ps1 folder)
#>
Param(
  [string]$commandName
)
Set-PSDebug -strict
Set-StrictMode -Version latest

if(!($commandName))
{
    Get-Help -Detailed $MyInvocation.MyCommand.Name
    $commandName = "ListCommands"
}

$params = $MyInvocation.UnboundArguments

#the cmd folder is where jcmd expects to find all of the command scripts
#either in .\[commandName].ps1 files or .\[commandName]\[commandName].ps1
$cmdFolder = Join-Path $PSScriptRoot "jcmd";


#look for the command as a ps1 file in the command folder
$cmdScript = Join-Path $cmdFolder "$commandName.ps1";
if (!(Test-Path $cmdScript))
{
  #look for the command in a folder with the same name (ie .\revertall\revertall.ps1)
  $cmdFolder = Join-Path $cmdFolder $commandName;
  $cmdScript = Join-Path $cmdFolder "$commandName.ps1";
  if (!(Test-Path $cmdScript))
  {
    #if we didn't find the command then there is nothing to do but report the error 
    #and fail with an exit code
    Write-Host "ERROR: jcmd command '$commandName' not found!" -ForegroundColor Red
    exit 1
  }
}

#default exit code when exceptions occur
$exitCode = -100
try {
  #run the command
  & $cmdScript @params
  #if we get to this point, we are not exiting with a 0
  #so see if we can get a better exit code
  $success = $?
  if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

  #check the result, if success, exit with exitcode 0
  if ($success) { EXIT 0 }
}
catch {
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $MyInvocation.MyCommand

  Write-Host "$FailedItem failed with message: $ErrorMessage" -ForegroundColor Red
  EXIT $exitCode
}

if ($exitCode)
{
  EXIT $exitCode
}

#if we cant find a better code, just exit with 1
EXIT 1
