param(
    [string] $gitFolder="C:\dev\Git-active",
    [string] $hgFolder="C:\dev\Platform"
)

. "$PSScriptRoot\..\jcmd\_shared\common.ps1"

#switch to HG
push-location $hgFolder
#get the open branches (heads)
$hgHeads=$(hg heads -T "{branch}\n") | sort-object | get-unique
pop-location

#switch to GIT
push-location $gitFolder
$gitHeads = $(& git branch -r --format "%(refname)") | Split-path -Leaf | sort-object | get-unique
pop-location

$sameCount = $($gitHeads | Where-Object {$hgHeads -contains $_}).Count
Write-ColorOutput "$sameCount heads are the same in Git and HG." -ForegroundColor Cyan

$missingFromHG = $gitHeads | Where-Object {$hgHeads -notcontains $_}
Write-ColorOutput "These heads are in Git but not in HG ($($missingFromHG.Count)):" -ForegroundColor Yellow
$missingFromHG

$missingFromGit = $hgHeads | Where-Object {$gitHeads -notcontains $_}
Write-ColorOutput "These heads are in HG but not in GIT ($($missingFromGit.Count)):" -ForegroundColor Red
$missingFromGit

