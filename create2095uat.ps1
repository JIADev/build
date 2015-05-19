$sourcerepo = 'InitSourceRepo=active;TrashBranch=trashcan;'
$customernumber = 'CustomerNumber=2095;'
$interactive = '/p:Interactive=true;'
$branches = ''

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      } else {
      	$branches = $branches + '2095_' + $_ + ';'
      }
}

$customernumber = 'CustomerNumber=2095;SuppressPrefix="true";'
$branches = 'Branches="' + $branches + '"'
$buildTag = 'BuildTag=2095_UATBLD;'
$baseTag = 'BaseTag=2095_RC2015.05.07;'

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $interactive$sourcerepo$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
