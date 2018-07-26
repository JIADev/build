<#
.SYNOPSIS
  Creates an IIS Website with sub applications for site folders.
.DESCRIPTION
  Creates an IIS Website with sub applications for site folders.

  Performs the following functions (not in order):
	1. Creates host file entry
	2. Creates trusted certificate for SSL
	3. Sets up all IIS app pools
	4. Sets up all IIS Sites with proper bindings (http, https)
	5. Optionally enables net.pipe protocols
	6. Sets up proper config file for WebPWS if PWS exists
	7. Optionally adds app pool user as db_owner in DB (see -skipDB)
	8. Optionally sets URL appsettings for this environment  (see -skipDB)

  Main website is named according to development folder, using 
  "www." and ".local" prefix and suffix.

  Example: Dev folder is "c:\dev\cust1002\Work1"
  Result: Website will be named "www.Work1.local" by default.
  
  ** This can be overriden using the "name" parameter
.PARAMETER Name
  Overrides the folder name when building the website FQDN.

  Example: jcmd WebApps -Name "test"
  Result: Website will be named "www.test.local".
.PARAMETER netPipe
  Switch that enables net.pipe protocols and configuration.

  Example: jcmd WebApps -netPipe
.PARAMETER remove
  Completely removes most artifacts created by this script 
  including sites, certs, and host file entries.

  ** Does not remove webpws configuration file.
.PARAMETER skipDB
  Skips all actions related to updating the database for this environment.
.NOTES
  Created by Richard Carruthers on 07/17/18
#>
param(
	[string]$name = "",
	[switch]$remove = $false,
	[switch]$netPipe = $false,
	[switch]$skipDb = $false
)

Import-Module WebAdministration

#include Common-Functions file so that we can use them
. "$PSScriptRoot\_shared\jposhlib\Common.ps1"
. "$PSScriptRoot\_shared\jposhlib\Common-IIS.ps1"
. "$PSScriptRoot\_shared\jposhlib\Common-j6.ps1"
. "$PSScriptRoot\_shared\jposhlib\J6SQLConnection.Class.ps1"

$httpPort = 80 #standard http port
$httpsPort = 443 #standard https port
$iisAppPoolDotNetVersion = "v4.0"
$path = (Get-Location).path
$sitePath = "$path\Site"


#if the name is not specified as a parameter, default to the name of the root folder of the repo
if (!$name)
{
	$name = Split-Path -Path $path -leaf
}

$fqdn=("www."+"$name"+".local").ToLower()
$longName="$name - $fqdn"

Write-Debug "Constant: Name = $name"
Write-Debug "Constant: FQDN = $fqdn"
Write-Debug "Constant: Name = $longName"

function Create-AppPool([string] $appPoolName)
{
	Push-Location
	try
	{
		$pool = Get-ChildItem IIS:\AppPools | where {$_.Name -eq "$appPoolName"} | Select-Object -first 1

		#check if the app pool exists
		if ($pool)
		{
			Write-Debug "Skipping App Pool '$appPoolName' - already exists."
			return $pool;
		}

		#create the app pool
		$pool = New-WebAppPool -Name $appPoolName
		$pool.managedRuntimeVersion = $iisAppPoolDotNetVersion
		$pool | Set-Item

		Write-Debug "AppPool '$appPoolName' created"
		
		return $pool
	}
	finally
	{
		Pop-Location
	}
}

function Create-IISSite ([string] $websiteName, [string] $fqdn, [string] $physicalPath, [string] $appPoolName)
{
	Write-Debug "Create-IISSite ([string] websiteName, [string] fqdn, [string] physicalPath, [string] appPoolName)"
	Write-Debug "  websiteName: $websiteName"
	Write-Debug "  fqdn: $fqdn"
	Write-Debug "  physicalPath: $physicalPath"
	Write-Debug "  appPoolName $appPoolName"

	Push-Location
	try
	{
		#check if the site exists
		$iisApp = Get-Website -Name $websiteName
		if ($iisApp)
		{
			Write-Debug "Skipping Site '$websiteName' - already exists."
			return $iisApp
		}

		$iisApp = New-Website -Name $websiteName -ApplicationPool $appPoolName -IPAddress "*" -Port $httpPort -HostHeader $fqdn -PhysicalPath $physicalPath

		Write-Debug "Site '$websiteName' created"
		return $iisApp
	}
	finally
	{
		Pop-Location
	}
}


