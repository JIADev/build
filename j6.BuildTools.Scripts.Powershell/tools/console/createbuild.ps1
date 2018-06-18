$trashBranches = @{ 'active' = ';TrashBranch=trashcan'; 'prod' = ';TrashBranch=trash' }
$trashBranch = ''
$sourcerepo = ''
$customernumber = ''
$branches = ''
$args | foreach {
      if($sourcerepo -eq ''){
        $sourcerepo = '/p:Preview=false;InitSourceRepo=' + $_ + ';CustomerNumber='
	$trashBranch = $trashBranches[$_]
      } else {
      	if($customernumber -eq ''){
	  $customernumber = '' + $_  + ';Branches="'
      	} else {
      	  $branches = $branches + $_ + ';'
      	}
      }
}
$branches = $branches + '"'
Write-Host "TrashBranch is $trashBranch"
Write-Host "SourceRepo is $sourcerepo"
Write-Host "TrashBranches is $trashBranches"
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:CreateBuild $sourcerepo$customernumber$branches$trashBranch $scriptPath\buildtools.proj
