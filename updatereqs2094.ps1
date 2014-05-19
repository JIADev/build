$interactive = '/p:Interactive=false;'
$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ002;REQ005;REQ006;REQ011;REQ013;REQ016;REQ017;REQ029;REQ031;REQ032;REQ033;REQ035;REQ036;REQ038;REQ039;REQ044;REQ049;REQ060;REQ064;REQ081;REQ116;REQ126;REQ127;REQ129;REQ132;REQ141;REQ145;REQ146;REQ147;REQ177;REQ180;REQ193"'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
