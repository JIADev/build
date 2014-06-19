$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2095;'
$branches = 'Branches="REQ006;REQ007"'
$buildTag = 'BuildTag=QA;'
$baseTag = 'BaseTag=Events;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
