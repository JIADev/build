<#
	.SYNOPSIS
		A brief description of the jenkinsDeployWebStopAppPools.ps1 file.
	
	.DESCRIPTION
		Jenkins deployment script to stop App Pools on the Web Servers.
	
	.PARAMETER driver
		Customer driver parameter.

	.PARAMETER config_json
		Parameter for the path to the json config file for environments.

	.PARAMETER deploy_env
		Environment we are deploying to.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	10/10/2017 08:38
		Created by:   	jcollins
		Organization: 	JIA Inc.
		Filename:     	jenkinsDeployWebStopAppPools.ps1
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env,
	[string]$command
)

#create PSCred object for PSRemoting
$user = "jenkon\ccnet_new"
$secPW = (Get-Content "$($ENV:secret_dir)\ccnet.txt" | ConvertTo-SecureString)
$credential = New-Object System.Management.Automation.PSCredential($user, $secPW)

$appPoolScriptBlock = {
	param
	(
		[parameter(Mandatory = $true)]
		[string]$serviceCommand,
		[string]$environment
	)
	
	Import-Module WebAdministration
	
	function stopAppPool ($appPools)
	{
		foreach ($appPool in $appPools)
		{
			if ((Get-WebAppPoolState -Name $appPool).Value -ne "Stopped")
			{
				Write-Host "AppPool $appPool on $env:COMPUTERNAME is running. Stopping now..." -ForegroundColor Yellow
				Stop-WebAppPool -Name $appPool
			}
		}
		
	}
	
	function startAppPool ($appPools)
	{
		foreach ($appPool in $appPools)
		{
			if ((Get-WebAppPoolState -Name $appPool).Value -ne "Started")
			{
				Write-Host "AppPool $appPool on $env:COMPUTERNAME is stopped. Starting now..." -ForegroundColor Yellow
				Start-WebAppPool -Name $appPool
			}
		}
		
	}
	
	function getAppPools ($environment)
	{
		Write-Host "Working with App Pools on $ENV:COMPUTERNAME"
		Write-Host "GetAppPools custPrefix: $environment"
		$appPools = Get-ChildItem -Path IIS:\\AppPools | where { $_.Name -like "*$($environment)*" } | select -expandProperty Name
		Write-Host "AppPools: $appPools"
		return $appPools
	}
	
	$appPools = (getAppPools $environment)
	if ($serviceCommand -eq "Stop")
	{
		foreach ($appPool in $appPools)
		{
			stopAppPool $appPool
		}
	}
	if ($serviceCommand -eq "Start")
	{
		
		foreach ($appPool in $appPools)
		{
			startAppPool $appPool
		}
	}
}

#Write-Host "Send script to stop App Pools on remote Web Servers" -ForegroundColor Yellow
#foreach ($webServer in $webServers)
#{
#	$remoteCommand = Invoke-Command -ComputerName $webServer -Credential $secureCreds -ScriptBlock $appPoolScriptBlock -ArgumentList "Stop", "$ENV_$($CUST)"
#	$remoteCommand
#}


#Get list of web servers from config.
#get the contents of the JSON file with the server list in it.
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$webservers = $json.$driver.environments.$deploy_env.webservers | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$custPrefix = $json.$driver.environments.$deploy_env.custPrefix


#Loop through each web server
#Stop app pools matching customer
foreach ($webserver in $webservers)
{
	$hostname = $json.$driver.environments.$deploy_env.webservers.$webserver.hostname
	$ip = $json.$driver.environments.$deploy_env.webservers.$webserver.ip
	#	Write-Host $hostname
	#	Write-Host $ip
	Invoke-Command -ComputerName $hostname -Credential $credential -ScriptBlock $appPoolScriptBlock -ArgumentList "$Command", "$custPrefix"
	
}

