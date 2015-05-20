$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateBuildToolsRepo $scriptPath\buildtools.proj
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
$comment = "Starting task " + [string]$taskNumber
& hg pull
if($revertall -eq $true) {
	      & $msbuild /t:RevertAll $scriptPath\buildtools.proj
}
Write-Host "Updating to $startTag"
& hg up $startTag
& hg up
& hg branch $branchName
& hg ci -m "$comment"
Write-Host "Working directory is now on branch $branchName"
