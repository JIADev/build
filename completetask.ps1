$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
$noComment = 'true'
$args | foreach {
      $noComment = 'false'
}
if($noComment -eq 'true') {
	 Write-Host "You need a comment"
	 Exit
}
& $msbuild /t:UpdateBuildToolsRepo /p:BuildToolsRepo="$scriptPath" $scriptPath\buildtools.proj
& hg ci -m "$args"
& hg ci -m "Completing task" --close-branch
& hg push

