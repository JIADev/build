$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2095;'
$branches = 'Branches="REQ002;REQ005;REQ022;REQ011;REQ006;REQ007;REQ014;REQ015;REQ004;REQ003;Config"'
$buildTag = 'BuildTag=RC1;'
$baseTag = 'BaseTag=Events;'

$suppressPrefix='SuppressPrefix="true";'
$branches761 = 'Branches="7.6.1"'
$build761Tag = 'BuildTag=2095_QA;'
$base761Tag = 'BaseTag=2095_RC1;'

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
& msbuild /t:CreateBuild $interactive$customernumber$suppressPrefix$build761Tag$base761Tag$branches761 $scriptPath\buildtools.proj
