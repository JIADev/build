. "$scriptPath\mercurialTasks.ps1"
. "$scriptPath\customerInfo.ps1"
function parseArgs([array]$params) {
$config = [pscustomobject]@{
customerNumber = [string]''
taskNumber = [string]''
graftRevision = [array]@()
revertall = [bool]$false
}
$params | foreach {
	if('--revertall' -eq $_ ) {
		$config.revertall = $true
    } else {
		if($config.customerNumber -eq '') {
			$config.customerNumber = [string]$_
		} else {
			if($config.taskNumber -eq '') {
				$config.taskNumber = [string]$_
			} else {
				$config.graftRevision = $config.graftRevision + @( $_ )
			}
		} 
	}
}
return $config
}

function validateCustomer([string]$customerNumber) {
if($validCustomers -NotContains $customerNumber) {
	$errorMessage = $customerNumber + " is not a valid customer number"
	Write-Host $errorMessage
	Write-Host $usageMessage
	Exit
}
}

function setupBranch([string]$customerNumber, [string]$taskNumber, [array]$graftRevision, [bool]$revertall) {
$startEnv = $tagOverrides[[string]$customerNumber]
if($startEnv -eq $null) {
	$startEnv = 'PRD'
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

$branchCreated = ensureBranchUp $branchName
if($branchCreated -ne 0) { 
	Write-Host "Cannot create or update to $branchName"
	Exit
}
}


