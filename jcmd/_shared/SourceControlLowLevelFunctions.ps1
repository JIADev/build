. "$PSScriptRoot\SourceControlLowLevelFunctionsHg.ps1"
. "$PSScriptRoot\SourceControlLowLevelFunctionsGit.ps1"

function SourceControl_Commit([string] $message, [switch] $closeBranch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_CommitAndClose([string] $message) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_SetBranch([string] $branchName) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_UpdateBranch([string] $branchName) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_Pull() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_Push([string[]] $options) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_Merge([string] $remoteBranch, [switch] $internalMerge) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_Graft([string] $commitRevision, [switch] $internalMerge) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_ResolveAll() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_RevertAll() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_GetOutgoingChanges([string] $branch) {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_HasPendingChanges() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}

function SourceControl_GetCurrentBranch() {
    if (Test-Path ".\.hg")
    {
        return SourceControlHg_Commit($message, $closeBranch)
    }
    if (Test-Path ".\.git")
    {
        return SourceControlGit_Commit($message, $closeBranch)
    }
    Throw "Cannot execute source control command on this folder. It is not a repository."
}