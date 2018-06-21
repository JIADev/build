. "$PSScriptRoot\SourceControlLowLevelFunctionsHg.ps1"
. "$PSScriptRoot\SourceControlLowLevelFunctionsGit.ps1"

function SourceControl_Commit([string] $message) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit $message
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit $message
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
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
    Throw "Cannot execute source control command on this folder. It is not a repository."
}