. "$PSScriptRoot\SourceControlHg.ps1"
. "$PSScriptRoot\SourceControlGit.ps1"

function _SourceControl([string] $command, [string[]] $arguments) {
    #this is where the magic happens of picking the right repo command

    #figure out the type by looking for the repo folder
    $scType = "";
    if (Test-Path ".\.hg")
    {
        $scType = "Hg";
    }
    if (Test-Path ".\.git")
    {
        $scType = "Git";
    }

    #no repo folder, cannot proceed
    if (!($scType)) {
        throw "Cannot execute source control command on this folder. It is not a repository."
    }

    #take the original command and insert "hg" or "git" into the function name
    $command = $command -replace "SourceControl`_", "SourceControl$scType`_"
    
    #call the new function name with the old arguments
    $result = & $command @arguments
    return $result
}

function SourceControl_Commit([string] $message) {
    _SourceControl $MyInvocation.MyCommand $message
}

function SourceControl_CommitAndClose([string] $message) {
    _SourceControl $MyInvocation.MyCommand $message
}

function SourceControl_SetBranch([string] $branchName) {
    _SourceControl $MyInvocation.MyCommand $branchName
}

function SourceControl_UpdateBranchToHead([string] $branchName) {
    _SourceControl $MyInvocation.MyCommand $branchName
}

function SourceControl_PullRepoCommits() {
    _SourceControl $MyInvocation.MyCommand
}

function SourceControl_PushCommitsToRemote([switch] $newBranch) {
    _SourceControl $MyInvocation.MyCommand $newBranch
}

function SourceControl_MergeToCurrentBranch([string] $remoteBranch, [switch] $internalMerge) {
    _SourceControl $MyInvocation.MyCommand $remoteBranch,$internalMerge
}

function SourceControl_MergeSingleCommit([string] $commitRevision, [switch] $internalMerge) {
    _SourceControl $MyInvocation.MyCommand $commitRevision,$internalMerge
}

function SourceControl_ResolveAllMergeConflicts() {
    _SourceControl $MyInvocation.MyCommand
}

function SourceControl_RevertAll() {
    _SourceControl $MyInvocation.MyCommand
}

function SourceControl_GetOutgoingChanges([string] $branch) {
    _SourceControl $MyInvocation.MyCommand $branch
}

function SourceControl_HasPendingChanges() {
    _SourceControl $MyInvocation.MyCommand
}

function SourceControl_GetCurrentBranch() {
    _SourceControl $MyInvocation.MyCommand
}

function SourceControl_ForwardChangeCheck([string]$baseBranch, [string]$currentBranch) {
    _SourceControl $MyInvocation.MyCommand $baseBranch,$currentBranch
}

function SourceControl_NewBranch([string] $branch) {
    _SourceControl $MyInvocation.MyCommand $branch
}

function SourceControl_BranchExists($branch) {
    _SourceControl $MyInvocation.MyCommand $branch
}