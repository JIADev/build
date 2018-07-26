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

Push-Location $cmdFolder
$folder = Get-Location
try {
  Write-ColorOutput "Updating $folder from source control..." -ForegroundColor Cyan
  $hasPendingChanges = SourceControl_HasPendingChanges
  if ($hasPendingChanges -eq $true) {
    Write-ColorOutput "Cannot update " Red
    Exit 1
  }

  $branch = SourceControl_GetCurrentBranch
  SourceControl_UpdateBranchToHead $branch

  Write-ColorOutput "Update Complete" -ForegroundColor Cyan
}
finally {
  Pop-Location
}

