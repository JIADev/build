function WriteGitError([string]$cmd, [string]$output)
{
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
    Write-ColorOutput "Git Command Failed: $cmd " -ForegroundColor Red
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
    Write-ColorOutput $output -ForegroundColor Red
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
}

function gitcmd([string[]] $arguments, [switch]$DoNotExitOnError){
    $cmd = "git.exe"
    Write-Debug "$cmd $arguments"
    
    $output = ((& $cmd @arguments) | Out-String)
    $success = $?
    if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}
    if ((!$success -or ($exitCode -gt 0)) -and !$DoNotExitOnError)
    {
        WriteGitError "$cmd $arguments" $output
        Exit $exitCode
    }

    $lines = $output -split "`r`n"
    return $lines
}

function SourceControlGit_Commit([string] $message) {
    gitcmd commit,-a,-m,$message
}

function SourceControlGit_CommitAndClose([string] $message) {
    SourceControlGit_Commit $message

    #now tag and remove the branch - Git doesnt have a "close" branch
    $branchName = SourceControlGit_GetCurrentBranch
    $closedTag = "Closed-$branchName"
    gitcmd tag,$closedTag,$branchName
    gitcmd branch,-d,$branchName
}

function SourceControlGit_SetBranch([string] $branchName) {
    gitcmd checkout,$branchName
}

function SourceControlGit_UpdateBranchToHead([string] $branchName) {
    gitcmd checkout,$branchName
    gitcmd pull,origin,$branchName
}

function SourceControlGit_PullRepoCommits() {
        gitcmd fetch --all
}

function SourceControlGit_PushCommitsToRemote([switch] $newBranch) {
    $currentBranch = SourceControlGit_GetCurrentBranch
    if ($newBranch)
    {
        gitcmd push,origin,$currentBranch
    }
    else
    {
        gitcmd push,-u,origin,$currentBranch
    }
}

function SourceControlGit_MergeToCurrentBranch([string] $remoteBranch, [switch] $internalMerge) {
    gitcmd merge,$remoteBranch -DoNotExitOnError
}

function SourceControlGit_MergeSingleCommit([string] $commitRevision, [switch] $internalMerge) {
    gitcmd cherry-pick,$commitRevision
}

function SourceControlGit_ResolveAllMergeConflicts() {
    gitcmd add,-u
}

function SourceControlGit_RevertAll() {
    gitcmd reset,--hard
    gitcmd clean,-dx,-f
}

function SourceControlGit_GetOutgoingChanges([string] $branch) {
    if (!($branch)) {
        $branch = SourceControlGit_GetCurrentBranch
    }
    gitcmd diff,--stat,--cached,--name-only,"origin/$branch"
}

function SourceControlGit_HasPendingChanges() {
    $output = (gitcmd diff,--name-only);
    return $output.length -gt 0
}

function SourceControlGit_GetCurrentBranch() {
    $output = (gitcmd rev-parse,--abbrev-ref,HEAD)[0].Trim()
    return $output.Trim();
}

function SourceControlGit_ForwardChangeCheck([string]$baseBranch, [string]$currentBranch) {
    #if the name isnt a local branch or tag, then check the remote repo
    if (-not ((SourceControlGit_BranchExists $baseBranch) -or (SourceControlGit_TagExists $baseBranch)))
    {
        $baseBranch = "origin/$baseBranch"
    }
    $output = (gitcmd log,$baseBranch,"^$currentBranch",--no-merges,-n,10);
    return $output
}

function SourceControlGit_NewBranch($branch) {
    #creates a new branch and makes it the current branch
    gitcmd checkout,-b,$branch

    #if you want to make it remote right away
    #gitcmd push,origin,$branch
}

function SourceControlGit_BranchExists($branch) {
    $arguments = "show-ref","--verify","--quiet","refs/heads/$branch"
    $output = (gitcmd $arguments -DoNotExitOnError)
    $exitCode = $GLOBAL:LASTEXITCODE
    if ($exitCode -eq 0) { 
        return $true;
    }
    if ($exitCode -eq 1) { 
        return $false;
    }

    #if the error code wasnt 0 or 1, then we have an unexpected error
    WriteGitError("$cmd $arguments", $output);
    Exit 1
}

function SourceControlGit_TagExists($branch) {
    $arguments = "show-ref","--verify","--quiet","refs/tags/$branch"
    $output = (gitcmd $arguments -DoNotExitOnError)
    $exitCode = $GLOBAL:LASTEXITCODE
    if ($exitCode -eq 0) { 
        return $true;
    }
    if ($exitCode -eq 1) { 
        return $false;
    }

    #if the error code wasnt 0 or 1, then we have an unexpected error
    WriteGitError("$cmd $arguments", $output);
    Exit 1
}

function SourceControlGit_BranchExistsRemote($branch) {
    $result = (gitcmd ls-remote,--heads,origin,$branch).Count
    if ($result -gt 0) { return $true; }
    return $false;
}

function SourceControlGit_TagExistsRemote($branch) {
    $result = (gitcmd ls-remote,--tags,origin,$branch).Count
    if ($result -gt 0) { return $true; }
    return $false;
}
