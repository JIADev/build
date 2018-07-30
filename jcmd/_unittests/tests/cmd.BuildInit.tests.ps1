. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

EnsureTestGitRepo

Describe 'jcmd BuildInit tests' {

  Context "BuildInit Git Tests" {
    It "Should not fail when building $testGitBranch" {
        Push-Location $testGitRepoPath
        SourceControl_SetBranch $testGitBranch
        try {
            $params = @{}
            $params.commandName = "BuildInit"
            $params.ignoreVS = $true

            & $jcmd @params
            $success = $?
            if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

            ($success -and ($exitCode -eq 0)) | Should -be $true
        }
        finally {
            Pop-Location
        }
    }
  }

}


