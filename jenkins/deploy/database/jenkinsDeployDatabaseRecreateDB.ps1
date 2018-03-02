<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	1/19/2018 14:02
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployDatabaseRecreateDB.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env
)

$ErrorActionPreference = 'Stop'

#get json config info for sql server and dbname and possibly backup drive.
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$dbname = $json.$driver.environments.$deploy_env.sql.dbName
$sqlHostname = $json.$driver.environments.$deploy_env.sql.hostname
$sqlIP = $json.$driver.environments.$deploy_env.sql.ip
$sqlBackupDir = $json.$driver.environments.$deploy_env.sql.backups
$backupDrive = ((Split-Path -path $sqlBackupDir -Qualifier)) -replace ':',''
$backupPath = $sqlBackupDir -replace ':', '$'
$backupPath = "\\$sqlHostname\$backupPath"

#check if DB exists, if so, drop it.
Write-Host "If DB exists, we want to drop it."
$dropScript = "IF EXISTS (SELECT name FROM sys.databases WHERE name = '$($dbname)') DROP DATABASE [$($dbname)]"
#execute SQLCMD
Write-Host "If DB doesn't exists, create the blank DB"
$createScript = "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$($dbname)') CREATE DATABASE [$($dbname)]"
#Execute SQLCMD
Write-Host "Once the DB is created, we need to make sure we set up permissions, and service broker is enabled."

$cust = $driver.Substring(4,4)
Write-Host $workerProcessUser
$userScript = "USE [$($dbName)] OG; DECLARE @brokerSql VARCHAR(200) GO; SET @brokerSql = 'ALTER DATABASE [' + DB_NAME() + '] SET NEW_BROKER WITH ROLLBACK IMMEDIATE' GO; EXEC (@brokerSql) GO; EXEC sp_configure 'clr enabled', 1 go; RECONFIGURE go; EXEC sp_configure 'clr enabled' go; USE [$($dbName)] GO; exec sp_adduser @loginame = 'jenkon\$($deploy_env)$($cust)_rte' GO; exec sp_addrolemember @rolename = 'db_owner', @membername = 'jenkon\$($deploy_env)$($cust)_rte' GO; exec sp_adduser @loginame = 'jenkon\$($deploy_env)$($cust)_wp' GO; exec sp_addrolemember @rolename = 'db_owner', @membername = 'jenkon\$($deploy_env)$($cust)_wp' GO; "
#Exceute SQLCMD