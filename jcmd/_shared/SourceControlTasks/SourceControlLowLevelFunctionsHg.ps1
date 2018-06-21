function hg(){
    #$cmd = "C:\Program Files\TortoiseHg\hg.exe"
    $cmd = "hg.exe"
    Write-Host "$cmd $args"
    
    $output = ((& $cmd $args) | Out-String)
    $lines = $output -split "`r`n"
    
    #remove the first line, it's the hg exe command
    $lines= $lines[1..($lines.Length-1)]
    return $lines;
}

function SourceControlHg_Commit([string] $message, [switch] $closeBranch) {
    hg ci -m $message
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot commit! message = $message"
        Exit 1
    }
}

function SourceControlHg_CommitAndClose([string] $message) {
    hg ci -m $message --close-branch
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot commit! message = $message"
        Exit 1
    }
}

function SourceControlHg_SetBranch([string] $branchName) {
    SourceControlHg_UpdateBranch $branchName
}

function SourceControlHg_UpdateBranch([string] $branchName) {
    hg update $branchName
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot update to branch: $branch"
        Exit 1
    }
}

function SourceControlHg_Pull() {
    hg pull
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot pull!"
        Exit 1
    }
}

function SourceControlHg_Push([string[]] $options) {
    hg push $options
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot push!"
        Exit 1
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
        Exit 1
    }
}

function SourceControlHg_Graft([string] $commitRevision, [switch] $internalMerge) {
    if ($internalMerge -eq $true) {
        hg graft -r $commitRevision --tool=internal:merge
    }
    else {
        hg graft -r $commitRevision
    }
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot Merge $remoteBranch"
        Exit 1
    }
}

function SourceControlHg_ResolveAll() {
    hg resolve --all
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot resolve conflicts!"
        Exit 1
    }
}

function SourceControlHg_RevertAll() {
    #hg revert --all --no-backup
    #hg update --clean
    #hg purge --all
    hg --config extensions.purge= purge --all

    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot revert all!"
        Exit 1
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
        Exit 1
    }
}

function SourceControlHg_HasPendingChanges() {
    $output = (hg status);
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot get repo status!"
        Exit 1
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
    $output = (hg branch).Trim()
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot get repo branch!"
        Exit 1
    }
    return $output.Trim();
}

function SourceControlHg_GetRemovedFiles() {
    $output = (hg status -r);
    if ($LastExitCode -ne 0) { 
        Write-Host "Cannot get repo status!"
        Exit 1
    }    
    return $output
}