$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\mercurialTasks.ps1"
. "$scriptPath\startGraftCommon.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools

$noComment = 'true'
$args | foreach {
      $noComment = 'false'
}

if($noComment -eq 'false') {
	& hg ci -m "$args"
	if($LastExitCode -ne 0) { 
		Write-Host "Commit failed"
		Exit
	}
}
$currentBranch = getCurrentBranch

if($currentBranch -eq '') { 
	Write-Host "Cannot determine my branch"
	Exit
}

$customerNumber = $currentBranch.Substring(0, $currentBranch.IndexOf('_'))

if($customerNumber -eq '') {
	Read-Host "Customer Number? (i.e. 2094, 2095, 2096)"
}

validateCustomer $customerNumber
$ongoingBranch = $pushTaskBranches[[string]$customerNumber]

Write-Host "Closing branch $currentBranch"
& hg ci -m "Completing task" --close-branch
if($LastExitCode -ne 0) { 
	Write-Host "Closing task branch failed"
	Exit
}

if($ongoingBranch -ne '') {
Write-Host "Updating to branch $ongoingBranch"
& hg up $ongoingBranch
if($LastExitCode -ne 0) { 
	Write-Host "Cannot update to $ongoingBranch"
	Exit
}

Write-Host "Merging $currentBranch to $ongoingBranch"
& hg merge $currentBranch
if($LastExitCode -ne 0) { 
	Write-Host "Cannot merge $currentBranch to $ongoingBranch"
	Exit
}

Write-Host "Committing Merge"
& hg ci -m "@merge $currentBranch"
}

$currentDir = Convert-Path .

& hg outgoing
$confirmation = Read-Host "This will push these changes in $currentDir to the server. (y/n?)"
if($confirmation -eq 'y') {
  & hg push --new-branch
  if($LastExitCode -ne 0) { 
	Write-Host "Cannot push"
	Exit
  }
} else {
  Write-Host "Not pushed, updating to $currentBranch"
  & hg up $currentBranch
}

$currentBranch = getCurrentBranch
Write-Host "Current Branch $currentBranch"
