. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

Describe 'jcmd Help tests' {

  Context "Base Help Tests" {
        It "Should not fail" {
        $params = @{}
        $params.commandName = "Help"
        $params.helpCommand = "ListCommands"

        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }
  }

}


