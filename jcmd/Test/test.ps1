. "$PSScriptRoot\..\_shared\common.ps1"

function testme
{
    Write-ColorOutput ("The name of this function is: {0} " -f $MyInvocation.MyCommand) red
}

testme
