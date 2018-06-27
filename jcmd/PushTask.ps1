<#
.SYNOPSIS
    Completes a change started by 'jcmd StartTask'.
.DESCRIPTION
	1. Checks for pending changes
	2. Checks to ensure this is a branch started with 'jcmd StartTask'
	3. Changes the current branch to the base branch used to start the task (such as 1002_PRD)
	4. Merges the task branch to the base branch
    5. Resolves all conflicts
    6. Optionally Commits Any Changes (resolved conflicts)
    7. Pushes the commits to the remote repo

	*Determines the correct source control commands to use for the folder repo.
    Mercurial and Git are supported.    
.EXAMPLE
    PS C:\> jcmd PushTask
.NOTES
    Created by Richard Carruthers on 06/25/18
    Based loosely on mercurial specific PushTask.ps1
#>
. "$PSScriptRoot\_shared\SourceControl\SourceControl.ps1"

if (SourceControl_HasPendingChanges)
{
	Write-Host "This branch has pending changes. Please commit first."
	Exit 1
}

$currentBranch = SourceControl_GetCurrentBranch
#we are going to merge the current branch back to the base branch
$mergeBranch = $currentBranch

$branchParts = $currentBranch -split "_"
if (($branchParts.Length -lt 4) -or (($branchParts | Where-Object {-not $_}).Count -gt 0))
{
	Write-Host "Cannot parse branch name for pushtask operation. Expected branch name format: TSK_[CustomerNumber]_[Environment]_[TaskId]" -ForegroundColor Red
	Exit 1
}

$taskPrefix = $branchParts[0]
$customerId = $branchParts[1]
$env = $branchParts[2]
$taskId = $branchParts[3]

if ($taskPrefix -ne "TSK")
{
	Write-Host "Branch does not appear to be started with 'jcmd StartTask'. Expected branch name format: TSK_[CustomerNumber]_[Environment]_[TaskId]" -ForegroundColor Red
	Exit 1
}

try {
    $baseBranch = "$customerId`_$env"
    Write-Host "UPDATING BRANCH TO '$baseBranch' FOR MERGING!!" -ForegroundColor Cyan
    SourceControl_SetBranch $baseBranch
    SourceControl_MergeToCurrentBranch $mergeBranch
    SourceControl_ResolveAllMergeConflicts
    if (SourceControl_HasPendingChanges)
    {
        SourceControl_Commit "PushTask Merging $mergeBranch to $baseBranch"
    }
    SourceControl_PushCommitsToRemote    
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "An unexpected error occured! You need to investigate the state of the repo and source folder to decide what to do now!" -ForegroundColor Red
    Exit 1
}
finally {
    $newCurrentBranch = SourceControl_GetCurrentBranch
    Write-Host "Your Current Branch is '$newCurrentBranch'" -ForegroundColor Yellow    
}


