<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
	 Created on:   	10/20/2017 13:25
	 Created by:   	jcollins
	 Organization: 	
	 Filename:     	deployJenkinsLoadRpt.ps1
	===========================================================================
	.DESCRIPTION
		This is the script for Jenkins to load reports to the new report server.  
		Previously used ReportLoader.  Will be creating a new solution that moves all reports to 'Report' folder 
		and then uses PS and SSRS proxy to load the reports.
#>

param
(
	[Parameter(Mandatory = $true)]
	[string]$driver,
	[string]$config_json,
	[string]$deploy_env
)

#Create Credential object from ecrypted password file
$jenkinsUserName = "jenkon\CCNet_new"
$jenkinsPassword = Get-Content -Path "C:\JCJenkins\securePassword.txt" | ConvertTo-SecureString
$credentials = New-Object System.Management.Automation.PSCredential($jenkinsUserName, $jenkinsPassword)

#$workingDirectory = "$($ENV:WORKSPACE)"
$workingDirectory = "C:\JCJenkins\workspace\1002"
$reportsDir = "$workingDirectory\RELEASE"
$json = Get-Content $config_json -Raw | ConvertFrom-Json

$reports = gci -Path $reportsDir -Filter *.rdl -Recurse | select -ExpandProperty FullName
$reportPath = "/"
$reportFolder = $json.$driver.environments.$deploy_env.reports.reportFolder
$isOverwriteDataSource = 1
$isOverwriteDataSet = 0
$isOverwriteReport = 1


$webServiceURL = $json.$driver.environments.$deploy_env.reports.reportURL
$proxyPath = "$webServiceURL/ReportService2010.asmx?WSDL"

#Connect to SSRS

Write-Host "ReportServer: $webServiceURL"
Write-Host "Creating Proxy, connecting to : $proxyPath"
Write-Host ""
$ssrsProxy = New-WebServiceProxy -Uri $proxyPath -Credential $credentials

$reportFolder_Final = $reportPath + $reportFolder

#Create needed Datasources in case they aren't already there.
$proxyNamespace = $ssrsProxy.gettype().Namespace
$datasourceDef = New-Object("$proxyNameSpace.DataSourceDefinition")
$reportDBServer = $json.$driver.environments.$deploy_env.sql.hostname
$reportDB = $json.$driver.environments.$deploy_env.reports.dbName
$connectionString = "server=$reportDBServer;Initial Catalog=$reportDB"
$datasourceDef.connectionstring = $connectionString
$datasourceDef.Extension = "SQL"
$datasourceDef.WindowsCredentials = $WindowsCredentials
$datasourceDef.password = $password
$datasourceDef.CredentialRetrieval = $credentialRetrieval
$datasourceDef.username = $username

#Deploy Reports

foreach ($report in $reports)
{
	Write-Host ""
	
	#Report Name
	$reportName = [System.IO.Path]::GetFileName($report);
	Write-Host "Deploying $reportName"
	
	try
	{
		Write-Host "Getting file content of $report"
		$byteArray = Get-Content $report -Encoding byte
		
		Write-Host "Uploading to: $reportFolder_Final"
		
		$type = $ssrsProxy.GetType().Namespace
		$dataType = ($type + '.Property')
		
		$descProp = New-Object($dataType)
		$descProp.Name = "Description"
		$descProp.Value = ""
		$hiddenProp = New-Object($dataType)
		$hiddenProp.Name = "Hidden"
		$hiddenProp.Value = "false"
		$properties = @($descProp, $hiddenProp)
		
		#Call proxy to upload report
		
		$warnings = $null
		
		$results = $ssrsProxy.CreateCatalogItem("Report", $reportName, $reportFolder_Final, $isOverwriteReport, $byteArray, $properties, [ref]$warnings)
		
		if ($warnings.length -le -1)
		{
			Write-Host "Upload Success."
		}
		else
		{
			
			foreach ($warning in $warnings) {
				Write-Host $warning.message
			}
#			Write-Host "$warnings"
		}
		
	}
	catch [System.IO.IOException]
	{
		$msg = "Error while reading rdl file: '{0}', Message: '{1}'" -f $report, $_.Exception.Message
		Write-Host $msg
	}
	catch [System.Web.Services.Protocols.SoapException]
	{
		$msg = "Error uploading report: $reportName. Msg: '{0}'" -f $_.Exception.Message
		Write-Host $msg
	}
	
	#Change report datasource
	$repoFullName = "$reportFolder_Final/$reportName"
	Write-Host "Datasource record $repoFullName"
	
	$rep = $ssrsProxy.GetItemDatasources($repoFullName)
	$rep | ForEach-Object {
		$proxyNamespace = $_.GetType().Namespace
		
		$constDatasource = New-Object("$proxyNamespace.DataSource")
		$constDatasource.Item = New-Object("$proxyNamespace.DataSourceReference")
		$finalDatasourcePath = $reportPath + "/" + $($_.Name)
		$constDatasource.Item.Reference = $finalDatasourcePath
		
		$_.Item = $constDatasource.Item
		$ssrsProxy.SetItemDataSources($repoFullName, $_)
		Write-Host "Changing datasource `"$($_.Name)`" to $($_.Item.Reference)"
	}
	
}

Write-Host ""
Write-Host "Reports deployment complete."
Write-Host ""
