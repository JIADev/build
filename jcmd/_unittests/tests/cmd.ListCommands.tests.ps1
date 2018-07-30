. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

Describe 'jcmd ListCommands tests' {

  Context "Base ListCommands Tests" {
        It "Should not fail" {
        $params = @{}
        $params.commandName = "ListCommands"

        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }
  }

}


