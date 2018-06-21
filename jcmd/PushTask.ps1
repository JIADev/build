. "$PSScriptRoot\..\customerInfo.ps1"
. "$PSScriptRoot\_shared\startGraftCommon.ps1"

$mergeSwitch = $false
$noComment = 'true'
$args | foreach {
      if([string]$_ -eq '--tool=internal:merge') {
      	$mergeSwitch = $true
      } else {
            $noComment = 'false'
	}
}

if($noComment -eq 'false') {
	#& h-g ci -m "$args"
	SourceControl_Commit "$args"
	if($LastExitCode -ne 0) { 
		Write-Host "Commit failed"
		Exit
	}
}
$currentBranch = SourceControl_GetCurrentBranch

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
		#& h-g pull
		SourceControl_Pull
		if($pushBranch -eq $currentBranch -and $pushBranch -ne $ongoingBranch) {
			Write-Host "Closing branch $currentBranch"
			#& h-g ci -m "Completing task @build" --close-branch
			SourceControl_CommitAndClose "Completing task @build"
		}
		if($ongoingBranch -ne '') {
			Write-Host "Updating to branch $ongoingBranch"
			#& h-g up $ongoingBranch
			SourceControl_SetBranch $ongoingBranch
			SourceControl_Pull

			if($pushBranch -ne $ongoingBranch) {
				Write-Host "Merging $pushBranch to $ongoingBranch"
				#& h-g merge $pushBranch $mergeSwitch
				SourceControl_Merge $pushBranch $mergeSwitch
			}
			Write-Host "Committing Merge"
			#& h-g ci -m "@merge $pushBranch"
			SourceControl_Commit "@merge $pushBranch"
			$pushBranch = $ongoingBranch
		}
	}	
} else {
	if($pushBranch -eq $currentBranch) {
		Write-Host "Closing branch $currentBranch"
		#& h-g ci -m "Completing task @build" --close-branch
		SourceControl_CommitAndClose "Completing task @build"
	}
}

$currentDir = Convert-Path .

#& h=g outgoing -b $pushBranch
SourceControl_GetOutgoingChanges $pushBranch
$confirmation = Read-Host "This will push these changes in $currentDir to the server. (y/n?)"
if($confirmation -eq 'y') {
	SourceControl_pushChanges $pushBranch
} else {
  Write-Host "Not pushed, updating to $currentBranch"
  #& h-g up $currentBranch
  SourceControl_UpdateBranch $currentBranch
}

$currentBranch = getCurrentBranch
Write-Host "Current Branch $currentBranch"
