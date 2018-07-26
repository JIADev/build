<#
.SYNOPSIS
  Updates jcmd to the latest version from source control.
.DESCRIPTION
  Updates the folder containing jcmd using a "git pull".
.EXAMPLE
  PS C:\>jcmd updatejcmd
.NOTES
#>

. "$PSScriptRoot\_Shared\common.ps1"
. "$PSScriptRoot\_shared\SourceControl\SourceControl.ps1"


$cmdFolder = "$PSScriptRoot\..";

#switch to the jcmd folder
Push-Location $cmdFolder
#get the resolved folder name
$folder = Get-Location
try {
  Write-ColorOutput "Updating $folder from source control..." -ForegroundColor Cyan
  
  #make sure there are no pending changes
  $hasPendingChanges = SourceControl_HasPendingChanges
  if ($hasPendingChanges -eq $true) {
    Write-ColorOutput "Cannot update " Red
    Exit 1
  }

  #get the current branch and update
  $branch = SourceControl_GetCurrentBranch
  SourceControl_UpdateBranchToHead $branch

  Write-ColorOutput "Update Complete" -ForegroundColor Cyan
}
finally {
	#switch back to the user's path
	Pop-Location
}

