$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2095;'
$branches = 'Branches="REQ005;REQ022;REQ011;REQ006;REQ007;REQ014;REQ015;REQ004;REQ003;Config"'
$buildTag = 'BuildTag=QA;'
$baseTag = 'BaseTag=Events;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
