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

function UpdateAssemblyInfoVersion
(
	[string]$file,
	[string]$newVersion
)
{
	$pattern = '^\[assembly: AssemblyVersion\("(.*)"\)\]$'

	(Get-Content $file -Encoding UTF8) | ForEach-Object {
		if ($_ -match $pattern) 
		{
			$fileVersion = [version]($matches[1] -replace "\*","0")

			'[assembly: AssemblyVersion("{0}")]' -f $newVersion

			Write-Host "Updating version from $fileVersion to $newVersion in $file"
		} 
		else 
		{
			$_
		}
	} | Set-Content $file -Encoding UTF8
}

function GetAssemblyInfoVersion
(
	[string]$file
)
{
	write-host "Parsing $file for version." -ForegroundColor Yellow
	$pattern = '^\[assembly: AssemblyVersion\("(.*)"\)\]$'

	(Get-Content $file -Encoding UTF8) | ForEach-Object {
		if ($_ -match $pattern) 
		{
			$fileVersion = [string]($matches[1] -replace "\*","0")
		} 
	} | Out-Null

	if ($fileVersion.Length -eq 0) 
	{
		throw "Error parsing $($file): Assembly version not found."
	}
	
	return $fileVersion		
}
