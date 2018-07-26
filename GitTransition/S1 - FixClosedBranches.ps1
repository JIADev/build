param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "$PSScriptRoot\..\jcmd\_shared\common.ps1"
. "$PSScriptRoot\..\jcmd\_shared\SourceControl\SourceControl.ps1"

$closedBranches = ""

#switch to mercurial folder for exporting info
Push-Location $hgFolder
try {
    #ensure latest code is local
    Write-ColorOutput "Pulling Mercurial Repo" -ForegroundColor Cyan
    hg pull

    #export the closed branches
    Write-ColorOutput "Exporting Closed Branches..." -ForegroundColor Cyan
    $closedBranches = $(hg log -r "closed()" -T "{branch}\n") | sort-object | get-unique
    if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Error getting closed branches from Mercurial" }
    Write-ColorOutput "Found $($closedBranches.Count) Closed Branches..." -ForegroundColor Cyan

    #export the active/open heads
    Write-ColorOutput "Exporting Open Branches..." -ForegroundColor Cyan
    $openBranches = $hgHeads=$(hg heads -T "{branch}\n") | sort-object | get-unique
    if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Error getting closed branches from Mercurial" }
    Write-ColorOutput "Found $($openBranches.Count) Open Branches..." -ForegroundColor Cyan

    #sometimes a branch was closed at one point, and so it will be in the closed list
    #but it was re-opened, and so it will also be in the opened list
    #lets make sure our closed list doesnt have opened branches

    $closedBranches = $closedBranches | Where-Object {$openBranches -notcontains $_}
    Write-ColorOutput "After removing open branches from closed list, there are $($closedBranches.Count) closed branches..." -ForegroundColor Cyan
}
finally {
    Pop-Location
}

#switch to git folder for processing
Push-Location $gitFolder
try {
    #get all repo info
    Write-ColorOutput "Updating Git Repo..." -ForegroundColor Cyan
    git fetch --all
    
    #change the current branch to 'master' to avoid conflicts with delete operations
    Write-ColorOutput "Switching git branch to 'master'..." -ForegroundColor Cyan
    git checkout master

    #get a list of all known branches in the git repo
    Write-ColorOutput "Exporting Git Branches..." -ForegroundColor Cyan
    $gitBranchList = & git branch -r --format "%(refname)" | Split-path -Leaf

    #we should process any branch we know was closed in HG, that is present in GIT as branch
    #because git doesnt have "closed" branches, GIT best practice is to use tags for this purpose
    [array] $processList = $closedBranches | Where-Object {$gitBranchList -contains $_}

    if (!$processList) {
        $processList = @()
    }

    $notProcessedCount = $closedBranches.Count - $processList.Count

    Write-ColorOutput "Skipping $notProcessedCount branches because they are not present in Git repository!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -lt $total; $i++ ) {
        $line = $processList[$i];
        $branchName = $line.Trim()
        $tagName = "archive/$branchName"

        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Processing Closed Branches" -Status "($($i+1) of $total) $pct% Complete | $branchName :" -PercentComplete $pct;

        Write-ColorOutput "Processing $branchName" -ForegroundColor Green
        try {
            $branchHash = $(git ls-remote origin $branchName) | Select-Object -First 1 | ForEach-Object {$_.Substring(0,40)}
            if (!$branchHash)
            {
                Write-ColorOutput "ERROR: Cannot retrieve branch hash for '$branchName'. Perhaps it does not exists!" -ForegroundColor Red
                Continue;
            }

            Write-ColorOutput "Creating Tag $tagName on $branchName $branchHash" -ForegroundColor Cyan
            git tag -f "$tagName" "$branchHash"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Tag $branchHash to $tagName failed!" }
            
            Write-ColorOutput "Pushing Tag $tagName" -ForegroundColor Cyan
            git push origin "$tagName" -f
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Push tag $tagName to Origin failed!" }

            Write-ColorOutput "Deleting Remote Branch $branchName" -ForegroundColor Cyan
            git push origin --delete "refs/heads/$branchName"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Deleting remote branch $branchName failed!" }

            Write-ColorOutput "Branch $branchName converted to tag $tagName" -ForegroundColor Cyan
        }
        catch {
            Write-ColorOutput "Processing $branchName failed:" -ForegroundColor Red
            Write-ColorOutput $_.Exception.Message -ForegroundColor Red
        }
    }

    Write-Progress -Activity "Processing Closed Branches" -Completed
}

finally {
    Pop-Location
}
