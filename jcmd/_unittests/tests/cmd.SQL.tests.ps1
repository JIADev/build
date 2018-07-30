. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

EnsureTestGitRepo

Describe 'jcmd SQL tests' {

  Context "SQL Git Tests" {
    It "Should be able to query country table without error" {
        Push-Location $testGitRepoPath
        try {
            $params = @{}
            $params.commandName = "SQL"
            $params.sql = "Select * from dbo.Country"

            $result = & $jcmd @params
            $success = $?
            if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

            ($success -and ($exitCode -eq 0)) | Should -be $true
        }
        finally {
            Pop-Location
        }
    }

    It "Should be able to query country table and return results" {
        Push-Location $testGitRepoPath
        try {
            $params = @{}
            $params.commandName = "SQL"
            $params.sql = "Select * from dbo.Country"

            $result = & $jcmd @params
            $success = $?
            if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

            ($success -and ($exitCode -eq 0)) | Should -be $true
            $result | Should -not -be $null
        }
        finally {
            Pop-Location
        }
    }
}

}


