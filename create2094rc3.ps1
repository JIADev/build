$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_REQ066;2094_REQ012;2094_REQ065;2094_REQ069;2094_REQ070;2094_REQ311;2094_REQ102;2094_REQ100;2094_REQ006.2;2094_REQ305"'
$buildTag = 'BuildTag=2094_RC3;'
$baseTag = 'BaseTag=7.6.3;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
