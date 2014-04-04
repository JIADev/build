$customernumber = '/p:Interactive=false;CustomerNumber=2094;'
$branches = 'Branches="TRK1;REQ033;REQ036;";'
$buildTag = 'BuildTag=TRK1;'
$baseTag = 'BaseTag=7.6.0'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $customernumber$branches$buildTag$baseTag $scriptPath\buildtools.proj