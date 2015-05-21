$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$scriptPath\mercurialTasks.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools

$validCustomers = '000', '065', '069', '077', '2082', '2083', '2085', '2086', '2087', '2088', '2089', '2090', '2092', '2094', '2095', '2096'
$uatCustomers = '2094', '2095', '2096'
$usageMessage = 'Usage: starttask <customerNumber> <RM or TFS Number> Example: starttask 2095 TFS01234'
$customerNumber = ''
$taskNumber = ''
$startEnv = 'PRD'
$revertall = $false

$args | foreach {
      if('--revertall' -eq $_ ) {
        $revertall = $true
      } else {
      if($customernumber -eq '') {
      	$customernumber = $_
      } else {
      	if($taskNumber -eq '') {
      		       $taskNumber = $_
      		       }
      } }
}
if($validCustomers -NotContains [string]$customerNumber) {
	$errorMessage = [string]$customerNumber + " is not a valid customer number"
	Write-Host $errorMessage
	Write-Host $usageMessage
	Exit
}
if($uatCustomers -Contains $customerNumber) {
	$startEnv = 'UAT'
}
$startTag = [string]$customerNumber + '_' + $startEnv
$branchName = [string]$customerNumber + '_' + [string]$taskNumber

& hg pull
if($LastExitCode -ne 0) { 
	Write-Host "hg pull failed"
	Exit
}
if($revertall -eq $true) {
	      & $msbuild /t:RevertAll $scriptPath\buildtools.proj
}
Write-Host "Updating to $startTag"
& hg up $startTag
if($LastExitCode -ne 0) { 
	Write-Host "Cannot update to $startTag"
	Exit
}
& hg up
if($LastExitCode -ne 0) { 
	Write-Host "Cannot update to tip of $startTag"
	Exit
}
& hg branch $branchName
if($LastExitCode -ne 0) { 
	Write-Host "Cannot mark working directory as $branchName"
	Exit
}

Write-Host "This script no longer auto-commits the initial $branchName revision.  (Don't forget to hg commit.)  Working directory is now marked as branch $branchName"
