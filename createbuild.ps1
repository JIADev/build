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
msbuild /t:CreateBuild $customernumber$branches $scriptPath\buildtools.proj
