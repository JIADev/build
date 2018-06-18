$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
& msbuild /t:CleanProjectFiles /p:RepoDirectory=. $scriptPath\buildtools.proj
