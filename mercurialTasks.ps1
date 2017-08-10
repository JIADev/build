$letters = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
function getHgStartInfo([string]$arguments, [string]$workingDir, [bool]$redirectStdOut, [bool]$redirectStdErr) {
	$hgStartInfo = New-Object System.Diagnostics.ProcessStartInfo
	$hgStartInfo.FileName = "hg.exe"
	$hgStartInfo.UseShellExecute = $false
	$hgStartInfo.Arguments = $arguments
	$hgStartInfo.WorkingDirectory = $workingDir
	$hgStartInfo.RedirectStandardOutput = $redirectStdOut
	$hgStartInfo.RedirectStandardError = $redirectStdErr
	return $hgStartInfo
}

function runProcess($hgStartInfo) {
	$runMessage = "Running in " + $hgStartInfo.WorkingDirectory + ": " + $hgStartInfo.FileName + " " + $hgStartInfo.Arguments
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $hgStartInfo
	$p.Start() | Out-Null
	$p.WaitForExit()
	return $p
}

function hasPendingChanges() {
	 $currentDir = Convert-Path .
	 $hgStartInfo = getHgStartInfo "status" $currentDir $true
	 $p = runProcess $hgStartInfo
	 if($p.ExitCode -ne 0) { return 'unknown pending changes exist' }
	 $pendingChanges = @()
	 while($p.StandardOutput.EndOfStream -eq $false)
	 {
		$modifiedFile = $p.StandardOutput.ReadLine().Trim()
		if($modifiedFile.StartsWith("? ") -eq $false){
			Write-Host $modifiedFile
			$pendingChanges += $modifiedFile
		}
	 }
	 return $pendingChanges.length -gt 0
}

function getCurrentBranch() {
	$currentDir = Convert-Path .
	 $hgStartInfo = getHgStartInfo "branch" $currentDir $true
	$p = runProcess $hgStartInfo
	if($p.ExitCode -ne 0) { return '' }
	$currentBranch = $p.StandardOutput.ReadToEnd().Trim()
	return $currentBranch
}

function pushChanges() { 
	 $currentDir = Convert-Path .
	 $arguments = "push --new-branch"

	 $hgStartInfo = getHgStartInfo $arguments $currentDir $true $true
	 $p = runProcess $hgStartInfo
	 if($p.ExitCode -eq 0) {
		return $true
	 }	 
	$errorOutput = $p.StandardError.ReadLine().Trim()
	if($errorOutput -match 'abort: push creates new remote head') {
		& hg pull
		& hg merge --tool=internal:merge
		if($LastExitCode -ne 0) {
			& hg resolve --all
			if($LastExitCode -ne 0) { 
				Write-Host "Cannot merge heads"
				Exit
			}
		}
		Write-Host "Committing Merge"
		& hg ci -m "@merge"
		& hg push --new-branch
		
  		if($LastExitCode -ne 0) { 
			Write-Host "Cannot push"
			Exit
		}
	} else {
		Write-Host "Cannot push"
	}
}

function updateBuildTools() {
	$hgStartInfo = getHgStartInfo "pull -u" $scriptPath $false
	$p = runProcess $hgStartInfo
	return $p.ExitCode
}

function newBranch($branch) {
	$currentDir = Convert-Path .
	$arguments = "branch " + $branch
	$hgStartInfo = getHgStartInfo $arguments $currentDir $false $true
	$p = runProcess $hgStartInfo
	if($p.ExitCode -eq 0) { 
		return $true
	} 
	$errorOutput = $p.StandardError.ReadLine().Trim()
	if($errorOutput -eq 'abort: a branch of the same name already exists') { 
		return $false
	}
}

function ensureBranchUp($branch) {
	$currentDir = Convert-Path .
	$branchCreated = newBranch $branch
	if($branchCreated -eq $true) {
		return 0;
	}
	$updateToBranch = Read-Host "Branch $branch already exists.  Update to branch? (y/n)"
	if($updateToBranch -ne 'y') {
                foreach ($letter in $letters) {

			$letteredBranch = $branch + '.' + $letter
			$branchCreated = newBranch $letteredBranch
			if($branchCreated -eq $true){
			Write-Host "Created"
			  break
			}
			  $updateToBranch = Read-Host "Branch $letteredBranch already exists.  Update to branch? (y/n)"
			  if($updateToBranch -eq 'y') {
			  	$branch = $letteredBranch
				break
			}
		}
		if($branchCreated -eq $true) { 
			return 0
		}
	}
	if($updateToBranch -ne 'y') {
	        return $p.ExitCode
	}
	$arguments = "update " + $branch
	$hgStartInfo = getHgStartInfo $arguments $currentDir $false
	$p = runProcess $hgStartInfo  
	return $p.ExitCode
}

function ensureBranchIncludes($branch) {
	$currentDir = Convert-Path .
	Write-Host "Merging $branch"
	& hg merge $branch --tool=internal:merge
	if($LastExitCode -ne 0) {
		& hg resolve --all
		if($LastExitCode -ne 0) { 
			Write-Host "Looks like $branch is already an ancestor, No problem"
			return
		}
	}
	Write-Host "Committing Merge"
	& hg ci -m "@merge $branch"
}