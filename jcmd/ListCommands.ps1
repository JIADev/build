<#
.SYNOPSIS
  Lists jcmd commands with synopsis.
.DESCRIPTION
  Lists jcmd commands with synopsis.
.EXAMPLE
  PS C:\dev\project_folder>jcmd listcommands
.PARAMETER quiet
  Limits output to only a list of commands
.PARAMETER fullName
  Limits output to only a list of commands
.NOTES
#>
param(
  [switch]$quiet,
  [switch]$fullName
)

function GetCommandName($fileName, $showFullName)
{
  if ($showFullName) {return $fileName}
  $shortName = [IO.Path]::GetFileNameWithoutExtension($fileName);
  return $shortName;
}

. "$PSScriptRoot\_Shared\common.ps1"

$cmdFolder = $PSScriptRoot;
Get-ChildItem  -File -Include "*.ps1"

$commands = Get-ChildItem "$cmdFolder\\*" -File -Include "*.ps1" | ForEach-Object {$_.FullName}
$folders = Get-ChildItem $cmdFolder -directory -Exclude "`_*"  | ForEach-Object {$_.FullName}
$folderCommands = 
    $folders |
    ForEach-Object {$leaf=Split-Path -Leaf $_; return "$_\$leaf.ps1"} |
    Where-Object {Test-Path $_}

if ($quiet)
{
  ($commands + $folderCommands) |
    ForEach-Object {$(GetCommandName $_ $fullName)}    
}
else {
  ($commands + $folderCommands) |
    ForEach-Object { Get-Help $_ } |
    Select-Object @{N="Command Name"; E={GetCommandName($_.Name,$fullName)}},@{N="Description"; E={$_.Synopsis}} |
    Sort-Object -Property "Command Name" |
    Format-Table -Auto

    Write-ColorOutput "Execute: jcmd help [Command] for details on a specific command" -ForegroundColor Cyan
}




