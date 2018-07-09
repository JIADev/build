. "$PSScriptRoot\..\_shared\common.ps1"

function testme
{
    ("The name of this function is: {0} " -f $MyInvocation.MyCommand) | Write-ColorOutput -ForegroundColor red
}

testme
