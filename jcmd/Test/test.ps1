function testme
{
    write-host ("The name of this function is: {0} " -f $MyInvocation.MyCommand)
}

$DebugPreference = "Continue"
testme
