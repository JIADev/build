$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"

& $msbuild /t:ForwardMerge_Active $scriptPath\buildtools.proj
