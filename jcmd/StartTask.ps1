<#
.SYNOPSIS
    Prepares a j6 repo folder for a change to a specific tag such as UAT or PRD.
.DESCRIPTION
	1. Optionally calls a revertall (gets rid of junctions).
	2. Pulls the lastest code from the repository.
	3. Updates to the [TaskBaseTag] tag/branch (defaults to "[CustomerNumber]_PRD").
	4. Creates a new branch for this [TaskNumber] off of the tag/branch (defaults to "[CustomerNumber]_[TaskNumber]"..
	5. Makes this new branch the current branch.

	Determines the correct source control commands to use for the folder repo.
    Mercurial and Git are supported.
.PARAMETER CustomerNumber
	Specifies the 4 digit customer number. May also include trailing alpha characters
	for the market specifier. e.g. 2094 or 2094PER or 2097PL
.PARAMETER TaskNumber
	Specifies the work item task ID that is related to this change. This ID is used
	as part of the naming convention for task branch names.
.PARAMETER TaskBaseTag
	Specifies the tag name that represents the starting point for this change. Typically,
	this is "PRD", but it could be "UAT" or a customer specific identifier.
.PARAMETER SkipRevertAll
	Optionally skips the initial revertall step.
.EXAMPLE
    PS C:\> jcmd StartTask 2097PL TFS20121
.NOTES
    Created by Richard Carruthers on 06/25/18
    Based loosely on mercurial specific StartTask.ps1
#>
param(
	[Parameter(Mandatory=$true)][string]$CustomerNumber,
	[Parameter(Mandatory=$true)][string]$TaskNumber,
	[Parameter(Mandatory=$false)][string]$TaskBaseTag="PRD",
    [Parameter(Mandatory=$false)][switch]$SkipRevertAll
)
. "$PSScriptRoot\..\customerInfo.ps1"
. "$PSScriptRoot\_shared\SourceControlTasks\SourceControlTasks.ps1"

#Validate Customer Number
if ($validCustomers -NotContains $CustomerNumber) {
	$errorMessage = "$CustomerNumber is not a valid customer number"
	Write-Host $errorMessage -ForegroundColor Red
	Exit 1
}

$hasPendingChanges = SourceControl_HasPendingChanges
if ($hasPendingChanges -eq $true) {
	Write-Host "Pending changes found.  Please shelve or commit your changes before running starttask"
	Exit 1
}

if (!($SkipRevertAll)) { & jcmd revertall }

$startTag = [string]$CustomerNumber + '_' + $TaskBaseTag
$branchName = [string]$CustomerNumber + '_' + [string]$TaskNumber

SourceControl_Pull
#& h-g pull
if (SourceControl_BranchExists $branchName)
{
	Write-Host "Branch '$branchName' already exists. Switch to this branch manually, or choose a different TaskNumber" -ForegroundColor Red
	Exit 1
}

Write-Host "Updating to $startTag"
SourceControl_UpdateBranch $startTag

SourceControl_EnsureBranchUp $branchName


$currentBranch = SourceControl_GetCurrentBranch
if ($currentBranch -ne $branchName)
{
	Write-Host "Unexpected error! The current branch should be '$branchName' but it is actually '$currentBranch'." -ForegroundColor Red
	Exit 1
}

Write-Host "Don't forget to commit.  Working directory is now branch '$currentBranch'" -ForegroundColor Yellow
