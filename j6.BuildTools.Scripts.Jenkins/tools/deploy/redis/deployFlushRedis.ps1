<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	12/14/2017 12:15
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployFlushRedis.ps1
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

$json = Get-Content $config_json -Raw | ConvertFrom-Json
$redisHostname = $json.$driver.environments.$deploy_env.redis.hostname
$redisIP = $json.$driver.environments.$deploy_env.redis.ip

$errorLog = "$($jia_log_dir)\$($BUILD_TAG)-redis.log"

$cmdParams = "c:\Redis\redis-cli -h $redisHostname -n 1 ""flushdb"""
$redis = Get-Process -Name "redis-cli" -ErrorAction SilentlyContinue
if ($redis -ne $null)
{
	#try to gracefully quit the process
	$redis.CloseMainWindow()
	#kill after 5 seconds
	sleep 5
	if (!$redis.HasExited)
	{
		$redis | Stop-Process -Force
	}
}
else
{
	Write-Host "Flushing Redis on $redisHostname"
	try
	{
#		Start-Process -FilePath "C:\Redis\redis-cli.exe" -ArgumentList $cmdParams -PassThru -verb runas -Wait -RedirectStandardError "$errorLog"
#		$exe = "C:\Redis\redis-cli.exe"
		#		& $exe $cmdParams
		Invoke-Command -ComputerName $redisHostname -ScriptBlock { $cmdParams }
	}
	catch
	{
		Write-Error "Could not flush Redis on $redisHostname. Error: $_"
	}
}
<#
Below is example code to check for a running process and stop it if its running.  Need to add this to check for Redis-cli running, if it is, stop it, and then flush redis.  
Build has been getting stuck with Redis not finishing properly on failed builds.

# get Firefox process
$firefox = Get-Process firefox -ErrorAction SilentlyContinue
if ($firefox) {
  # try gracefully first
  $firefox.CloseMainWindow()
  # kill after five seconds
  Sleep 5
  if (!$firefox.HasExited) {
    $firefox | Stop-Process -Force
  }
}
Remove-Variable firefox

#>