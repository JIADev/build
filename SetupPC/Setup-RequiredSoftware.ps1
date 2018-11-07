. "$PSScriptRoot\_setupfunctions.ps1"

$global:localPackages = @{}
$global:localFeatures = @{}
$global:localInstalledApps = @{}
$global:localNpmPackages = @{}

#install windows OS optional features
function Install-RequiredWindowsFeatures()
{
	Write-Host "Ensuring Required Windows Features" -ForegroundColor Yellow
	Ensure-Feature Windows-Identity-Foundation
	Ensure-Feature NetFx3
	Ensure-Feature IIS-WebServerRole
	Ensure-Feature IIS-WebServer
	Ensure-Feature IIS-CommonHttpFeatures
	Ensure-Feature IIS-HttpErrors
	Ensure-Feature IIS-HttpRedirect
	Ensure-Feature IIS-ApplicationDevelopment
	
	Ensure-Feature IIS-HealthAndDiagnostics
	Ensure-Feature IIS-HttpLogging
	Ensure-Feature IIS-LoggingLibraries
	Ensure-Feature IIS-RequestMonitor
	Ensure-Feature IIS-HttpTracing
	Ensure-Feature IIS-Security
	Ensure-Feature IIS-RequestFiltering
	Ensure-Feature IIS-Performance
	Ensure-Feature IIS-WebServerManagementTools
	Ensure-Feature IIS-IIS6ManagementCompatibility
	Ensure-Feature IIS-Metabase
	Ensure-Feature WAS-WindowsActivationService
	Ensure-Feature WAS-ProcessModel
	Ensure-Feature WAS-ConfigurationAPI
	Ensure-Feature IIS-HostableWebCore
	Ensure-Feature IIS-StaticContent
	Ensure-Feature IIS-DefaultDocument
	Ensure-Feature IIS-DirectoryBrowsing
	Ensure-Feature IIS-WebSockets
	Ensure-Feature IIS-ApplicationInit
	Ensure-Feature IIS-ASPNET
	Ensure-Feature IIS-ASPNET45
	Ensure-Feature IIS-ISAPIExtensions
	Ensure-Feature IIS-ISAPIFilter
	Ensure-Feature IIS-ServerSideIncludes
	Ensure-Feature IIS-BasicAuthentication
	Ensure-Feature IIS-HttpCompressionStatic
	Ensure-Feature IIS-ManagementConsole
	Ensure-Feature IIS-HttpCompressionDynamic
	Ensure-Feature IIS-WindowsAuthentication
	Ensure-Feature IIS-CustomLogging
	
	Ensure-Feature MSMQ-Container
	Ensure-Feature MSMQ-Server
	Ensure-Feature MSMQ-Triggers
	Ensure-Feature MSMQ-HTTP
	Ensure-Feature MSMQ-Multicast
	Ensure-Feature MSMQ-ADIntegration
	

	Ensure-Feature WCF-Services45
	Ensure-Feature WCF-HTTP-Activation45
	Ensure-Feature WCF-TCP-Activation45
	Ensure-Feature WCF-Pipe-Activation45
	Ensure-Feature WCF-MSMQ-Activation45
	Ensure-Feature WCF-TCP-PortSharing45
	Ensure-Feature WCF-MSMQ-Activation45
	Ensure-Feature WCF-HTTP-Activation
	Ensure-Feature WCF-NonHTTP-Activation

	Ensure-Feature NetFx4-AdvSrvs
	Ensure-Feature NetFx4Extended-ASPNET45

	Ensure-Feature IIS-NetFxExtensibility
	Ensure-Feature IIS-NetFxExtensibility45
}
#constants
function Install-BaseTools()
{
	Write-Host "Ensuring Base Tools" -ForegroundColor Yellow
	#Ensure-Package "dotnet4.6.2"
	Ensure-Package "dotnet4.7.1"
	Ensure-Package "7zip"
	Ensure-Package "git"
	#Ensure-Package "hg"
	Ensure-Package "nuget.commandline"
	#Ensure-Package "tortoisehg"
	#Ensure-Package "redis" #NOT redis-64, that's v3 and doesnt install server
	Ensure-Package "GoogleChrome"
	Ensure-Package "FireFox"
}

function Install-JTools()
{
	Write-Host "Ensuring JTools" -ForegroundColor Yellow
	Ensure-Package "beyondcompare"
}


function Install-RecommendedTools()
{
	Write-Host "Ensuring Recommended Tools" -ForegroundColor Yellow

	Ensure-Package "notepadplusplus"
	Ensure-Package "agentransack"

	Ensure-Package "VisualStudioCode"
	Ensure-Package "vscode-powershell"
	Ensure-Package "vscode-csharp"
	Ensure-Package "vscode-mssql"
	Ensure-Package "vscode-markdownlint"
	Ensure-Package "vscode-jshint"
	#Ensure-Package "resharper"
}

function Install-DevelopmentIDEs()
{
	Write-Host "Ensuring Required IDE Features and Tools" -ForegroundColor Yellow
	Ensure-Package "VisualStudio2012Professional"
	Ensure-Package "visualstudio2012-update"
	if ($VS2015)
	{
		Ensure-Package "VisualStudio2015Professional"
	}
	if ($VS2017)
	{
		Ensure-Package "VisualStudio2017Professional"
	}
	Ensure-Package "sql-server-management-studio"
	Ensure-Package "sqlserverdatatools2012"
	Ensure-Package "ssdt17"
	Ensure-Package "nodejs"

	if (!(Test-NpmGlobalPackageInstalled "webpack"))
	{
		#load webpack
		Write-Host "Installing webpack globally using NPM" -ForegroundColor Yellow
		& npm install -g webpack
	}
}

function Ensure-Services()
{
	#Ensure-Service "Redis"
	Ensure-Service "MSDTC"
}

function Register-IIS
{
	Write-Host "Registering ASP.Net IIS Extensions."
	& C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -lv
}


try
{
	Write-Host "Beginning Software Setup..." -ForegroundColor Yellow

	#Main Code
	Ensure-Is64BitProcess
	Ensure-IsPowershellMinVersion4
	Ensure-IsAdmin

	if (Test-PendingReboot)
	{
		Write-Host "This machine has a pending required reboot. Please reboot and then re-run this script."
		Exit 1
	}

	#Ensure-DotNet462

	Install-RequiredWindowsFeatures
	Register-IIS

	Install-BaseTools
	Install-JTools
	Install-DevelopmentIDEs

	Ensure-Services

	if ($recommendedTools)
	{
		Install-RecommendedTools
	}

	#do this last, so that we know the path is ready to be processed
	#FYI, this is a critical step, otherwise the path is >2000 characters and 
	#powershell will not be able to find all the proper tools
	#specifically, this presents as "Cannot locate msbuild.exe"

	#Ensure-PathIsNotTooLong

	Write-Host "Software Setup Complete." -ForegroundColor Green
}
catch
{
	Write-Host "EXCEPTION:" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red

	Write-Host "FYI, This script is designed to be safe for re-execution at any time." -ForegroundColor Yellow
	Write-Host "Please address the error and re-run the script..." -ForegroundColor Yellow
}