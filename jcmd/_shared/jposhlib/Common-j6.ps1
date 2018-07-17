#
# 
#

function Ensure-IsJ6DevRootFolder()
{
	$isValid = $true;
	$path = Get-Location
	$sitePath = Join-Path $path "Site"
	$isValid = $isValid -and (Test-Path $sitePath -pathType container)

#ensure this is a path with a j6 style /site/ folder
	if (!$isValid)
	{
		Throw "This is not a valid folder. Call this command from the root of a j6 source repository. Be sure to build first!"
		exit 1;
	}
}

function Test-J6NetworkConnected()
{
	return Test-Connection source.jenkon.com -count 1 -quiet
}

function Test-JenkonDomain()
{
	$domain=(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
	$domainName=(Get-WmiObject -Class Win32_ComputerSystem).Domain

	return $domain -and ($domainName -ieq "jenkon")
}


function Ensure-J6NetworkConnected()
{
	if (!(Test-J6NetworkConnected))
	{
		Write-Host "This script requires a connection to the Jenkon Network - please connect directly or through a VPN!"
		exit 1	
	}
}