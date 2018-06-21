function git(){
    $cmd = "git.exe"
    Write-Host "$cmd $args"
    
    $output = ((& $cmd $args) | Out-String)
    $lines = $output -split "`r`n"
    
    #remove the first line, it's the git exe command
    $lines= $lines[1..($lines.Length-1)]
    return $lines;
}

function SourceControlGit_Commit([string] $message) {
    git commit -a -m $message
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot commit! message = $message"
        Exit 1
    }
}

function SourceControlGit_CommitAndClose([string] $message) {
    SourceControlGit_Commit $message

    #now tag and remove the branch - Git doesnt have a "close" branch
    $branchName = SourceControlGit_GetCurrentBranch
    $closedTag = "Closed-$branchName"
    git tag $closedTag $branchName
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot tag branch $branchName with tag $tagName"
        Exit 1
    }

    git branch -d $branchName
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot remove branch $branchName"
        Exit 1
    }
}

function SourceControlGit_SetBranch([string] $branchName) {
    SourceControlGit_UpdateBranch $branchName
}

function SourceControlGit_UpdateBranch([string] $branchName) {
    git update $branchName
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot update to branch: $branch"
        Exit 1
    }
}

function SourceControlGit_Pull() {
    git pull
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot pull!"
        Exit 1
    }
}

function SourceControlGit_Push() {
    git push 
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot push!"
        Exit 1
    }
}

function SourceControlGit_Merge([string] $remoteBranch, [switch] $internalMerge) {
    git merge $remoteBranch
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot Merge $remoteBranch"
        Exit 1
    }
}

function SourceControlGit_Graft([string] $commitRevision, [switch] $internalMerge) {
    git cherry-pick $commitRevision
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot Merge $remoteBranch"
        Exit 1
    }
}

function SourceControlGit_ResolveAll() {
    git add -u
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot resolve conflicts!"
        Exit 1
    }
}

function SourceControlGit_RevertAll() {
    hg revert --all --no-backup
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot revert all!"
        Exit 1
    }
}

function SourceControlGit_GetOutgoingChanges([string] $branch) {
    if ($branch) {
        hg outgoing -b $branch
    }
    else {
        hg outgoing
    }
    
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot get outgoing changesets!"
        Exit 1
    }
}

function SourceControlGit_HasPendingChanges() {
    $output = (hg "status");
    if ($LastExitCode -ne 0) { 
        #unknown pending changes exist
        return $true
    }

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

function SourceControlGit_GetCurrentBranch() {
    $output = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($LastExitCode -ne 0) { return ''}
    return $output.Trim();
}

