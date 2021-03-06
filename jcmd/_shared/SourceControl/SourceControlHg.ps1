function WriteHgError([string]$cmd, [string]$output)
{
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
    Write-ColorOutput "Mercurial Command Failed: $cmd " -ForegroundColor Red
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
    Write-ColorOutput $output -ForegroundColor Red
    Write-ColorOutput $('-' * 80) -ForegroundColor Red
}

function hgcmd([string[]] $arguments, [switch]$DoNotExitOnError){
    $cmd = "hg.exe"
    Write-Debug "$cmd $arguments"
    
    $output = ((& $cmd @arguments) | Out-String)
    if ($DoNotExitOnError -or $GLOBAL:LASTEXITCODE -eq 0)
    {
        $lines = $output.Trim() -split "`r`n"
        #remove the first line - it is the hg command
        #$lines= $lines[1..($lines.Length-1)] #doesnt seem to be needed
        return $lines
    }

    WriteHgError("$cmd $arguments", $output);
    Exit 1
}

function SourceControlHg_Commit([string] $message, [switch] $closeBranch) {
    hgcmd ci,-m,$message
}

function SourceControlHg_CommitAndClose([string] $message) {
    hgcmd ci,-m,$message,--close-branch
}

function SourceControlHg_SetBranch([string] $branchName) {
    SourceControlHg_UpdateBranch $branchName
}

function SourceControlHg_UpdateBranchToHead([string] $branchName) {
    hgcmd update,$branchName
}

function SourceControlHg_PullRepoCommits() {
    hgcmd pull
}

function SourceControlHg_PushCommitsToRemote([string[]] $options) {
    hgcmd push,$options
}

function SourceControlHg_MergeToCurrentBranch([string] $remoteBranch, [switch] $internalMerge) {
    if ($internalMerge -eq $true) {
        hgcmd merge,$remoteBranch,--tool=internal:merge
    }
    else {
        hgcmd merge,$remoteBranch
    }
}

function SourceControlHg_MergeSingleCommit([string] $commitRevision, [switch] $internalMerge) {
    if ($internalMerge -eq $true) {
        hgcmd graft,-r,$commitRevision,--tool=internal:merge
    }
    else {
        hgcmd graft,-r,$commitRevision
    }
}

function SourceControlHg_ResolveAllMergeConflicts() {
    hgcmd resolve,--all
}

function SourceControlHg_RevertAll() {
    hgcmd --config,extensions.purge=,purge,--all
}

function SourceControlHg_GetOutgoingChanges([string] $branch) {
    if ($branch) {
        hgcmd outgoing,-b,$branch
    }
    else {
        hgcmd outgoing
    }
}

function SourceControlHg_HasPendingChanges() {
    $output = (hgcmd status);

    $pendingChanges = @()
    foreach ($line in $output) {
        $modifiedFile = $line.Trim()
        if ($modifiedFile -and $modifiedFile.StartsWith("? ") -eq $false) {
            Write-ColorOutput $modifiedFile
            $pendingChanges += $modifiedFile
        }
    }
    return $pendingChanges.length -gt 0
}

function SourceControlHg_GetCurrentBranch() {
    $output = (hgcmd branch).Trim()
    return $output.Trim();
}

function SourceControlHg_GetRemovedFiles() {
    $output = (hgcmd status,-r);
    return $output
}

function SourceControlHg_ForwardChangeCheck([string]$baseBranch, [string]$currentBranch) {
    $output = (hgcmd log,--rev,"`"ancestors('$baseBranch') and !ancestors('$currentBranch')`"",-l,10);
    return $output
}


function SourceControlHg_NewBranch($branch) {
    hgcmd branch,$branch
}

function SourceControlHg_BranchExists($branch) {
    $arguments="id","-q","-r","$branch"
    $output = (hgcmd $arguments -DoNotExitOnError)
    $exitCode = $GLOBAL:LASTEXITCODE
    if ($exitCode -eq 0) { 
        return $true;
    }
    if ($exitCode -eq 255) { 
        return $false;
    }

    #if the error code wasnt 0 or 255, then we have an unexpected error
    WriteHgError("$cmd $arguments", $output);
    Exit 1
}

function SourceControlHg_BranchExistsRemote($branch) {
    #mercurial doesnt really have a remote, so we pull first, then decide
    SourceControlHg_PullRepoCommits
    return SourceControlHg_BranchExists $branch
}

function SourceControlHg_TagExists($tag) {
    $arguments="id","-q","-r","$tag"
    $output = (hgcmd $arguments -DoNotExitOnError)
    $exitCode = $GLOBAL:LASTEXITCODE
    if ($exitCode -eq 0) { 
        return $true;
    }
    if ($exitCode -eq 255) { 
        return $false;
    }

    #if the error code wasnt 0 or 255, then we have an unexpected error
    WriteHgError("$cmd $arguments", $output);
    Exit 1
}

function SourceControlHg_TagExistsRemote($tag) {
    #mercurial doesnt really have a remote, so we pull first, then decide
    SourceControlHg_PullRepoCommits
    return SourceControlHg_BranchExists $tag
}
