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
  Write-ColorOutput "Checking  $folder for pending changes..." -ForegroundColor Cyan
  
  #make sure there are no pending changes
  $hasPendingChanges = SourceControl_HasPendingChanges
  if ($hasPendingChanges -eq $true) {
    Write-ColorOutput "Cannot update, there are pending changes!" Red
    Exit 1
  }

  Write-ColorOutput "Checking Cource Control Origin for $folder ..." -ForegroundColor Cyan
  $remote = SourceControl_GetRemoteUrl
  if ($remote -match "github")
  {
    $newRemote = "https://jenkon.visualstudio.com/j6%20Core%20Product/_git/build"
    $result = SourceControl_SetRemoteUrl $newRemote

    if ($result -ne $newRemote)
    {
      throw "There was a problem updating the build folder remote url. Please resolve this issue manually!"
    }
  }


  Write-ColorOutput "Updating $folder from source control..." -ForegroundColor Cyan
  #get the current branch and update
  $branch = SourceControl_GetCurrentBranch
  SourceControl_UpdateBranchToHead $branch

  Write-ColorOutput "Update Complete" -ForegroundColor Cyan
}
finally {
	#switch back to the user's path
	Pop-Location
}

