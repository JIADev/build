$initsourcerepo='/p:TrashBranch=trashcan;Preview=false;InitSourceRepo=active;'
$interactive = 'Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = 'Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_REQ216.4"'
$buildTag = 'BuildTag=2094_RC3.2;'
$baseTag = 'BaseTag=7.6.5;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $initsourcerepo$interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
