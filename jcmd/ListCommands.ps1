<#
.SYNOPSIS
    Lists jcmd commands with synopsis.
.DESCRIPTION
    Lists jcmd commands with synopsis.
.EXAMPLE
    PS C:\dev\project_folder>jcmd listcommands
.INPUTS
    NONE
.OUTPUTS
    List of jcmd commands.

    Use "jcmd help [Command Name]" to get more information.
.NOTES
#>

$cmdFolder = $PSScriptRoot;


Get-ChildItem  -File -Include "*.ps1"

$commands = Get-ChildItem "$cmdFolder\\*" -File -Include "*.ps1" | ForEach-Object {$_.FullName}
$folders = Get-ChildItem $cmdFolder -directory -Exclude "`_*"  | ForEach-Object {$_.FullName}
$folderCommands = 
    $folders |
    ForEach-Object {$leaf=Split-Path -Leaf $_; return "$_\$leaf.ps1"} |
    Where-Object {Test-Path $_}

($commands + $folderCommands) |
    ForEach-Object { Get-Help $_ } | 
    Select-Object @{N="Command Name"; E={[IO.Path]::GetFileNameWithoutExtension($_.Name)}},@{N="Description"; E={$_.Synopsis}} | 
    Sort-Object -Property "Command Name" | 
    Format-Table -Auto

Write-Host "Execute: jcmd help [Command] for details on a specific command" -ForegroundColor Cyan


