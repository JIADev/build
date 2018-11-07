param(
    [string] $gitFolder="C:\dev\Git-active"
)

. "$PSScriptRoot\..\..\jcmd\_shared\common.ps1"
#. "$PSScriptRoot\..\..\jcmd\_shared\SourceControl\SourceControl.ps1"

$packageFile = "C:\dev\build\GitTransition\ToolsConfig\packages.config"
if (!(Test-Path $packageFile))
{
    $packageFile = "C:\dev\git-build\GitTransition\ToolsConfig\packages.config"
    if (!(Test-Path $packageFile))
    {
        Throw "Cannot locate updated package file."
    }
}

$targetFile = Join-Path $gitFolder ".nuget\jenkon\DeploymentTools\packages.config"

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
    [array] $ProcessInclude = @(
        "2083_ActiveInfra",
        "2094COL_Sprint",
        "2094PER_Sprint",
        "2094_Bolivia",
        "2094_Colombia",
        "2094_PeruInfra",
        "2094_Peru",
        "2095_Ver7.7",
        "2097JP_QAS",
        "2097JP_Ver7.7_PRD",
        "2097MY_Ver7.8",
        "2097PL_Ver7.7_PRD",
        "2097SG_ActiveInfra",
        "2097SG_Ver7.7_PRD",
        "2097_Ver7.7",
        "2098_7.8.0",
        "7.6.8",
        "MPS_Sprint3",
        "7.8.0",
        "1002_7.8.0_Carlton",
        "2095AU_DEV", 
        "2095AU_UAT",
        "2095AU_PRD"
    )

    #find the branches that used to be tags in HG
    [array] $processList = $gitBranchList | Where-Object {$ProcessInclude -contains $_}

    $notProcessedCount = $gitBranchList.Count - $processList.Count
    Write-ColorOutput "Skipping $notProcessedCount tags because they are not included as build branches!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -lt $total; $i++ ) {
        $line = $processList[$i];
        $branchName = $line.Trim()

        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Updating Deployment Tools Package Info" -Status "($($i+1) of $total) $pct% Complete | $branchName :" -PercentComplete $pct;

        Write-ColorOutput "Processing $branchName" -ForegroundColor Green
        try {
            Write-ColorOutput "Checking out $branchName" -ForegroundColor Cyan
            git checkout "$branchName"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Cannot checkout $branchName!" }
            
            if (!(Test-Path $targetFile))
            {
                #skip this branch, no package config
                Write-ColorOutput "$branchName does not have Deployment Config -- skipping" -ForegroundColor Yellow
                continue;
            }

            #skip this branch if the file is already updated
            if (!(Compare-Object -ReferenceObject $(Get-Content $packageFile) -DifferenceObject $(Get-Content $targetFile)))
            {
                Write-ColorOutput "$branchName already has the latest package config -- skipping" -ForegroundColor Yellow
                continue;
            }

            Write-ColorOutput "Updating Package File" -ForegroundColor Cyan
            Copy-Item $packageFile $targetFile
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Package Copy failed!" }

            Write-ColorOutput "Adding Package File" -ForegroundColor Cyan
            git add "$targetFile"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Adding Target File failed!" }

            Write-ColorOutput "Git Commit" -ForegroundColor Cyan
            git commit -m "Updating Deployment Tools"
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
    git push --all origin
    if ($GLOBAL:LASTEXITCODE -ne 0) { 
        Write-ColorOutput "Git Push to Origin Failed!" -ForegroundColor Red
        Exit 1
    }

    Write-Progress -Completed -Activity "Converting Branches to Tags" 
}

finally {
    Pop-Location
}
