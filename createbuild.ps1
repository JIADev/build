$customernumber = ''
$branches = ''
$args | foreach { if($customernumber -eq ''){
      	$customernumber = '/p:CustomerNumber=' + $_  + ';Branches="'
      } else {
      	$branches = $branches + $_ + ';'
      }
}
$branches = $branches + '"'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $customernumber$branches $scriptPath\buildtools.proj
