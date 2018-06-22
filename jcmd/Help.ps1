<#
.SYNOPSIS
    Displays the help associated with jcmd scripts.
.DESCRIPTION
    Every jcmd command script should contain standard powershell help information
    such as SYNOPSIS, DESCRIPTION, EXAMPLES, INPUTS, OUTPUTS, and NOTES.
.EXAMPLE
    PS C:\dev\project_folder>jcmd help forwardchangecheck
.INPUTS
    CommandName: Command for which to display the help information.
.OUTPUTS
    Help.
.NOTES
#>
param(
    [string]$commandName
)

$cmdFolder = $PSScriptRoot;


#look for the command as a ps1 file in the command folder
$cmdScript = Join-Path $cmdFolder "$commandName.ps1";
if (Test-Path $cmdScript)
{
    & Get-Help $cmdScript
    Exit
}

#look for the command in a folder with the same name (ie .\revertall\revertall.ps1)
$cmdFolder = Join-Path $cmdFolder $commandName;
$cmdScript = Join-Path $cmdFolder "$commandName.ps1";
if (Test-Path $cmdScript)
{
    & Get-Help $cmdScript
    Exit
}

Write-Host "Error: Command '$commandName' not found!"