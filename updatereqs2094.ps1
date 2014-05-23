$interactive = '/p:Interactive=false;'
$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ011;REQ013;REQ016;REQ032;REQ033;REQ035;REQ036;REQ044;REQ049;REQ064;REQ081;REQ116;REQ126;REQ127;REQ129;REQ141;REQ145;REQ147;REQ177;REQ180"'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "c:\windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