#Creates WebSite, and Host file entry 
function Create-RootWebSite([string] $siteName, [string] $physicalPath)
{
	Write-Debug "Create-RootWebSite([string] siteName, [string] physicalPath)"
	Write-Debug "  siteName: $siteName"
	Write-Debug "  physicalPath: $physicalPath"

	#CREATE IIS Site
	#navigate to the sites root
	$site = Create-IISSite $longName $fqdn $physicalPath $fqdn #Yes, $fqdn is passed twice here because it is both the website name and the apppool name

	#CREATE SPECIAL BINDINGINGS (HTTPS and NETPIPE)
	if (Get-WebBinding -Name $longName -Protocol "https")
	{
		Write-Debug "Skipping https binding on site '$longName' - already exists"
	}
	else
	{
		Write-Debug "Creating https binding on site '$longName'"
		New-WebBinding -Name $longName -Protocol "https" -Port $httpsPort -HostHeader $fqdn -SslFlags 1
	}

	if ($netPipe)
	{
		Enable-NetPipeProtocol $longName
		Create-NetPipeBinding $longName
	}

	#if SSL binding doesnt already exist, create it
	
	if (Get-ChildItem IIS:\SslBindings\ | where {($_.Host -eq $fqdn) -and ($_.Port=$httpsPort)})
	{
		Write-Debug "Skipping SSL Binding '$sslBindingItemString' - already exists."
	}
	else
	{
		$cert=Create-TrustedSelfSignedCertForLocalSite $fqdn
		Write-Debug "Cert created: $($cert.Thumbprint)"
		$sslBindingItemString = "IIS:\SslBindings\*!$httpsPort!$fqdn"
		Write-Debug "Creating SSL Binding '$sslBindingItemString'"
		$thumb = $cert.Thumbprint | Select-Object -First 1
		Write-Debug "Certificate thumbprint: $thumb"
		$binding = New-Item -Path $sslBindingItemString -Thumbprint $thumb -SSLFlags 1
	}		

	Write-Debug "Root Website '$siteName' Created"

	Write-Debug "Adding host Entry:'$fqdn'"
	AddHostEntry "127.0.0.1" $fqdn
	
	return $site
}

function Remove-Site()
{
		Get-ChildItem IIS:\Sites | where {$_.Name -match $longName} | Remove-Item -Recurse -Confirm:$false
		Get-ChildItem IIS:\AppPools\ | where {$_.Name -match $FQDN} | Remove-Item -Recurse -Confirm:$false

		Remove-AppPoolFromSQL $FQDN

		Remove-TrustedSelfSignedCertForLocalSite $FQDN

		Get-ChildItem IIS:\SslBindings | where {$_.Host -match $FQDN} | Remove-Item -Recurse -Confirm:$false

		Write-Host "Remove operation complete."
		exit
}


