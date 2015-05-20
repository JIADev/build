$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
$noComment = 'true'
$args | foreach {
      $noComment = 'false'
}

& $msbuild /t:UpdateBuildToolsRepo $scriptPath\buildtools.proj
if($noComment -eq 'false') {
	& hg ci -m "$args"
}
& hg ci -m "Completing task" --close-branch
& hg push --new-branch
