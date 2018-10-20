<#
.SYNOPSIS
  Executes a SQL command string on the configured j6 database.
.DESCRIPTION
  Uses the SQL Settings file to generate a connection string for executing the 
  supplied SQL string.
.PARAMETER sql
  String containing SQL statement(s)
.EXAMPLE
  PS C:\> jcmd SQL "select * from dbo.Country"
.NOTES
  Created by Richard Carruthers on 07/23/18
#>
param(
    [string]$sql
)
. "$PSScriptRoot\_shared\jposhlib\J6SQLConnection.Class.ps1"

Ensure-IsAdmin
Ensure-IsPowershellMinVersion5
Ensure-IsJ6DevRootFolder


$sqlConn = [J6SQLConnection]::new()

$data = $sqlConn.ExecuteSQL($sql)

Write-Output $data