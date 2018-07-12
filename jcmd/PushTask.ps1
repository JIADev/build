<#
.SYNOPSIS
  Completes a change started by 'jcmd StartTask'.
.DESCRIPTION
  1. Checks for pending changes
  2. Checks to ensure this is a branch started with 'jcmd StartTask'
  3. Merge the environment tag back into this branch in case it has 
     moved since this branch was create
  3. Changes the current branch to the base branch used to start the
     task (such as 2094_PeruInfra)
  4. Merges the task branch to the base branch
  5. Resolves all conflicts
  6. Optionally Commits Any Changes (resolved conflicts)
  7. Pushes the commits to the remote repo

  *Determines the correct source control commands to use for the folder repo.
  Mercurial and Git are supported.    
.PARAMETER BaseCustomerBranch
  Specifies the branch that these changes should be merged into so that they
  will be included in the next regular release.
.EXAMPLE
  PS C:\> jcmd PushTask 2094_PeruInfra
.NOTES
  Created by Richard Carruthers on 06/25/18
  Based loosely on mercurial specific PushTask.ps1
#>
param(
	[Parameter(Mandatory=$true)][string]$BaseBranch
)

. "$PSScriptRoot\_Shared\common.ps1"
. "$PSScriptRoot\_shared\SourceControl\SourceControl.ps1"

if (SourceControl_HasPendingChanges)
{
	Write-ColorOutput "This branch has pending changes. Please commit first."
	Exit 1
}

$currentBranch = SourceControl_GetCurrentBranch
#we are going to merge the current branch back to the base branch
$branchParts = $currentBranch -split "_"
if (($branchParts.Length -lt 4) -or (($branchParts | Where-Object {-not $_}).Count -gt 0))
{
	Write-ColorOutput "Cannot parse branch name for pushtask operation. Expected branch name format: TSK_[CustomerNumber]_[Environment]_[TaskId]" -ForegroundColor Red
	Exit 1
}

$mergeBranch = $currentBranch
$taskPrefix = $branchParts[0]
$customerId = $branchParts[1]
$env = $branchParts[2]
$taskId = $branchParts[3]

if ($taskPrefix -ne "TSK")
{
	Write-ColorOutput "Branch does not appear to be started with 'jcmd StartTask'. Expected branch name format: TSK_[CustomerNumber]_[Environment]_[TaskId]" -ForegroundColor Red
	Exit 1
}

$envTag = "$customerId`_$env"
Write-ColorOutput "Checking for updates to the env tag '$envTag' FOR MERGING!!" -ForegroundColor Cyan
#see if there are any changes in the env tag that are not in 
& "$PSScriptRoot\ForwardChangeCheck.ps1" $envTag
if ($LASTEXITCODE -ne 0)
{
	Write-ColorOutput "This starttask was branch from '$envTag', but that tag has new commits." -ForegroundColor Red
  Write-ColorOutput "You must manually merge that tag into this branch and resolve any issues!" -ForegroundColor Red
  Write-ColorOutput "`git merge $envTag` should be the command you need to execute" -ForegroundColor Yellow
	Exit 1
}
Write-ColorOutput "--No changes detected." -ForegroundColor Cyan

Write-ColorOutput "UPDATING BRANCH TO '$baseBranch' FOR MERGING!!" -ForegroundColor Cyan
try {
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
    Write-ColorOutput $_.Exception.Message -ForegroundColor Red
    Write-ColorOutput "An unexpected error occured! You need to investigate the state of the repo and source folder to decide what to do now!" -ForegroundColor Red
    Exit 1
}
finally {
    $newCurrentBranch = SourceControl_GetCurrentBranch
    Write-ColorOutput "Your Current Branch is '$newCurrentBranch'" -ForegroundColor Yellow    
}
