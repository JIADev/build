$initsourcerepo='/p:Preview=false;InitSourceRepo=active;'
$interactive = 'Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = 'Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_REQ213.4;2094_REQ309.4;2094_REQ306.4;2094_REQ308.4;2094_REQ310.4;2094_REQ301.4;2094_REQ304.4;2094_REQ184.4;2094_REQ164.4;2094_REQ163.4"'
$buildTag = 'BuildTag=2094_RC3.2;'
$baseTag = 'BaseTag=2094_7.6.4;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $initsourcerepo$interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
