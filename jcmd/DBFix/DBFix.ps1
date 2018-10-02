<#
.SYNOPSIS
  Execute common DB scripts
.DESCRIPTION
   Execute common DB scripts via a text menu. Typically used after restoring a database 
   to a new environment.
.EXAMPLE
  PS C:\dev\project_folder>jcmd dbfix
.NOTES
  Created by Richard Carruthers 07/17/2018
#>

. "$PSScriptRoot\..\_Shared\common.ps1"
. "$PSScriptRoot\..\_shared\jposhlib\J6SQLConnection.Class.ps1"

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

Ensure-Is64BitProcess
Ensure-IsPowershellMinVersion5
Ensure-IsJ6DevRootFolder

$scripts = Get-ChildItem $PSScriptRoot -Filter *.sql

$table = $scripts | Select-Object @{N="Number"; E={$scripts.IndexOf($_)+1} },@{N="Script Name"; E={GetName $_.FullName}},@{N="Description"; E={GetDescription $_.FullName}}

$table | format-table

$scriptNumbers = Read-Host -Prompt 'List of scripts to execute (CSV: 1,4,2)'

$scriptNumbersArr = $scriptNumbers -split ','

if (-not $scriptNumbersArr) {Exit 0;}

$sqlConn = [J6SQLConnection]::new()

$scriptNumbersArr | % {

  $scriptNumber = $_.trim()

  $scriptFileName = $table | Where-Object {"$($_.Number)" -eq $scriptNumber} | Select-Object -ExpandProperty 'Script Name'
  $sqlFile = "$PSScriptRoot\$scriptFileName.sql"


  if (($scriptFileName) -and (Test-Path $sqlFile))
  {
    try {
        $sqlFile = "$PSScriptRoot\$scriptFileName.sql"
        "Executing $scriptFileName"
        $sqlConn.ExecuteFile($sqlFile, $false)
    }
    catch [Exception]
    {
      "$scriptFileName failed to execute!"
      $_.Exception|format-list -force
      Exit 0
    }
  }
  else
  {
    "Could not find script number $scriptNumber!"
  }
  
}