function Add-AppPoolToSQL($poolName)
{
	if (!$skipDb)
	{

		$sqlConn = [J6SQLConnection]::new()
		$dbName = $sqlConn.SqlConnection.Database
		$sql = "
DECLARE @SqlStatement nvarchar(2000)

IF EXISTS (SELECT 1 FROM sys.sysusers WHERE [Name] = '$poolName')
BEGIN
	SELECT @SqlStatement = 'DROP User [$poolName]' 
	EXEC sp_executesql @SqlStatement
END

IF EXISTS (SELECT 1 FROM syslogins WHERE [Name] = 'IIS APPPOOL\$poolName')
BEGIN
    SELECT @SqlStatement = 'DROP LOGIN [IIS APPPOOL\$poolName]' 
	EXEC sp_executesql @SqlStatement
END	
	
SELECT @SqlStatement = 'CREATE LOGIN [IIS APPPOOL\$poolName] FROM WINDOWS WITH DEFAULT_DATABASE=[$dbName]' 
EXEC sp_executesql @SqlStatement

SELECT @SqlStatement = 'CREATE USER [$poolName] FOR LOGIN [IIS APPPOOL\$poolName]' 
EXEC sp_executesql @SqlStatement

SELECT @SqlStatement = 'ALTER ROLE [db_owner] ADD MEMBER [$poolName]' 
EXEC sp_executesql @SqlStatement
"
		$data = $sqlConn.ExecuteNonquery($sql, 30)
	}

}

function Remove-AppPoolFromSQL($poolName)
{
	if (!$skipDb)
	{

		$sqlConn = [J6SQLConnection]::new()
		$dbName = $sqlConn.SqlConnection.Database

		#find users
		$sql = "SELECT Name FROM sys.sysusers WHERE [Name] LIKE '"+$poolName+"%'"
		$users = $sqlConn.ExecuteReader($sql, 30)

		#build drop sql
		$sql = ""
		foreach ($user in $users) {
			$sql += "drop user ["+$user.Name+"]; "
		}
		
		#execute drop sql commands
		$data = $sqlConn.ExecuteNonquery($sql, 30)



		#find logins
		$sql = "SELECT Name FROM sys.syslogins WHERE [Name] LIKE 'IIS APPPOOL\"+$poolName+"%'"
		$logins = $sqlConn.ExecuteReader($sql, 30)

		#build drop sql
		$sql = ""
		foreach ($login in $logins) {
			$sql += "drop login ["+$login.Name+"]; "
		}

		#execute drop sql commands
		$data = $sqlConn.ExecuteNonquery($sql, 30)

	}

}

function Create-Site()
{
	Write-Debug "Create-Site([string] name, [string] physicalPath)"
	Write-Debug "  name: $name"
	Write-Debug "  physicalPath: $sitePath"
	try
	{
		Write-Debug "Createing Main AppPool $fqdn"
		$pool=Create-AppPool $fqdn 

		Add-AppPoolToSQL $fqdn

		$rootSite = Create-RootWebSite $name $sitePath
		$rootSite | Write-Debug
		Write-Debug "Processing Folders under $sitePath"
		#get each child folder under the /sites/ folder
		$siteFolders = (Get-ChildItem -Path $sitePath | ?{ $_.PSIsContainer }).fullname
		foreach ($siteFolder in $siteFolders)
		{
			Write-Debug "Processing folder: $siteFolder"
			#get just the ending folder name
			$siteFolderName = Split-Path -Path $siteFolder -leaf

			if (-not $siteFolderName.EndsWith(".obj")) #dont know why build creates .obj subfolders in the site folder, but they are not sites
			{
				$webApp = Get-WebApplication -Name $siteFolderName -Site $($rootSite.name) 

				if ($webApp)
				{
					Write-Debug "Skipping Application: $siteFolderName - Already Exists"
				}
				else
				{
					$poolName = $fqdn+"_"+$siteFolderName
					Write-Debug "Creating AppPool for sub-application: $poolName"
					$pool = Create-AppPool $poolName

					Add-AppPoolToSQL $poolName

					#create the sub-application
					Write-Debug "Creating Application: $siteFolderName"
					$webApp = New-WebApplication -Name $siteFolderName -Site $($rootSite.name) -PhysicalPath $siteFolder -ApplicationPool $poolName

					if ($netPipe -and ($siteFolderName -eq "integration"))
					{
						Enable-NetPipeProtocol $longName $siteFolderName
					}			
				}

			}
		}
	}
	finally
	{
		#cleanup any password info
		$password = ""
	}
}


