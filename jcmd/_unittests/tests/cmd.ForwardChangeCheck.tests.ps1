. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

Describe 'jcmd ForwardChangeCheck tests' {

  Context "Base ForwardChangeCheck Tests" {
    It "Should not fail when checking same branch" {
        Push-Location $testGitRepoPath
        SourceControl_SetBranch $testGitBranch
        try {
            $params = @{}
            $params.commandName = "ForwardChangeCheck"
            $params.baseBranch = $testGitBranch

            & $jcmd @params
            $success = $?
            if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

            ($success -and ($exitCode -eq 0)) | Should -be $true
        }
        finally {
            Pop-Location
        }
    }

    It "Should fail when checking very old branch" {
        Push-Location $testGitRepoPath
        SourceControl_SetBranch $testGitBranch
        try {
            $params = @{}
            $params.commandName = "ForwardChangeCheck"
            $params.baseBranch = "7.7.0"

            & $jcmd @params
            $success = $?
            if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

            ($success -and ($exitCode -eq 0)) | Should -be $false
        }
        finally {
            Pop-Location
        }
    }

}

}


