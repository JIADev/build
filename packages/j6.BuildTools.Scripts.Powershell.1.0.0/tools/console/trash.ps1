param ( [string]$BranchName )
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"

& $msbuild /t:Trash /p:SourceBranch=$BranchName /p:TrashBranch=trashcan /p:TrashRepo=c:\dev\repos\trashActiveRepo $scriptPath\buildtools.proj
