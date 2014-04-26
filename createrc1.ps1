$interactive = '/p:Interactive=true;'

$args | foreach { if($_ -eq '--non-interactive'){
      	$interactive = '/p:Interactive=false;'
      }
}

$customernumber = 'CustomerNumber=2094;'
$branches = 'Branches="REQ044;REQ038;REQ147;REQ064;REQ145;REQ132;REQ129;REQ126"'
$buildTag = 'BuildTag=RC1;'
$baseTag = 'BaseTag=7.6.0;'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& msbuild /t:UpdateReqs $interactive$customernumber$branches $scriptPath\buildtools.proj
& msbuild /t:DependencyMerge_2094 /p:SourceRepo=c:\dev\repos\buildRepo $scriptPath\buildtools.proj
& msbuild /t:CreateBuild $interactive$customernumber$buildTag$baseTag$branches $scriptPath\buildtools.proj
