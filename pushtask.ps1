$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\mercurialTasks.ps1"
. "$scriptPath\customerInfo.ps1"
. "$scriptPath\startGraftCommon.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools

$mergeSwitch = ''
$noComment = 'true'
$args | foreach {
      if([string]$_ -eq '--tool=internal:merge') {
      	$mergeSwitch = $_
      } else {
            $noComment = 'false'
	}
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

$underscore = $currentBranch.IndexOf('_')
$customerNumber = ''

if($underscore -lt 1) {
	Write-Host "Can't determine customer number from branch name: "$currentBranch
} else {
  $customerNumber = $currentBranch.Substring(0, $underscore)
}

if($customerNumber -eq '') {
	$customerNumber = Read-Host "Customer Number? (i.e. 2094, 2095, 2096)"
}

validateCustomer $customerNumber
$ongoingBranches = $pushTaskBranches[[string]$customerNumber]
$pushBranch = $currentBranch

if($ongoingBranches) {
	foreach($ongoingBranch in $ongoingBranches) {
		Write-Host "Pulling from server"
		& hg pull
		if($pushBranch -eq $currentBranch -and $pushBranch -ne $ongoingBranch) {
			Write-Host "Closing branch $currentBranch"
			& hg ci -m "Completing task @build" --close-branch
		}
		if($ongoingBranch -ne '') {
			Write-Host "Updating to branch $ongoingBranch"
			& hg up $ongoingBranch
			if($LastExitCode -ne 0) { 
				Write-Host "Cannot update to $ongoingBranch"
				Exit
			}

			if($pushBranch -ne $ongoingBranch) {
				Write-Host "Merging $pushBranch to $ongoingBranch"
				& hg merge $pushBranch $mergeSwitch
				if($LastExitCode -ne 0) { 
					& hg resolve --all
					if($LastExitCode -ne 0) { 
						Write-Host "Cannot merge $pushBranch to $ongoingBranch"
						Exit
					}
				}
			}
			Write-Host "Committing Merge"
			& hg ci -m "@merge $pushBranch"
			$pushBranch = $ongoingBranch
		}
	}	
} else {
	if($pushBranch -eq $currentBranch) {
		Write-Host "Closing branch $currentBranch"
		& hg ci -m "Completing task @build" --close-branch
	}
}

$currentDir = Convert-Path .

& hg outgoing -b $pushBranch
$confirmation = Read-Host "This will push these changes in $currentDir to the server. (y/n?)"
if($confirmation -eq 'y') {
	pushChanges $pushBranch
} else {
  Write-Host "Not pushed, updating to $currentBranch"
  & hg up $currentBranch
}

$currentBranch = getCurrentBranch
Write-Host "Current Branch $currentBranch"
