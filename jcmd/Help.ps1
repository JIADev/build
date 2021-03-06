<#
.SYNOPSIS
  Displays the help associated with jcmd scripts.
.DESCRIPTION
  Every jcmd command script should contain standard powershell help information
  such as SYNOPSIS, DESCRIPTION, EXAMPLES, INPUTS, OUTPUTS, and NOTES.
.EXAMPLE
  PS C:\dev\project_folder>jcmd help forwardchangecheck
.NOTES
#>
param(
    [string]$helpCommand
)

. "$PSScriptRoot\_Shared\common.ps1"

$cmdFolder = $PSScriptRoot;


#look for the command as a ps1 file in the command folder
$cmdScript = Join-Path $cmdFolder "$helpCommand.ps1";
if (Test-Path $cmdScript)
{
    & Get-Help $cmdScript -Detailed
    Exit
}

#look for the command in a folder with the same name (ie .\revertall\revertall.ps1)
$cmdFolder = Join-Path $cmdFolder $commandName;
$cmdScript = Join-Path $cmdFolder "$helpCommand.ps1";
if (Test-Path $cmdScript)
{
    & Get-Help $cmdScript -Detailed
    Exit
}

Write-ColorOutput "Error: Command '$helpCommand' not found!"