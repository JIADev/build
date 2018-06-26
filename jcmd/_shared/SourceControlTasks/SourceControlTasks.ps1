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

function SourceControl_EnsureBranchUp($branch) {
	if (SourceControl_BranchExists $branch)
	{
		SourceControlGit_UpdateBranch $branch
	}
	else
	{
		SourceControl_NewBranch $branch	
	}
}

function SourceControl_EnsureBranchIncludes($branch) {
	Write-Host "Merging $branch"
	SourceControl_Merge $branch $true
	SourceControl_ResolveAll
	Write-Host "Committing Merge"
	SourceControl_Commit "@merge $branch"
}

