. "$PSScriptRoot\..\..\_shared\SourceControl\SourceControl.ps1"

$jcmd = "$PSScriptRoot\..\..\..\jcmd.ps1"
$testGitRepoPath = "c:\temp\jcmd\tests\git"
$testMercurialRepoPath = "c:\temp\jcmd\tests\hg"
$testDBName="UnitTest_1002"
$testCustomerId="CUST1002"
$testGitBranch="7.8.0"
$testMercurialBranch="7.8.0"

if (!(Test-Path $jcmd))
{
    Write-Host "Testing path to jcmd invalid!" -ForegroundColor Red
    Throw "Testing path to jcmd invalid!"
}

function EnsureTestGitRepo()
{

    if (!(Test-Path  $testGitRepoPath))
    {
        #clone the repo
        gitcmd clone,"https://jenkon.visualstudio.com/j6%20Core%20Product/_git/active",$testGitRepoPath
    }

    Push-Location $testGitRepoPath
    try {
        
        #checkout the right folder and make sure we are on the tip
        SourceControl_UpdateBranchToHead $testGitBranch
        
        #configure the folder
        $params = @{}
        $params.commandName = "Configure"
        $params.CustomerCode = $testCustomerId
        $params.DatabaseName = $testDBName
        $params.CacheDBId = 16
        
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        if (!$success -or ($exitCode -gt 0))
        {
            Write-Output "The command '$jcmd $params' exited with error code: $exitCode"
            Exit $exitCode
        }

        #configure the folder
        $params = @{}
        $params.commandName = "Flush"
        $params.services = "redis"
        
        & $jcmd @params
        $success = $?
        if (Test-Path VARIABLE:GLOBAL:LASTEXITCODE) {$exitCode = $GLOBAL:LASTEXITCODE;} else { $exitCode = 0;}

        if (!$success -or ($exitCode -gt 0))
        {
            Write-Output "The command '$jcmd $params' exited with error code: $exitCode"
            Exit $exitCode
        }
    }
    finally {
        Pop-Location    
    }

}

