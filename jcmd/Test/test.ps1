. "$PSScriptRoot\..\_Shared\SourceControlTasks\SourceControlLowLevelFunctions.ps1"

$DebugPreference = "Continue"
#Push-Location C:\dev\git-active
Push-Location C:\dev\Platform
try {
    #$exists=SourceControlHg_BranchExists "7.7.0"
    $output=(SourceControlHg_ForwardChangeCheck MPS_Sprint3)
    Write-Host $output -ForegroundColor Yellow
}
catch {
}
finally {

}

