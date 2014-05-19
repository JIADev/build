$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ044;REQ038;REQ146;REQ147;REQ064;REQ145;REQ132;REQ129;REQ126;REQ033;REQ060;REQ177;REQ036;REQ035;REQ002;REQ016"'
$buildTag = 'BuildTag=RC1;'
$baseTag = 'BaseTag=7.6.0;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
