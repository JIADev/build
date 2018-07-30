. "$PSScriptRoot\_common.ps1"
. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

# Pester tests
Set-StrictMode -Version Latest

Describe 'jcmd Flush tests' {

  Context "Base Flush Tests" {
    It "Flush IIS" {
        $params = @{}
        $params.commandName = "Flush"
        $params.services = "iis"
    
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }

    It "Flush SQL" {
        $params = @{}
        $params.command = "Flush"
        $params.services = "sql"
    
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }

    It "Flush redis" {
        $params = @{}
        $params.command = "Flush"
        $params.services = "redis"
    
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }

    It "Flush iisexpress" {
        $params = @{}
        $params.command = "Flush"
        $params.services = "iisexpress"
    
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }

    It "Flush All" {
        $params = @{}
        $params.command = "Flush"
        $params.services = "all"
    
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        ($success -and ($exitCode -eq 0)) | Should -be $true
    }


}

}


