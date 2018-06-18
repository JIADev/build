$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$scriptPath\customerInfo.ps1"
."$scriptPath\startgraftCommon.ps1"
Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools $scriptPath

$usageMessage = 'Usage: graftchanges <customerNumber> <RM or TFS Number> <graft Revision list> Example: graftchanges 2095 TFS01234 9e68964c958d 6fa376e28672 307ccb5f019d'

function ensureGraftRevisions($graftRevision) {
if($graftRevision.Length -eq 0) { 
	Write-Host "No graft revisions listed"
	Write-Host $usageMessage
	Exit
}
}


$config = parseArgs $args
validateCustomer $config.customerNumber
ensureGraftRevisions $config.graftRevision
setupBranch $config.customerNumber $config.taskNumber $config.graftRevision $config.revertall

$config.graftRevision | foreach {
	
	hg graft $_ --tool=internal:merge
	if($LastExitCode -ne 0) { 
		hg resolve --all
		hg graft --continue	
	}
}
$currentBranch = getCurrentBranch

Write-Host "Working directory is now marked as branch $currentBranch"

& "$scriptPath\pushtask.ps1"
