$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if (test-path ".\.git")
{
	& "$scriptPath\jcmd.ps1" StartTask $args
	exit $LastExitCode
}

$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$scriptPath\customerInfo.ps1"
. "$scriptPath\startgraftCommon.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools $scriptPath

$usageMessage = 'Usage: starttask <customerNumber> <RM or TFS Number> [<additional Revisions>]
Examples:
 starttask 2095 TFS01234
 starttask 2094 RM23456 RM12345
 starttask 2094 RM34567 UAT'

$config = parseArgs $args
validateCustomer $config.customerNumber
setupBranch $config.customerNumber $config.taskNumber $config.graftRevision $config.revertall

$config.graftRevision | foreach {
	$mergeBranch = [string]$config.customerNumber + '_' + $_
	
	hg merge $mergeBranch --tool=internal:merge
	if($LastExitCode -ne 0) { 
		hg resolve --all
	}
	hg ci -m "@merge $mergeBranch"
}
$currentBranch = getCurrentBranch

Write-Host "Don't forget to hg commit.  Working directory is now branch $currentBranch"
