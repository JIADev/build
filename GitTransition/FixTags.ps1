param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "$PSScriptRoot\..\jcmd\_shared\common.ps1"
. "$PSScriptRoot\..\jcmd\_shared\SourceControl\SourceControl.ps1"

$tags = ""

#switch to mercurial folder for exporting info
Push-Location $hgFolder
try {
    #ensure latest code is local
    Write-ColorOutput "Pulling Mercurial Repo" -ForegroundColor Cyan
    hg pull

    #export the closed branches
    Write-ColorOutput "Exporting Closed Branches..." -ForegroundColor Cyan
    $tags = $(hg log -r "tag()" -T "{branch}\n") | sort-object | get-unique
    if ($LASTEXITCODE -ne 0) { throw "Error getting tags from Mercurial" }

    #get the open branches (heads)
    $hgHeads=$(hg heads -T "{branch}\n") | sort-object | get-unique
    if ($LASTEXITCODE -ne 0) { throw "Error getting branches from Mercurial" }

    #if there happens to be a case where the a tag is also a branch, remove it
    #from the tags list
    $tags = $tags | Where-Object {$hgHeads -notcontains $_}
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

    #find the branches that used to be tags in HG
    [array] $processList = $tags | Where-Object {$gitBranchList -contains $_}

    $notProcessedCount = $tags.Count - $processList.Count
    Write-ColorOutput "Skipping $notProcessedCount tags because they are not present in Git repository!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -lt $total; $i++ ) {
        $line = $processList[$i];
        $branchName = $line.Trim()
        $tagName = "$branchName"

        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Converting Branches to Tags" -Status "($($i+1) of $total) $pct% Complete | $branchName :" -PercentComplete $pct;

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
            if ($LASTEXITCODE -ne 0) { throw "Tag $branchHash to $tagName failed!" }
            
            Write-ColorOutput "Pushing Tag $tagName" -ForegroundColor Cyan
            git push origin "$tagName" -f
            if ($LASTEXITCODE -ne 0) { throw "Push tag $tagName to Origin failed!" }

            Write-ColorOutput "Deleting Remote Branch $branchName" -ForegroundColor Cyan
            git push origin --delete "refs/heads/$branchName"
            if ($LASTEXITCODE -ne 0) { throw "Deleting remote branch $branchName failed!" }

            Write-ColorOutput "Branch $branchName converted to tag $tagName" -ForegroundColor Cyan
        }
        catch {
            Write-ColorOutput "Processing $branchName failed:" -ForegroundColor Red
            Write-ColorOutput $_.Exception.Message -ForegroundColor Red
        }
    }

    Write-Progress -Completed -Activity "Converting Branches to Tags" 
}

finally {
    Pop-Location
}
