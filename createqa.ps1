$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2095;'
$branches = 'Branches="Config_7.6.1;REQ005;REQ022;REQ011;REQ006;REQ007;REQ015;REQ004"'
$buildTag = 'BuildTag=QA;'
$baseTag = 'BaseTag=Events_7.6.1;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
