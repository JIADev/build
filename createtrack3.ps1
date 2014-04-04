$customernumber = '/p:Interactive=false;CustomerNumber=2094;'
$branches = 'Branches="TRK3;REQ038;REQ145;REQ064;REQ147";'
$buildTag = 'BuildTag=TRK3;'
$baseTag = 'BaseTag=7.6.0'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $customernumber$branches$buildTag$baseTag $scriptPath\buildtools.proj
