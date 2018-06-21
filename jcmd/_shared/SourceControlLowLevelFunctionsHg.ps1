function hg([string] $params ){
    $output = ((& "C:\Program Files\TortoiseHg\hg.exe" $params) | Out-String)
    $lines = $output -split "`r`n"
    
    #remove the first line, it's the hg exe command
    $lines= $lines[1..($lines.Length-1)]
    return $lines;
}

function SourceControlHg_Commit([string] $message, [switch] $closeBranch) {
    hg ci -m $message
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot commit! message = $message"
        Exit
    }
}

function SourceControlHg_CommitAndClose([string] $message) {
    hg ci -m $message --close-branch
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot commit! message = $message"
        Exit
    }
}

function SourceControlHg_SetBranch([string] $branchName) {
    SourceControlHg_UpdateBranch $branchName
}

function SourceControlHg_UpdateBranch([string] $branchName) {
    hg update $branchName
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot update to branch: $branch"
        Exit
    }
}

function SourceControlHg_Pull() {
    hg pull
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot pull!"
        Exit
    }
}

function SourceControlHg_Push([string[]] $options) {
    hg push $options
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot push!"
        Exit
    }
}

function SourceControlHg_Merge([string] $remoteBranch, [switch] $internalMerge) {
    if ($internalMerge -eq $true) {
        hg merge $remoteBranch --tool=internal:merge
    }
    else {
        hg merge $remoteBranch
    }
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot Merge $remoteBranch"
        Exit
    }
}

function SourceControlHg_Graft([string] $commitRevision, [switch] $internalMerge) {
    if ($internalMerge -eq $true) {
        hg merge $commitRevision --tool=internal:merge
    }
    else {
        hg merge $commitRevision
    }
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot Merge $remoteBranch"
        Exit
    }
}

function SourceControlHg_ResolveAll() {
    hg resolve --all
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot resolve conflicts!"
        Exit
    }
}

function SourceControlHg_RevertAll() {
    hg revert --all --no-backup
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot revert all!"
        Exit
    }
}

function SourceControlHg_GetOutgoingChanges([string] $branch) {
    if ($branch) {
        hg outgoing -b $branch
    }
    else {
        hg outgoing
    }
    
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot get outgoing changesets!"
        Exit
    }
}

function SourceControlHg_HasPendingChanges() {
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

function SourceControlHg_GetCurrentBranch() {
    $output = (hg branch)
    if ($LastExitCode -ne 0) { return ''}
    return $output.Trim();
}

