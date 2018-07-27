<#
.SYNOPSIS
  Execute common DB scripts
.DESCRIPTION
   Execute common DB scripts. Typically used after restoring a database to a new environment.

.PARAMETER scripts

.EXAMPLE
  PS C:\dev\project_folder>jcmd flush IIS,Redis,SQL

  .EXAMPLE
  PS C:\dev\project_folder>jcmd flush all
.NOTES
  Created by Richard Carruthers 07/17/2018
#>
param(
  [String] $script
)

. "$PSScriptRoot\..\_Shared\common.ps1"
. "$PSScriptRoot\..\_shared\jposhlib\J6SQLConnection.Class.ps1"

#$all = $services -contains "all"

$sqlFile = "$PSScriptRoot\$script.sql"


if (($script) -and (Test-Path $sqlFile))
{
  $sqlConn = [J6SQLConnection]::new()
  try {
      $sqlFile = "$PSScriptRoot\$script.sql"
      $sqlConn.ExecuteFile($sqlFile)
  }
  finally {

  }
  EXIT 0
}

#else, show the list of possible commands

function GetDescription([string] $fileName)
{
  $firstLine = $(Get-Content $fileName -First 1)
  $result = $firstLine.Substring(2).Trim()
  return $result
}

function GetName([string] $fileName)
{
  $result = [IO.Path]::GetFileNameWithoutExtension($fileName);
  return $result
}

$scripts = Get-ChildItem $PSScriptRoot -Filter *.sql

$table = $scripts | Select-Object @{N="Script Name"; E={GetName $_.FullName}},@{N="Description"; E={GetDescription $_.FullName}}

$table | format-table

