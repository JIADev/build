$interactive = '/p:Interactive=false;'
$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches=""'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
