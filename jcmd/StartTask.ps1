<#
.SYNOPSIS
  Prepares a j6 repo folder for a change to a specific tag such as UAT or PRD.
.DESCRIPTION
  1. Optionally calls a revertall (gets rid of junctions).
  2. Updates the local repository with the latest commits from the remote.
  3. Updates to the [EnvironmentCode] tag (defaults to "[CustomerId]_PRD").
  4. Creates a new branch for this [TaskId] off of the tag/branch (defaults to "[CustomerId]_[TaskId]"..
  5. Makes this new branch the current branch.

  *Determines the correct source control commands to use for the folder repo.
  Mercurial and Git are supported.
.PARAMETER CustomerId
  Specifies the 4 digit customer number. May also include trailing alpha characters
  for the market specifier. e.g. 2094 or 2094PER or 2097PL
.PARAMETER TaskId
  Specifies the work item task ID that is related to this change. This ID is used
  as part of the naming convention for task branch names.
.PARAMETER EnvironmentCode
  Specifies the environment or branch suffix that represents the starting point 
  for this change. Typically,	this is "PRD", but it could be "UAT" or a customer
  specific identifier. The starting branch will be [CustomerId]_[EnvironmentCode]
  such as 2097PL_PRD
.PARAMETER SkipRevertAll
  Optionally skips the initial revertall step.
.EXAMPLE
  PS C:\> jcmd StartTask 2097PL TFS20121
.NOTES
  Created by Richard Carruthers on 06/25/18
  Based loosely on mercurial specific StartTask.ps1
#>
param(
	[Parameter(Mandatory=$true)][string]$CustomerId,
	[Parameter(Mandatory=$true)][string]$TaskId,
	[Parameter(Mandatory=$false)][string]$EnvironmentCode="PRD",
    [Parameter(Mandatory=$false)][switch]$SkipRevertAll
)
. "$PSScriptRoot\_Shared\common.ps1"
. "$PSScriptRoot\_shared\SourceControl\SourceControl.ps1"

$hasPendingChanges = SourceControl_HasPendingChanges
if ($hasPendingChanges -eq $true) {
	Write-ColorOutput "Pending changes found.  Please shelve or commit your changes before running starttask" Red
	Exit 1
}

$startBranch = $CustomerId + '_' + $EnvironmentCode
$branchName = "TSK" + '_' + $startBranch + '_' + $TaskId
SourceControl_PullRepoCommits
if (!((SourceControl_TagExists $startBranch) -or (SourceControl_BranchExists $startBranch)))
{
	Write-ColorOutput "Base tag (or branch) '$startBranch' not found!" Red
	Exit 1
}

if (SourceControl_BranchExists $branchName)
{
	Write-ColorOutput "Branch '$branchName' already exists. Switch to this branch manually, or choose a different TaskId" -ForegroundColor Red
	Exit 1
}

if (!($SkipRevertAll)) { & jcmd revertall }

Write-ColorOutput "Setting current branch to $startBranch..."
SourceControl_SetBranch $startBranch

Write-ColorOutput "Creating branch $branchName..."
SourceControl_NewBranch $branchName

$currentBranch = SourceControl_GetCurrentBranch
if ($currentBranch -ne $branchName)
{
	Write-ColorOutput "Unexpected error! The current branch should be '$branchName' but it is actually '$currentBranch'." -ForegroundColor Red
	Exit 1
}

Write-ColorOutput "Don't forget to commit.  Working directory is now branch '$currentBranch'" -ForegroundColor Yellow
