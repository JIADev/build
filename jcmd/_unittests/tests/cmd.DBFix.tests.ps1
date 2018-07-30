. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

EnsureTestGitRepo

$scripts = Get-ChildItem "..\..\DBFix\*.sql"

Describe 'jcmd DBFix tests' {

    Context "DBFix Base Tests" {
        It "Should not fail when called with no parameters" {
            Push-Location $testGitRepoPath
            #SourceControl_SetBranch $testGitBranch
            try {
                #configure the folder
                $params = @{}
                $params.commandName = "DBFix"
    
                & $jcmd @params
                $success = $?
                if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE; } else { $exitCode = 0; }
    
                ($success -and ($exitCode -eq 0)) | Should -be $true
            }
            finally {
                Pop-Location
            }
        }
    }
    
    Context "DBFix Script Tests" {

        foreach ($script in $scripts) {
            $scriptName = [IO.Path]::GetFileNameWithoutExtension($(Split-Path $script -Leaf)) 

            It "Testing script $scriptName" {
                Push-Location $testGitRepoPath
                #SourceControl_SetBranch $testGitBranch
                try {
                    #configure the folder
                    $params = @{}
                    $params.commandName = "DBFix"
                    $params.script = $scriptName
                    $params.quiet = $true
    
                    & $jcmd @params
                    $success = $?
                    if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE; } else { $exitCode = 0; }
    
                    ($success -and ($exitCode -eq 0)) | Should -be $true
                }
                finally {
                    Pop-Location
                }
            }
    
            It "Testing 2nd successive call to script $scriptName" {
                Push-Location $testGitRepoPath
                #SourceControl_SetBranch $testGitBranch
                try {
                    #configure the folder
                    $params = @{}
                    $params.commandName = "DBFix"
                    $params.script = $scriptName
                    $params.quiet = $true

                    & $jcmd @params
                    $success = $?
                    if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE; } else { $exitCode = 0; }
    
                    ($success -and ($exitCode -eq 0)) | Should -be $true
                }
                finally {
                    Pop-Location
                }
            }
        }

    }

}


