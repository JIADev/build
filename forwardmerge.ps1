$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:ForwardMerge $scriptPath\buildtools.proj
