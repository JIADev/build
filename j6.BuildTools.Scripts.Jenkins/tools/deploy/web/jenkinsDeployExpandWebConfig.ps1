<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	12/21/2017 11:00
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	jenkinsDeployExpandWebConfig.ps1
	===========================================================================
	.DESCRIPTION
		This is a prototype script to try and mimic the functionality of configatron in ruby in an effort to be able to dynamically write web.config
		files during the build/deployment based on environment. This is probably called from the jenkinsDeployCreateSitePackage.ps1 script.

		Premise:
		
		1. Accept Parameters $driver, $deploy_env, and the config_json file (possibly 'hard code' this later to be come a 'secret' and held in source control).
		2. check out configs with naming convention i.e <portal>.web.config, from source control. Folder structure in source control should be by
			<portal>.web.config. Possibly keep these configs in the 'secrets' repo that we will keep the
			config_json file and other secrets in. The appropriate configs would be copied to a working folder in the 'RELEASE/Site' folder.
		3. Transform web.config using settings from json.
		4. Rename the new config as new_<portal>.web.config.
		5. Copy the new config to the appropriate portal folder in the _Site package that is zipped for deployment. *Don't forget the 'root' config for load balanced environments*
		6. 
		
#>

param (
	[string]$webConfig,
	[string]$portal,
	[string]$driver,
	[string]$deploy_env,
	[string]$config_json
)

Write-Verbose -Verbose "Beep...Boop...Expanding $(Split-Path -path $webConfig -Leaf)"
#Write-Verbose -Verbose ("Path to Web.Config: {0}" -f $webConfigTemp)

$json = Get-Content $config_json -Raw | ConvertFrom-Json

# read in the web.config file
$contents = gc -Path $webConfig

# perform a regex replacement
$newContents = "";
$contents | % {
	$line = $_
	if ($_ -match "__(\w+)__")
	{
		$setting = $Matches[1]
		$value = $json.CUST1002.environments.DEV.configs.$portal.$setting
		$setting = $json.$driver.environments.$deploy_env.configs.$portal.psobject.properties.name -eq $Matches[1]
		if ($setting)
		{
			Write-Verbose -Verbose ("Replacing key {0} with value from the {1} environment config settings." -f $setting, $deploy_env)
			$line = $_ -replace "__(\w+)__", $value
		}
	}
	$newContents += $line + [Environment]::NewLine
}