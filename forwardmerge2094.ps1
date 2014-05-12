$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"

& $scriptPath/updatereqs2094.ps1
& $msbuild /t:ForwardMerge_2094 $scriptPath\buildtools.proj
