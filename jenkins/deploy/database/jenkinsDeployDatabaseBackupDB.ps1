<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	1/19/2018 14:02
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployDatabaseBackupDB.ps1
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

#create PSCred object for PSRemoting
$user = "jenkon\ccnet_new"
$secPW = (Get-Content "$($ENV:secrets_dir)\ccnet.txt") | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($user, $secPW)

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

#check drive space?
$freeSpace = (Invoke-Command -ComputerName $sqlHostname -Credential $credential -ScriptBlock { Get-PSDrive -PSProvider FileSystem } | ? { $_.Name -eq $backupDrive } | select -ExpandProperty Free) / 1Gb
$lastDBBakSize = (gci -Path $backupPath -Filter *.bak | sort LastWriteTime | select -Last 1 | select -ExpandProperty Length) / 1gb
#Write-Host "file size $lastDBBakSize"

#format SQL statement
if ($freeSpace -gt $lastDBBakSize)
{
	$bakFileName = "{0}\{1}_preDeploy_{2}.bak" -f $sqlBackupDir, $dbname, (get-date -Format "yyyyMMddHHmmss")
	$sqlQuery = "BACKUP DATABASE [$dbname] TO  DISK = '$bakFileName'  WITH COPY_ONLY, NOFORMAT, NOINIT,  NAME = '$dbname', SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10"
	
	try
	{
		$bakTimer = [System.Diagnostics.Stopwatch]::StartNew()
		#execute SQLCMD
		& SQLCMD -S "$sqlHostname" -d "$dbName" -Q "$sqlQuery" -e
		$bakTimer.Stop()
		$msg = "The backup has completed in {0} minutes." -f $bakTimer.Elapsed.TotalMinutes
		Write-Host $msg
	}
	catch
	{
		Write-Error "DB Backup Failed. Error: $_"
	}
}
else
{
	$msg = "There is currently not enough free space on the specified backup directory: {0}. The backup needs approximately {1}gb of space and {2}gb is available." -f $sqlBackupDir, $lastDBBakSize, $freeSpace
	Write-Error $msg
}
