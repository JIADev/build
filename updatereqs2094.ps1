$interactive = '/p:Interactive=false;'
$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ033;REQ036;REQ035;REQ039;REQ029;REQ031;REQ129;REQ132;REQ127;REQ126;REQ038;REQ146;REQ147;REQ064;REQ145;REQ011;REQ180;REQ016;REQ060;REQ177;REQ002;REQ006;REQ005;REQ081;REQ032;REQ049;REQ044"'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
