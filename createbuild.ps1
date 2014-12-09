$sourcerepo = ''
$customernumber = ''
$branches = ''
$args | foreach {
      if($sourcerepo -eq ''){
        $sourcerepo = '/p:Preview=false;InitSourceRepo=' + $_ + ';CustomerNumber='
      } else {
      	if($customernumber -eq ''){
	  $customernumber = '' + $_  + ';Branches="'
      	} else {
      	  $branches = $branches + $_ + ';'
      	}
      }
}
$branches = $branches + '"'
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $sourcerepo$customernumber$branches $scriptPath\buildtools.proj
