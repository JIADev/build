param(
    [string] $gitFolder="C:\Dev\_Engine\EngineCore_git"
)

. "$PSScriptRoot\..\..\jcmd\_shared\common.ps1"

$packageFile = "C:\dev\build\GitTransition\IgnoreTemplate\.gitIgnore"

$targetFile = Join-Path $gitFolder ".\.gitignore"

#switch to git folder for processing
Push-Location $gitFolder
try {
    #get all repo info
    Write-ColorOutput "Updating Git Repo..." -ForegroundColor Cyan
    git fetch --all
   
    #change the current branch to 'master' to avoid conflicts with delete operations
    #Write-ColorOutput "Switching git branch to 'master'..." -ForegroundColor Cyan
    #git checkout master

    #get a list of all known branches in the git repo
    Write-ColorOutput "Exporting Git Branches..." -ForegroundColor Cyan
    $gitBranchList = & git branch -r --format "%(refname)" | Split-path -Leaf

    #dont process these brances
    [array] $ProcessExclude = @(
        #"TFS52733",
        #"TFS52763",
        #"TFS53680",
        #"TFS53866"
    )

    #find the branches that used to be tags in HG
    [array] $processList = $gitBranchList | Where-Object {$_ -notin $ProcessExclude}

    $notProcessedCount = $gitBranchList.Count - $processList.Count
    Write-ColorOutput "Skipping $notProcessedCount branches!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -lt $total; $i++ ) {
        $line = $processList[$i];
        $branchName = $line.Trim()

        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Updating Git Ignore Package Info" -Status "($($i+1) of $total) $pct% Complete | $branchName :" -PercentComplete $pct;

        Write-ColorOutput "Processing $branchName" -ForegroundColor Green
        try {
            Write-ColorOutput "Checking out $branchName" -ForegroundColor Cyan
            git checkout "$branchName"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Cannot checkout $branchName!" }
            
            if (Test-Path $targetFile)
            {
                #skip this branch, no package config
                Write-ColorOutput "$branchName already has an ignore file -- skipping" -ForegroundColor Yellow
                continue;
            }

            Write-ColorOutput "Updating Ignore File" -ForegroundColor Cyan
            Copy-Item $packageFile $targetFile
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Package Copy failed!" }

            Write-ColorOutput "Adding ignore file" -ForegroundColor Cyan
            git add "$targetFile"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Adding Target File failed!" }

            Write-ColorOutput "Git Commit" -ForegroundColor Cyan
            git commit -m "Adding git ignore file"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Git Commit failed!" }
        }
        catch {
            Write-ColorOutput "Processing $branchName failed:" -ForegroundColor Red
            Write-ColorOutput $_.Exception.Message -ForegroundColor Red
            Exit 1
        }
    }


    Write-ColorOutput "All branches updated." -ForegroundColor Cyan
    Write-ColorOutput "Pushing all branches to Origin" -ForegroundColor Yellow
    #git push --all origin
    if ($GLOBAL:LASTEXITCODE -ne 0) { 
        Write-ColorOutput "Git Push to Origin Failed!" -ForegroundColor Red
        Exit 1
    }

    Write-Progress -Completed -Activity "Converting Branches to Tags" 
}

finally {
    Pop-Location
}
