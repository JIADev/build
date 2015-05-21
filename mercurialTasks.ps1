function getCurrentBranch() {
	$hgStartInfo = New-Object System.Diagnostics.ProcessStartInfo
	$hgStartInfo.FileName = "hg.exe"
	$hgStartInfo.UseShellExecute = $false
	$hgStartInfo.Arguments = "branch"
	$currentDir = Convert-Path .
	$hgStartInfo.WorkingDirectory = $currentDir
	$hgStartInfo.RedirectStandardOutput = $true
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $hgStartInfo
	$p.Start() | Out-Null
	$p.WaitForExit()
	if($p.ExitCode -ne 0) { return '' }
	$currentBranch = $p.StandardOutput.ReadToEnd()
	return $currentBranch
}

function updateBuildTools() {
	$hgStartInfo = New-Object System.Diagnostics.ProcessStartInfo
	$hgStartInfo.FileName = "hg.exe"
	$hgStartInfo.UseShellExecute = $false
	$hgStartInfo.Arguments = "pull -u"
	$hgStartInfo.WorkingDirectory = $scriptPath
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $hgStartInfo
	$p.Start() | Out-Null
	$p.WaitForExit()
	return $p.ExitCode
}