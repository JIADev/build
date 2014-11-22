$initsourcerepo='/p:InitSourceRepo=active;'
$interactive = 'Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = 'Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_RC3.2;2094_REQ310.B;2094_REQ213;2094_REQ301.B;2094_REQ184;2094_REQ164"'
$buildTag = 'BuildTag=2094_RC3.2;'
$baseTag = 'BaseTag=2094_7.6.4;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $initsourcerepo$interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
