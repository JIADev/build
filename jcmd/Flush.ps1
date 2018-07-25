<#
.SYNOPSIS
  Flushes j6 related services that are associated with cached data.
.DESCRIPTION
  Flushes j6 related services that are associated with cached data.

.PARAMETER services
  A string array of services from the following list that should be 
  restarted or flushed.

  Options:
  IIS, Redis, SQL, IISExpress, All

  Example: jcmd flush IIS,Redis,SQL

.EXAMPLE
  PS C:\dev\project_folder>jcmd flush IIS,Redis,SQL

  .EXAMPLE
  PS C:\dev\project_folder>jcmd flush all
.NOTES
  Created by Richard Carruthers 07/17/2018
#>
param(
    [String[]] $services = @('all')
)

. "$PSScriptRoot\_Shared\common.ps1"

$all = $services -contains "all"
$iis = $services -contains "iis"
$sql = $services -contains "sql"
$redis = $services -contains "redis"
$iisexpress = $services -contains "iisexpress"

Write-ColorOutput "Starting jobs:" Cyan

if ($all -or $iisexpress)
{
    Start-Job -name FlushIISExpress -ScriptBlock {get-process | where { $_.ProcessName -like "IISExpress"} | stop-process}
}

if ($all -or $sql)
{
    Start-Job -name FlushSQL -ScriptBlock {Restart-Service MSSQLSERVER -force}
}

if ($all -or $iis)
{
    Start-Job -name FlushIIS -ScriptBlock {IISReset}
}

if ($all -or $redis)
{
    Start-Job -name FlushRedis -ScriptBlock {C:\Redis\redis-cli.exe $args[0]} -ArgumentList @("flushall")
}

Write-ColorOutput "Waiting for jobs to complete..." Cyan

Get-Job -name Flush* | Wait-Job
Remove-Job -name Flush*

Write-ColorOutput "Flush complete..." Cyan
