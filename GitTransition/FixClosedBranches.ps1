param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "..\jcmd\_shared\SourceControl\SourceControl.ps1"

$closedBranches = ""

#switch to mercurial folder for exporting info
Push-Location $hgFolder
try {
    #ensure latest code is local
    Write-Host "Pulling Mercurial Repo" -ForegroundColor Cyan
    hg pull

    #export the closed branches
    Write-Host "Exporting Closed Branches..." -ForegroundColor Cyan
    $closedBranches = $(hg log -r "closed()" -T "{branch}\n") | sort-object | get-unique
    if ($LASTEXITCODE -ne 0) { throw "Error getting closed branches from Mercurial" }
}
finally {
    Pop-Location
}

#switch to git folder for processing
Push-Location $gitFolder
try {
    #get all repo info
    Write-Host "Updating Git Repo..." -ForegroundColor Cyan
    git fetch --all
    
    #change the current branch to 'master' to avoid conflicts with delete operations
    Write-Host "Switching git branch to 'master'..." -ForegroundColor Cyan
    git checkout master

    #get a list of all known branches in the git repo
    Write-Host "Exporting Git Branches..." -ForegroundColor Cyan
    $gitBranchList = & git branch -r --format "%(refname)" | Split-path -Leaf

    $processList = $closedBranches | Where-Object {$gitBranchList -contains $_}

    $notProcessedCount = $closedBranches.Count - $processList.Count

    Write-Host "Skipping $notProcessedCount branches because they are not present in Git repository!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -le $total; $i++ ) {
        $line = $processList[$i];
        $branchName = $line.Trim()
        $tagName = "archive/$branchName"

        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Processing ($($i+1) of $total) $branchName " -Status "$pct% Complete:" -PercentComplete $pct;

        Write-Host "Processing $branchName" -ForegroundColor Green
        try {
            $branchHash = $(git ls-remote origin $branchName) | Select-Object -First 1 | ForEach-Object {$_.Substring(0,40)}
            if (!$branchHash)
            {
                Write-Host "ERROR: Cannot retrieve branch hash for '$branchName'. Perhaps it does not exists!" -ForegroundColor Red
                Continue;
            }

            Write-Host "Creating Tag $tagName on $branchName $branchHash" -ForegroundColor Cyan
            git tag -f "$tagName" "$branchHash"
            if ($LASTEXITCODE -ne 0) { throw "Tag $branchHash to $tagName failed!" }
            
            Write-Host "Pushing Tag $tagName" -ForegroundColor Cyan
            git push origin "$tagName" -f
            if ($LASTEXITCODE -ne 0) { throw "Push tag $tagName to Origin failed!" }

            Write-Host "Deleting Remote Branch $branchName" -ForegroundColor Cyan
            git push origin --delete "$branchName"
            if ($LASTEXITCODE -ne 0) { throw "Deleting remote branch $branchName failed!" }

            Write-Host "Branch $branchName converted to tag $tagName" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Processing $branchName failed:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    Write-Progress -Completed
}

finally {
    Pop-Location
}
