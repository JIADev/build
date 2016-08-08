$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$scriptPath\uatCustomerInfo.ps1"
."$scriptPath\startgraftCommon.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools $scriptPath

$usageMessage = 'Usage: startqatask <customerNumber> <RM or TFS Number> Example: starttask 2095 TFS01234'

$config = parseArgs $args
validateCustomer $config.customerNumber
setupBranch $config.customerNumber $config.taskNumber $config.graftRevision $config.revertall

$currentBranch = getCurrentBranch

Write-Host "This script no longer auto-commits the initial $currentBranch revision.  (Don't forget to hg commit.)  Working directory is now marked as branch $currentBranch"