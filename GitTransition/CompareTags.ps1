param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "$PSScriptRoot\..\jcmd\_shared\common.ps1"

#switch to HG
push-location $hgFolder
#get the open branches (heads)
$hgTags = $(hg log -r "tag()" -T "{branch}\n") | sort-object | get-unique

$hgClosedBranches = $(hg log -r "closed()" -T "{branch}\n") | sort-object | get-unique

pop-location

#switch to GIT
push-location $gitFolder
$gitTags = $(& git tag -l) | Split-path -Leaf | sort-object | get-unique | Where-Object {$_ -notlike "archive/*"}
pop-location

$sameCount = $($gitTags | Where-Object {$hgTags -contains $_}).Count
Write-ColorOutput "$sameCount tags are the same in Git and HG." -ForegroundColor Cyan

$missingFromHG = $gitTags | Where-Object {$hgTags -notcontains $_ -and $hgClosedBranches -notcontains $_}
Write-ColorOutput "These tags are in Git but not in HG ($($missingFromHG.Count)):" -ForegroundColor Yellow
$missingFromHG

$missingFromGit = $hgTags | Where-Object {$gitTags -notcontains $_}
Write-ColorOutput "These tags are in HG but not in GIT ($($missingFromGit.Count)):" -ForegroundColor Red
$missingFromGit

