<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	12/7/2017 11:38
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployCreateSQLSettings.ps1
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

$workingDirectory = "$($ENV:WORKSPACE)"

#Get DB values from config.json
# \\jia-jenkins1\d$\secrets\deployConfig.json
$json = Get-Content $config_json -Raw | ConvertFrom-Json

#Set new DB values to write to sql-settings.xml
#$newDBServer = "DEV-1002sql1"
$newDBServer = $json.$driver.environments.$deploy_env.sql.hostname
$newDBName = $json.$driver.environments.$deploy_env.sql.dbName
$newRPTServer = $json.$driver.environments.$deploy_env.reports.hostname
$newRPTDBName = $json.$driver.environments.$deploy_env.sql.dbName
$newRedisHost = $json.$driver.environments.$deploy_env.redis.hostname

#Get development sql-settings.xml and load as an XML object in memory.
$xmlpath = "$workingDirectory\RELEASE\sql-settings.xml"
#$xmlpath = "C:\JCJenkins\workspace\1002\sql-settings.xml"
$xml = New-Object XML
$xml.Load($xmlpath)

#Find development server settings
$dbserver = $xml.SelectSingleNode("//sql//server")
$dbname = $xml.SelectSingleNode("//sql//database")
$rptServer = $xml.SelectSingleNode("//reporting//server")
$rptDBName = $xml.SelectSingleNode("//reporting//database")
$redisHost = $xml.SelectSingleNode("//Cache//Servers//Server")

#Set new DBvalues in the XML object
$dbserver.InnerText = "$newDBServer"
$dbname.InnerText = "$newDBName"
$rptServer.InnerText = "$newRPTServer"
$rptDBName.InnerText = "$newRPTDBName"
$redisHost.SetAttribute("Host", "$newRedisHost")

#Write the new sql-settings.xml file.
$xml.Save("$xmlpath")

