$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_REQ143;2094_RM48203;2094_REQ188;2094_REQ179;2094_REQ078;2094_REQ089;2094_REQ054"'
$buildTag = 'BuildTag=2094_RC2;'
$baseTag = 'BaseTag=7.6.1;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
