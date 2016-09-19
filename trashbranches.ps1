
function closeBranches([string]$BranchNames) {
$scriptPath = "c:\build"
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"

& $msbuild /t:TrashBranches /p:SourceBranch="$BranchNames" /p:TrashBranch=trashcan /p:TrashRepo=c:\dev\repos\trashActiveRepo $scriptPath\buildtools.proj
}
