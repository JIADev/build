#
# 
#


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