$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ146;REQ147;REQ064;REQ145;REQ032;REQ081;REQ011;REQ049;REQ051;REQ044;REQ020.B;REQ057;REQ193;REQ060;REQ013;REQ033;REQ177;REQ016;REQ180;REQ036;REQ035;REQ121;REQ141;REQ116;REQ127;REQ129;REQ132;REQ126;REQ002;REQ006;REQ017;REQ029;REQ031;REQ038;REQ039;REQ134"'
$buildTag = 'BuildTag=RC1;'
$baseTag = 'BaseTag=7.6.0;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
