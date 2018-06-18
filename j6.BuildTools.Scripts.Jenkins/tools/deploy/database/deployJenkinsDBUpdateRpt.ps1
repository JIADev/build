<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/20/2017 13:21
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsDBUpdateRpt.ps1
	===========================================================================
	.DESCRIPTION
		This is the script for creating the database update report.
		Previous execution was through msbuild deployment.proj target ScriptDac pacs
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env,
	[string]$dbServer,
	[string]$dbName = "",
	[string]$dbInstance
)

#Find all the Dacpacs
Write-Host "Copy DacPac"
gci -Path $archivePkg

Add-Type -Path "C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\Microsoft.SqlServer.Dac.dll"
$dacService = New-Object Microsoft.SqlServer.Dac.DacServices "server=$dbServer"

$dacPacPath = ""
$dacPac = [Microsoft.SqlServer.Dac.DacPackage]::Load("$dacPacPath")

$dacService.Deploy($dacPac, $dbName, $true)
