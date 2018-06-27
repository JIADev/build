function WriteHgError([string]$cmd, [string]$output)
{
    Write-Host $('-' * 80) -ForegroundColor Red
    Write-Host "Mercurial Command Failed: $cmd " -ForegroundColor Red
    Write-Host $('-' * 80) -ForegroundColor Red
    Write-Host $output -ForegroundColor Red
    Write-Host $('-' * 80) -ForegroundColor Red
}

function hgcmd([string[]] $arguments, [switch]$DoNotExitOnError){
    $cmd = "hg.exe"
    Write-Host "$cmd $arguments" -ForegroundColor Cyan
    
    $output = ((& $cmd @arguments) | Out-String)
    if ($DoNotExitOnError -or $LASTEXITCODE -eq 0)
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
            Write-Host $modifiedFile
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
    if ($LASTEXITCODE -eq 0) { 
        return $true;
    }
    if ($LASTEXITCODE -eq 255) { 
        return $false;
    }

    #if the error code wasnt 0 or 255, then we have an unexpected error
    WriteHgError("$cmd $arguments", $output);
    Exit 1
}

