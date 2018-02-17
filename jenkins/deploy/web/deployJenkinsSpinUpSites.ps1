<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	12/19/2017 10:36
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsSpinUpSites.ps1
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

$ie = New-Object -Com internetexplorer.application
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name

foreach ($webserver in $webservers)
{
	$ip = $json.$driver.environments.$deploy_env.webservers.$webserver.ip
	$url = $json.$driver.environments.$deploy_env.webservers.$webserver.url
	$portals = ("Corporate", "Business", "Integration", "WebPWS")
	foreach ($portal in $portals)
	{
		$ipURL = "https://$ip/$portal"
		$domainURL = "$url/$portal"
#		$ie.Navigate("$ipURL")
#		$ie.Visible = $true
#		$ie.Navigate("$domainURL", 0x1000)
#		$ie.Visible = $true
		start $ipURL
		start $domainURL
	}
}