# Pester tests
Set-StrictMode -Version Latest

$jcmd = "$PSScriptRoot\..\..\..\jcmd.ps1"
$argTestCommand=".\_unittests\helpers\argtest"
$exitCodeTestCommand=".\_unittests\helpers\exitcodetest"

Describe 'jcmd shim tests' {

  Context "Basic Tests" {
    It "Given no parameters, doesnt fail" {
      $result = & $jcmd
    }
  }

  Context 'jcmd passes exact parameters to specified command' {
    It "passes no parameters" {
      $result = & $jcmd $argTestCommand
      $result | Should -Be $null
    }

    It "passes one parameter" {
      $result = & $jcmd $argTestCommand 1
      $result | Should -Be "1"
    }

    It "passes multiple parameters" {
      $result = & $jcmd $argTestCommand 1 2 3
      $result | Should -Be @(1, 2, 3)
    }

    It "passes quoted parameter" {
      $p = "a b c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes quoted parameter with other parameters" {
      $p = "a b c"
      $result = & $jcmd $argTestCommand 1 $p 2
      $result | Should -Be @(1, $p, 2)
    }

    It "passes multiple quoted parameter with other parameters" {
      $p = "a b c"
      $result = & $jcmd $argTestCommand 1 $p 2 $p $p 3
      $result | Should -Be @(1, $p, 2, $p, $p, 3)
    }

    It "passes quoted parameter with double quotes" {
      $p = "a `"b`" c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes multiple quoted parameter with double quotes and other parameters" {
      $p = "a `"b`" c"
      $result = & $jcmd $argTestCommand 1 $p 2 $p $p 3
      $result | Should -Be @(1, $p, 2, $p, $p, 3)
    }

    It "passes quoted parameter with unmatched double quotes" {
      $p = "a `"b c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes multiple quoted parameter with unmatched double quotes and other parameters" {
      $p = "a `"b c"
      $result = & $jcmd $argTestCommand 1 $p 2 $p $p 3
      $result | Should -Be @(1, $p, 2, $p, $p, 3)
    }

    It "passes quoted parameter with double double quotes" {
      $p = "a `"`"b`"`" c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes quoted parameter with single quotes" {
      $p = "a 'b' c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes string parameters carriage return quotes" {
      $p = "a `nb c"
      $result = & $jcmd $argTestCommand $p
      $result | Should -Be @($p)
    }

    It "passes object parameters" {
      #obj has multiple properties
      $obj = Get-Location
      $result = & $jcmd $argTestCommand 1 $obj
      $result | Should -Be @(1, $obj)
    }
  }

  Context "Exit code tests" {
    It "return command exit code when 1" {
      [int] $exitCode = 1
      $result = & $jcmd $exitCodeTestCommand $exitCode
      $LASTEXITCODE | Should -Be $exitCode
    }

    It "return command exit code when greater than 1" {
      [int] $exitCode = 99
      $result = & $jcmd $exitCodeTestCommand $exitCode
      $LASTEXITCODE | Should -Be $exitCode
    }

    It "return command exit code when -1" {
      [int] $exitCode = -1
      $result = & $jcmd $exitCodeTestCommand $exitCode
      $LASTEXITCODE | Should -Be $exitCode
    }

    It "return command exit code when exception thrown" {
      [int] $exitCode = -100
      $result = & $jcmd $exitCodeTestCommand $exitCode "ERROR!"
      $LASTEXITCODE | Should -Be $exitCode
    }
  }
}


