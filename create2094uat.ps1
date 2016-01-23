$sourcerepo = 'InitSourceRepo=active;TrashBranch=trashcan;'
$customernumber = 'CustomerNumber=2094;'
$interactive = '/p:Interactive=true;'
$branches = ''

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      } else {
      	$branches = $branches + $_ + ';'
      }
}

$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="' + $branches + '"'
$buildTag = 'BuildTag=UATBLD;'
$baseTag = 'BaseTag=UAT;'

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $interactive$sourcerepo$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
