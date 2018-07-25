<#
.SYNOPSIS
  Executes a SQL command string or file on the configured j6 database.
.DESCRIPTION
  Uses the SQL Settings file to generate a connection string for executing the 
  supplied SQL string or SQL file.

.PARAMETER query
  String containing SQL statement(s)
.PARAMETER sql
  String containing SQL statement(s)
.PARAMETER file
  Name of file containing SQL statement(s).
.EXAMPLE
  PS C:\> jcmd SQL "select * from dbo.Country"
.NOTES
  Created by Richard Carruthers on 07/23/18
#>
param(
    [switch]$query,
    [string]$sql,
    [string]$file
)

. "$PSScriptRoot\_shared\jposhlib\J6SQLConnection.Class.ps1"


$sqlConn = [J6SQLConnection]::new()

if ($file)
{
    $sql = get-content -Path $file
}

if ($query)
{
    $data = $sqlConn.ExecuteReader($sql, 30)
}
else {
    $data = $sqlConn.ExecuteNonquery($sql, 30)
}

$data | Format-Table