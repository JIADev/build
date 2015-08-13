$buildTag = 'UATBLD;'
$branches = $buildTag

$args | foreach { 
      	$branches = $branches + $_ + ';'
}

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
& $scriptPath\create2095uat.ps1 $branches
