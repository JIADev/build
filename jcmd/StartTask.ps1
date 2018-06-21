$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$PSScriptRoot\..\customerInfo.ps1"
. "$PSScriptRoot\_shared\startgraftCommon.ps1"

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
	
	#h-g merge $mergeBranch --tool=internal:merge
	SourceControl_Merge $mergeBranch $true
	if($LastExitCode -ne 0) { 
		#h-g resolve --all
		SourceControl_ResolveAll
	}
	#h-g ci -m "@merge $mergeBranch"
	SourceControl_Commit "@merge $mergeBranch" $false
}
$currentBranch = getCurrentBranch

Write-Host "Don't forget to commit.  Working directory is now branch $currentBranch"
