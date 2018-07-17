#
# Common-IIS.ps1
#
Import-Module WebAdministration

function Enable-WebSiteProtocol($site, $protocol)
{
	$name = $site.Name
	$protocols = $site.enabledProtocols
	$protocolList = $protocols -split ","
	if ($protocolList -notcontains $protocol)
	{
		if ($protocols -ne "") { $protocols+="," }
		$protocols+="net.pipe"
		$site | Set-ItemProperty -name enabledProtocols -Value $protocols
		Write-Output "$name configured with protocols: $protocols"
	}
	else {
		Write-Output "Skipping! $name already configured with: $protocols"
	}
}

function Enable-WebAppProtocol($sitePath, $appName, $protocol)
{
	$app = Get-WebApplication -site "$siteName" -name "$applicationName"
	$name = $app.path
	$protocols = $app.enabledProtocols
	$protocolList = $protocols -split ","
	if ($protocolList -notcontains $protocol)
	{
		if ($protocols -ne "") { $protocols+="," }
		$protocols+="net.pipe"
		
		Get-ChildItem "IIS:\Sites\$siteName" | 
		Where-Object {($_.Schema.Name -eq "Application") -and ($_.Name -eq $appName)} | 
		ForEach-Object { Set-ItemProperty $_.PSPath -name enabledProtocols -Value "$protocols"}
		
		Write-Output "$name configured with protocols: $protocols"
	}
	else {
		Write-Output "Skipping! $name already configured with: $protocols"
	}
}

function Enable-NetPipeProtocol([string] $siteName, [string] $applicationName)
{
	$websites = Get-ChildItem 'IIS:\Sites'
	$site = $websites | Where-object { $_.Name -eq $siteName }
	Enable-WebSiteProtocol $site "net.pipe"

	if ($applicationName)
	{
		Write-Output "Configuring application '$applicationName'"
		Enable-WebAppProtocol $siteName $applicationName "net.pipe"
	}
}

function Create-NetPipeBinding([string] $siteName)
{
	$websites = Get-ChildItem 'IIS:\Sites'
	$site = $websites | Where-object { $_.Name -eq $siteName }
	$netPipeExists = [bool]($site.bindings.Collection | ? { $_.bindingInformation -eq '*' -and $_.protocol -eq 'net.pipe' })
	if (!$netPipeExists )
	{
		Write-Output "Net Pipe binding does not exist for this site. Creating binding now..."
		# Create the binding
		$site | New-ItemProperty -name bindings -Value @{protocol="net.pipe";bindingInformation="*"}
		Write-Debug "net.pipe binding created"
	}
	else
	{
		Write-Output "net.pipe binding already exists for the site"
	}

}
