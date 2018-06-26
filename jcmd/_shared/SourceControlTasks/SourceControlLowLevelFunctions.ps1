. "$PSScriptRoot\SourceControlLowLevelFunctionsHg.ps1"
. "$PSScriptRoot\SourceControlLowLevelFunctionsGit.ps1"

function SourceControl_ErrorNoRepo
{
    throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_Commit([string] $message) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit $message
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit $message
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_CommitAndClose([string] $message) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_CommitAndClose $message
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_CommitAndClose $message
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_SetBranch([string] $branchName) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_SetBranch $branchName
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_SetBranch $branchName
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_UpdateBranch([string] $branchName) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_UpdateBranch $branchName
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_UpdateBranch $branchName
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_Pull() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Pull
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Pull
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_Push([switch] $newBranch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Push $newBranch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Push $newBranch
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_Merge([string] $remoteBranch, [switch] $internalMerge) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Merge $remoteBranch $internalMerge
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Merge $remoteBranch $internalMerge
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_Graft([string] $commitRevision, [switch] $internalMerge) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Graft $commitRevision $internalMerge
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Graft $commitRevision $internalMerge
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_ResolveAll() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_ResolveAll
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_ResolveAll
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_RevertAll() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_RevertAll
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_RevertAll
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_GetOutgoingChanges([string] $branch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_GetOutgoingChanges $branch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_GetOutgoingChanges $branch
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_HasPendingChanges() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_HasPendingChanges
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_HasPendingChanges
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_GetCurrentBranch() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_GetCurrentBranch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_GetCurrentBranch
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_ForwardChangeCheck([string]$baseBranch, [string]$currentBranch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_ForwardChangeCheck $baseBranch $currentBranch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_ForwardChangeCheck $baseBranch $currentBranch
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_NewBranch([string] $branch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_NewBranch $branch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_NewBranch $branch
    }
    SourceControl_ErrorNoRepo
}

function SourceControl_BranchExists($branch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_BranchExists $branch
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_BranchExists $branch
    }
    SourceControl_ErrorNoRepo
}