$initsourcerepo='/p:TrashBranch=trashcan;Preview=false;InitSourceRepo=active;'
$interactive = 'Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = 'Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;SuppressPrefix="true";'
$branches = 'Branches="2094_REQ216.4;2094_CR141.001;2094_REQ058.4;2094_CR039.001;2095_REQ021.5;2095_REQ034.5"'
$buildTag = 'BuildTag=2094_RC3.3;'
$baseTag = 'BaseTag=2094_RC3.2;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:CreateBuild $initsourcerepo$interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
