$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateBuildToolsRepo $scriptPath\buildtools.proj
Write-Host "Version 1"

$ongoingBranch = '2095_QA2015.05.19'
$noComment = 'true'
$args | foreach {
      $noComment = 'false'
}

if($noComment -eq 'false') {
	& hg ci -m "$args"
	if($LastExitCode -ne 0) { 
		Write-Host "Commit failed"
		Exit
	}
}

& hg ci -m "Completing task" --close-branch
if($LastExitCode -ne 0) { 
	Write-Host "Closing task branch failed"
	Exit
}
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "hg.exe"
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false
$pinfo.Arguments = "branch"
$currentDir = Convert-Path .
$pinfo.WorkingDirectory = $currentDir
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()
$currentBranch = $p.StandardOutput.ReadToEnd()

if($p.ExitCode -ne 0) { 
	Write-Host "Cannot determine my branch"
	Exit
}

Write-Host "Updating to branch $ongoingBranch"
& hg up $ongoingBranch
if($LastExitCode -ne 0) { 
	Write-Host "Cannot update to $ongoingBranch"
	Exit
}
Write-Host "Merging $currentBranch to $ongoingBranch"

& hg merge $currentBranch
if($LastExitCode -ne 0) { 
	Write-Host "Cannot merge $currentBranch to $ongoingBranch"
	Exit
}

& Write-Host "hg push --new-branch"
