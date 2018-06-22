. "$PSScriptRoot\..\_Shared\SourceControlTasks\SourceControlLowLevelFunctionsHg.ps1"

$DebugPreference = "Continue"
Push-Location C:\dev\Platform
try {
    $missingRevisions = SourceControlHg_ForwardChangeCheck "7.7.0" "7.8.0_candidate"
    if ($missingRevisions)
    {
        Write-Host "The following revisions would be reverted (limited to 10):" -ForegroundColor Red
        $missingRevisions | Write-Host -ForegroundColor Red
        Exit 1
    }
}
finally {
    Pop-Location
}
