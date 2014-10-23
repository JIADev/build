$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2095;SuppressPrefix="true";'
$branches = 'Branches="2095_REQ042;2095_REQ039;2095_REQ008;2095_REQ010;2095_REQ029;2095_REQ019_7.6.0"'
$buildTag = 'BuildTag=2095_RC2-demo;'
$baseTag = 'BaseTag=2095_RC1.2;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj

$branches = 'Branches="2095_REQ024"'
$buildTag = 'BuildTag=2095_RC2;'
$baseTag = 'BaseTag=2095_RC2-demo;'
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