function Configure-WebPWS ()
{
	$pwsPath = Join-Path $sitePath "webpws"
	if (Test-Path $pwsPath)
	{
		if ($netPipe)
		{
			$integrationOverrideBinding = "localhost/integration"
		}
		else {
			$integrationOverrideBinding="$fqdn/integration"	
		}
		

		$intCfgXml = "<IntegrationConfiguration><IntegrationServer>[SERVER-BINDING]</IntegrationServer></IntegrationConfiguration>"

		$intCfgXml = $intCfgXml.Replace("[SERVER-BINDING]", $integrationOverrideBinding)
		$intCfgXmlFile = Join-Path $pwsPath "IntegrationConfiguration.xml"

		New-Item -Path $intCfgXmlFile -Type file -Force
		$intCfgXml | Set-Content -Path $intCfgXmlFile

		Write-Output "Configuration File Created: $intCfgXmlFile"
		Write-Output "Integration Site: $integrationOverrideBinding"
	}
	else {
		Write-Output "PWS configuration skipped because the site folder does not exist."
	}
}

function Update-DBSettings() {
	if (!$skipDb)
	{
	
		$sqlConn = [J6SQLConnection]::new()

		$sql = "
create procedure #SetAppSetting
	@settingName nvarchar(100),
	@value nvarchar(1000)
as
begin
	declare @sid int, @vid int

	select @sid = id from AppSetting a where a.Name = @settingName

	if (@sid is null)
	begin
		declare @message nvarchar(1000)
		select @message = 'Setting `"'+@settingName+'`" not found';
		RAISERROR (@message, 51000, 1)
	end
	
	--clear off any user values
	delete from AppSettingValue where AppSetting = @sid and UserOverride = 1

	--get any existing jenkon values
	select @vid = id from AppSettingValue where AppSetting = @sid and IsOverride = 1

	if (@vid is null)
	begin
		insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride) values (@sid, @value, 1, 0)
	end
	else
	begin
		update AppSettingValue set Value = @value where id = @vid and IsOverride = 1
	end

	PRINT @settingName +' = ' + @value
end
"
		$data = $sqlConn.ExecuteNonquery($sql, 30)

		$sql = "exec #SetAppSetting 'BarcodeServerUrl', 'https://[fqdn]/employee/barcode.axd'".Replace("[fqdn]",$fqdn)
		$data = $sqlConn.ExecuteNonquery($sql, 30)

		$sql = "exec #SetAppSetting 'ConsultantWebSiteBaseURL', 'https://[fqdn]/business/'".Replace("[fqdn]",$fqdn)
		$data = $sqlConn.ExecuteNonquery($sql, 30)

		$sql = "exec #SetAppSetting 'EmployeeWebSiteBaseURL', 'https://[fqdn]/employee/'".Replace("[fqdn]",$fqdn)
		$data = $sqlConn.ExecuteNonquery($sql, 30)


		if (Test-Path ".\Site\WebPWS\WebPWS.csproj")
		{
			$sql = "exec #SetAppSetting 'PersonalWebSiteBaseURL', 'https://[fqdn]/webpws/'".Replace("[fqdn]",$fqdn)
			$data = $sqlConn.ExecuteNonquery($sql, 30)
			
			$sql = "exec #SetAppSetting 'PWS3_APIPath', 'https://[fqdn]/webpws/API'".Replace("[fqdn]",$fqdn)
			$data = $sqlConn.ExecuteNonquery($sql, 30)

			$sql = "exec #SetAppSetting 'PWS3_SitePath', 'https://[fqdn]/webpws/'".Replace("[fqdn]",$fqdn)
			$data = $sqlConn.ExecuteNonquery($sql, 30)
		}
	}
}



# -- MAIN CODE SECTION --
Ensure-Is64BitProcess
Ensure-IsPowershellMinVersion4
Ensure-IsAdmin
Ensure-IsJ6DevRootFolder

if ($remove)
{
	Remove-Site
	exit 0
}

Create-Site

Configure-WebPWS

Update-DBSettings
