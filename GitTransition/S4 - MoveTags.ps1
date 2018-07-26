param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "$PSScriptRoot\..\jcmd\_shared\common.ps1"
. "$PSScriptRoot\..\jcmd\_shared\SourceControl\SourceControl.ps1"

$tags = @(
    "2094_PRD",
    "2094PER_PRD",
    "2095_PRD",
    "2097_PRD",
    "2097PL_PRD",
    "2097SG_PRD"
)

$tagInfoList = @()

$hgDatePattern="ddd MMM dd HH:mm:ss yyyy zzz"
$gitDatePattern="yyyy-MM-dd HH:mm:ss"

#switch to mercurial folder for exporting info
Push-Location $hgFolder
try {
    #ensure latest code is local
    Write-ColorOutput "Pulling Mercurial Repo" -ForegroundColor Cyan
    hg pull

    #export the closed branches
    Write-ColorOutput "Exporting tag data..." -ForegroundColor Cyan
    foreach ($tag in $tags)
    {
        # ":{space}" is important for proper parseing
        $tagInfo = $(hg log -r $tag) | ConvertFrom-String -Delimiter ': ' -PropertyNames Property,Value,Hash | Where-Object {$_.Property -ne "Tag"}
        if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Error getting tags from Mercurial" }

        [string] $tagUser = $tagInfo | Where-Object {$_.Property -eq "user"} | foreach-object {$_.Value.Trim()}
        [string] $tagDate = $tagInfo | Where-Object {$_.Property -eq "date"} | foreach-object {[DateTime]::ParseExact($_.Value.Trim(), $hgDatePattern,$null)}
        [string] $tagSummary = $tagInfo | Where-Object {$_.Property -eq "summary"} | foreach-object {$_.Value.Trim()}

        $tagObject = New-Object PSObject @{
            Tag = "$tag"
            User = "$tagUser"
            Date = $tagDate
            Summary = "$tagSummary"
        }

        Write-ColorOutput $tagObject cyan
        Write-ColorOutput ""

        $tagInfoList += $tagObject
    }
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

    Write-ColorOutput "Loading existing Git repo tags..." -ForegroundColor Cyan
    $gitTags = $(& git tag -l) | Split-path -Leaf | sort-object | get-unique | Where-Object {$_ -notlike "archive/*"}

    #only process tags that do not already exist
    [array] $processList = $tagInfoList | Where-Object {$gitTags -notcontains $_}

    $notProcessedCount = $tagInfoList.Count - $processList.Count
    Write-ColorOutput "Skipping $notProcessedCount tags because they already exist!" -ForegroundColor Yellow

    #process the branches are closed in HG and should be converted to tags in Git
    $total = $processList.Length
    for ($i = 0; $i -lt $total; $i++ ) {
        $tagDetails = $processList[$i];
        $tagName = $tagDetails["Tag"]
        $tagUser = $tagDetails["User"]
        $tagDate = $tagDetails["Date"]
        $tagDateString = [DateTime]::Parse($tagDate).ToString($gitDatePattern)
        $tagSummary = $tagDetails["Summary"]


        $pct = [math]::Round((($i + 1) / $total) * 100)
        Write-Progress -Activity "Applying Tags" -Status "($($i+1) of $total) $pct% Complete | $tagName :" -PercentComplete $pct;

        Write-ColorOutput "Processing $tagName" -ForegroundColor Green
        try {
            $gitCommit = $(git log --after="$tagDateString" --before="$tagDateString" --all --author $tagUser --oneline)
            if (!$gitCommit)
            {
                Write-ColorOutput "ERROR: Cannot find matching git commit at '$tagDateString' for '$tagUser'. Perhaps it does not exists!" -ForegroundColor Red
                Write-ColorOutput "git log --after=`"$tagDateString`" --before=`"$tagDateString`" --all --author $tagUser --oneline" Red
                Continue;
            }

            $commitHash = ($gitCommit -split " ")[0]

            Write-ColorOutput "Creating Tag $tagName on $commitHash" -ForegroundColor Cyan
            git tag -f "$tagName" "$commitHash"
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Tagging hash '$branchHash' with '$tagName' failed!" }

            Write-ColorOutput "Pushing Tag '$tagName'" -ForegroundColor Cyan
            git push origin "$tagName" -f
            if ($GLOBAL:LASTEXITCODE -ne 0) { throw "Push tag $tagName to Origin failed!" }

            Write-ColorOutput "Tag '$tagName' moved." -ForegroundColor Cyan
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
