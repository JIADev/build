<#
.SYNOPSIS
  Creates a new self-signed certificate for use in IIS and moves it into the Trusted Root store.
.DESCRIPTION
  Creates a new self-signed certificate for use in IIS and moves it into the Trusted Root store.
  Also, has the ability to remove a cert using the -delete option
.PARAMETER FQDN
  Fully Qualified Domain Name that will be used as the name and subject of this certificate.
  Example: www.cust1002.local
.PARAMETER delete
  Switch option used to cause an existing certificate to be removed rather than creating a new one.
  Example: jcmd CreateTrustedWebCert www.cust1002.local -delete
.EXAMPLE
  PS C:\> jcmd CreateTrustedWebCert www.cust1002.local
.NOTES
  Created by Richard Carruthers on 07/16/18
#>

param(
  [Parameter(Mandatory=$true)][string] $FQDN,
  [switch] $delete
)

Import-Module WebAdministration
. "$PSScriptRoot\_Shared\common.ps1"

#get any pre-existing cert that matches this binding
$oldCert = Get-ChildItem cert:\LocalMachine\My | where { $_.Subject -match "CN=$FQDN" } | select -First 1

if ($oldCert)
{
	Write-ColorOutput "Removing cert(s) for subject $FQDN" Yellow

	$certs = (Get-ChildItem cert:\LocalMachine\My | where {$_.Subject -match $FQDN})

	$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
	$rootStore.Open("MaxAllowed")

	foreach ($cert in $certs)
	{
		$rootStore.Remove($cert)
	}
	$rootStore.Close()

  $certs | Remove-Item -Recurse -Confirm:$false
  Write-ColorOutput "$FQDN certificate removed." Cyan
} else {
	Write-ColorOutput "Existing certificate not found ($FQDN)." Cyan
}


if (!$delete)
{
  Write-ColorOutput "Creating NEW self signed certificate: $FQDN" Cyan

  #$expDate = (Get-Date).AddYears(10)
  #$startDate = (Get-Date).AddDays(-1)
  New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $FQDN
  $cert = Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -match "CN=$FQDN" } | select-object -First 1

  Write-ColorOutput "Moving certificate to Trusted Root" Cyan

  #add this cert to the root store
  $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
  $rootStore.Open("MaxAllowed")
  $rootStore.Add($cert)
  $rootStore.Close()

  Write-ColorOutput "Certificate action complete." Cyan

  return $cert
}