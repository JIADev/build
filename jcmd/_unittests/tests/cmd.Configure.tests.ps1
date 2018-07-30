. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

EnsureTestGitRepo

Describe 'jcmd Configure tests' {

  Context "Base Configure Tests" {
    It "Should not fail" {
        Push-Location $testGitRepoPath
        #SourceControl_SetBranch $testGitBranch
        try {
            #configure the folder
            $params = @{}
            $params.commandName = "Configure"
            $params.CustomerCode = $testCustomerId
            $params.DatabaseName = $testDBName
            $params.CacheDBId = 16

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


