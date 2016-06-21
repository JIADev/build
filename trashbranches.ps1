param ( [string]$BranchNames )
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"

& $msbuild /t:TrashBranches /p:SourceBranch=$BranchNames /p:TrashBranch=trashcan /p:TrashRepo=c:\dev\repos\trashActiveRepo $scriptPath\buildtools.proj
