. "$PSScriptRoot\SourceControlLowLevelFunctions.ps1"

function SourceControl_PushChanges() { 
	 $currentDir = Convert-Path .
	 $arguments = "push --new-branch"

	 $hgStartInfo = SourceControl_GetStartInfo $arguments $currentDir $true $true
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

function SourceControl_UpdateBuildTools() {
	$hgStartInfo = SourceControl_GetStartInfo "pull -u" $scriptPath $false
	$p = runProcess $hgStartInfo
	return $p.ExitCode
}

function SourceControl_NewBranch($branch) {
	$currentDir = Convert-Path .
	$arguments = "branch " + $branch
	$hgStartInfo = SourceControl_GetStartInfo $arguments $currentDir $false $true
	$p = runProcess $hgStartInfo
	if($p.ExitCode -eq 0) { 
		return $true
	} 
	$errorOutput = $p.StandardError.ReadLine().Trim()
	if($errorOutput -eq 'abort: a branch of the same name already exists') { 
		return $false
	}
}

function SourceControl_EnsureBranchUp($branch) {
	$currentDir = Convert-Path .
	$branchCreated = newBranch $branch
	if($branchCreated -eq $true) {
		return 0;
	}
	$updateToBranch = Read-Host "Branch $branch already exists.  Update to branch? (y/n)"
	$letters = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'
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
	$hgStartInfo = SourceControl_GetStartInfo $arguments $currentDir $false
	$p = runProcess $hgStartInfo  
	return $p.ExitCode
}

function SourceControl_EnsureBranchIncludes($branch) {
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

function SourceControl_GraftToWorking($graftRevision, $args) 
{
    if($graftRevision.Length -eq 0) 
    { 
        Write-Host "No graft revisions listed"
        Write-Host $usageMessage
        Exit
    }

    hg graft $graftRevision --tool=internal:merge
    if($LastExitCode -ne 0) 
    {
		hg resolve --all
		hg graft --continue	
	}
}