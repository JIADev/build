$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
."$scriptPath\startgraftCommon.ps1"

Write-Host "Updating $scriptPath"
$updateSuccess = updateBuildTools $scriptPath

$repo = ($args[0])
$localDir = ($args[1])
$myLocation = get-location

& $msbuild $scriptPath\buildTools.proj /t:FastClone /p:Repository=$repo /p:LocalDir=$localDir /p:Location=$myLocation

