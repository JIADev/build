<#
.SYNOPSIS
  Sets j6 project configuration variables such as customer number and database.
.DESCRIPTION
  Sets j6 project configuration variables such as customer number and database.
.PARAMETER CustomerCode
  Should be "CUST" followed by 4 digit customer number followed by market identifier.
  Example: CUST2097PL
.PARAMETER DatabaseName
  Specifies datebase name to be used for connecting to main j6 data.
.PARAMETER CacheDBId
  Specifies the Redis DB ID to use, should be different for each customer and/or SQL DB.
  Valid values typically are 1-16, but this can be changed in the Redis configuration.
.PARAMETER DatabaseServer
  DNS name of the SQL server hosting the main j6 database.
  Examples: ".", "localhost", "127.0.0.1", "DEV-1002sql1"
.PARAMETER CustomerDriverFeature
  Usually the same as the customer code, defaults to the customer code when not specified
.PARAMETER ReportDatabaseName
  Specifies datebase name to be used for connecting to j6 reporting data.
  Defaults to the main database name if not specified.
.PARAMETER ReportDatabaseServer
  DNS name of the SQL server hosting the reporting j6 database.
  Defaults to the main database server if not specified.
.PARAMETER ConfigurationOverride
  Overrides the configuration used during "j build".
  Typical values are: 
    Debug (the default)
    Release (what the build server uses)

  Use this override to build release in mode locally.
.EXAMPLE
  PS C:\> jcmd configure CUST1002 CUST1002_DB
.NOTES
  Created by Richard Carruthers on 07/11/18
#>
param(
	[Parameter(Mandatory=$true)][string]$CustomerCode,
	[Parameter(Mandatory=$true)][string]$DatabaseName,
	[Parameter(Mandatory=$true)][int]$CacheDBId,
	[Parameter(Mandatory=$false)][string]$DatabaseServer="localhost",
	[Parameter(Mandatory=$false)][string]$CustomerDriverFeature,
	[Parameter(Mandatory=$false)][string]$ReportDatabaseName,
	[Parameter(Mandatory=$false)][string]$ReportDatabaseServer,
	[Parameter(Mandatory=$false)][string]$ConfigurationOverride = "Debug"
)

if (!$ReportDatabaseName)
{
  $ReportDatabaseName = $DatabaseName
  $ReportDatabaseServer = $ReportDatabaseServer
}

if (!$CustomerDriverFeature)
{
  $CustomerDriverFeature = $CustomerCode
}

try
{
  & msbuild /t:Configure /p:Customer=$CustomerCode /p:DriverFeature=$CustomerCode j6.proj | Out-Null
  if ($LASTEXITCODE -ne 0) {throw "Error configuring j6!"}  
  
  & msbuild /t:Configure /p:CacheDatabase=$CacheDBId j6.proj | Out-Null
  if ($LASTEXITCODE -ne 0) {throw "Error configuring j6!"}  
  
  & msbuild /t:Configure /p:DatabaseServer=$DatabaseServer /p:DatabaseName=$DatabaseName /p:ReportDatabaseServer=$DATABASE_SERVER /p:ReportDatabaseName=$DATABASE_NAME j6.proj | Out-Null
  if ($LASTEXITCODE -ne 0) {throw "Error configuring j6!"}  
  
  & msbuild /t:Configure /p:ReportDatabaseServer=$ReportDatabaseServer /p:ReportDatabaseName=$ReportDatabaseName j6.proj | Out-Null
  if ($LASTEXITCODE -ne 0) {throw "Error configuring j6!"}  
  
  & msbuild /t:Configure /p:Configuration=$ConfigurationOverride j6.proj | Out-Null
  if ($LASTEXITCODE -ne 0) {throw "Error configuring j6!"}  
  
  & msbuild /nologo /t:showconfig j6.proj
}
catch
{
	Write-Host $Error
	"Error: press enter to exit!"
	Read-Host
}