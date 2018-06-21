. "$PSScriptRoot\..\_Shared\SourceControlLowLevelFunctionsHg.ps1"

$args|format-list



$RevertPath = "C:\dev\work1"

Push-Location $RevertPath
try {
    $DebugPreference = "Continue"
    SourceControlHg_GetRemovedFiles
}
finally {
    Pop-Location
}
