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
.PARAMETER baseBranch
  The remote branch that may contain extra commits.
.PARAMETER childBranch
  The branch that should be checked for missing commits.
  *Defaults to the branch of the current folder if not specified.
.EXAMPLE
  PS C:\dev\project_folder>jcmd ForwardChangeCheck 7.0.0 7.0.0_Customer1002
  
  Outputs the first 10 revisions found that are in 7.0.0 but not in 
  7.0.0_Customer1002 and exits with an error code of 1. 
  If no revisions are found, no output is given and the command exits with a
  normal exit code (0).
.OUTPUTS
  Returns nothing if all commits are found.
  Otherwise, returns list of missing commits.
.NOTES
  Uses source control scripts for Git and Hg to execute the appropriate
  repository commands.
#>
param(
    [Parameter(Mandatory=$true)][string] $baseBranch,
    [Parameter(Mandatory=$false)][string] $childBranch
)

. "$PSScriptRoot\_Shared\common.ps1"
. "$PSScriptRoot\_Shared\SourceControl\SourceControl.ps1"

Ensure-IsPowershellMinVersion5
Ensure-IsJ6DevRootFolder

if (!($childBranch))
{
    $childBranch = SourceControl_GetCurrentBranch
}

$missingRevisions = SourceControl_ForwardChangeCheck $baseBranch $childBranch
if ($missingRevisions)
{
    Write-ColorOutput "The following revisions would be reverted (limited to 10):" -ForegroundColor Red
    Write-ColorOutput $missingRevisions -ForegroundColor Red
    Exit 1
}
