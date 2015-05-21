$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
. "$scriptPath\mercurialTasks.ps1"

updateBuildTools

Write-Host "Version 2"

$ongoingBranch = '2095_QA2015.05.19'
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

& hg ci -m "Completing task" --close-branch
if($LastExitCode -ne 0) { 
	Write-Host "Closing task branch failed"
	Exit
}
$currentBranch = getCurrentBranch

if($currentBranch -eq '') { 
	Write-Host "Cannot determine my branch"
	Exit
}

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

& Write-Host "hg push --new-branch"

