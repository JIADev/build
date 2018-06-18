<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/10/2017 08:38
	 Created by:   	jcollins
	 Organization: 	JIA Inc.
	 Filename:     	jenkinsDeployWebStopRTE.ps1
	===========================================================================
	.DESCRIPTION
		Jenkins deployment script to stop RTE on the RTE server.
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
$secPW = (Get-Content "$($ENV:secrets_dir)\ccnet.txt") | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($user, $secPW)

$cust = $driver.Substring(4)

$rteScriptBlock = {
	param
	(
		[parameter(Mandatory = $true)]
		[string]$rteCommand,
		[string]$rteService
	)
	
	If ($rteCommand -eq "Stop")
	{
		Write-Host "Stopping RTE on $env:COMPUTERNAME"
		Stop-Service -Name "*$rteService*"
	}
	If ($rteCommand -eq "Start")
	{
		Write-Host "Starting RTE on $env:COMPUTERNAME"
		Start-Service -Name "*$rteService*"
	}
}

#Get list of RTE servers from config.
#get the contents of the JSON file with the server list in it.
$json = Get-Content $config_json -Raw | ConvertFrom-Json
$servers = $json.$driver.environments.$deploy_env.rte | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
$rteService = $json.$driver.environments.$deploy_env.rte.rteServiceName


#Loop through each rte server and stop any RTE services that might exist.
foreach ($server in $servers)
{
#	Write-Host "Working with RTE on $env:COMPUTERNAME"
	$hostname = $json.$driver.environments.$deploy_env.rte.hostname
	$ip = $json.$driver.environments.$deploy_env.rte.ip
#		Write-Host $hostname
#		Write-Host $ip
	Invoke-Command -ComputerName $hostname -Credential $credential -ScriptBlock $rteScriptBlock -ArgumentList "$Command", $rteService
	
}


#Write-Host "Stop $($RTE_SERVICE) on $($RTE_SERVER)." -ForegroundColor Green
#Invoke-Command -ComputerName $RTE_SERVER -Credential $secureCreds -ScriptBlock $rteScriptBlock -ArgumentList "Stop", "$($RTE_SERVICE)"