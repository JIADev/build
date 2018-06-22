Param(
  [string]$commandName
)

#the cmd folder is where jcmd expects to find all of the command scripts
#either in .\[commandName].ps1 files or .\[commandName]\[commandName].ps1
$cmdFolder = Join-Path $PSScriptRoot "jcmd";


#look for the command as a ps1 file in the command folder
$cmdScript = Join-Path $cmdFolder "$commandName.ps1";
if (Test-Path $cmdScript)
{
    #log the command details for debugging purposes
    Write-Debug "Executing: $cmdScript"
    Write-Debug $($args -join '|' | Out-String)

    & $cmdScript $args
    exit $LASTEXITCODE
}

#look for the command in a folder with the same name (ie .\revertall\revertall.ps1)
$cmdFolder = Join-Path $cmdFolder $commandName;
$cmdScript = Join-Path $cmdFolder "$commandName.ps1";
if (Test-Path $cmdScript)
{
    #log the command details for debugging purposes
    Write-Debug "Executing: $cmdScript"
    Write-Debug $($args -join '|' | Out-String)

    & $cmdScript $args
    exit $LASTEXITCODE
}

#if we didn't find the command then there is nothing to do but report the error 
#and fail with an exit code
Write-Host "ERROR: jcmd command '$commandName' not found!" -ForegroundColor Red
exit 1