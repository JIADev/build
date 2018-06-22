<#
.SYNOPSIS
    Raises an error if a one branch contains commits that are not in another branch.
.DESCRIPTION
    Used to detect commits to a base branch that should be applied to a child branch 
    before deployment.

    Example:
    There is a version 7.0.0 branch in j6, and you start a project from there by creating
    a new branch. At some point, a bug is fixed in the base branch, but that commit was 
    not merged to your branch.

    This command will raise an error in this case so that you will be forced to merge
    the new core changes into your branch.
.EXAMPLE
    PS C:\dev\project_folder>jcmd ForwardChangeCheck 7.0.0 7.0.0_Customer1002
    Outputs the first 10 revisions found that are in 7.0.0 but not in 
    7.0.0_Customer1002 and exits with an error code of 1. 
    If no revisions are found, no output is given and the command exits with a
    normal exit code (0).
.INPUTS
    BaseBranch: Branch with commits that should be returned if they do not exist
    ChildBranch: Branch that may be missing commits from BaseBranch
.OUTPUTS
    Returns nothing if all commits are found.
    Otherwise, returns list of missing commits.
.NOTES
    Uses source control scripts for Git and Hg to execute the appropriate
    repository commands.
#>
param(
    [string] $baseBranch,
    [string] $childBranch
)
. "$PSScriptRoot\_Shared\SourceControlTasks\SourceControlLowLevelFunctions.ps1"

$missingRevisions = SourceControl_ForwardChangeCheck $baseBranch $childBranch
if ($missingRevisions)
{
    Write-Host "The following revisions would be reverted (limited to 10):" -ForegroundColor Red
    $missingRevisions | Write-Host -ForegroundColor Red
    Exit 1
}
