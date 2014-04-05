$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
& $scriptPath\createtrack1.ps1 --non-interactive

& $scriptPath\createtrack3.ps1 --non-interactive
& $scriptPath\createtrack4.ps1 --non-interactive
& $scriptPath\createtrack5.ps1 --non-interactive
& $scriptPath\createrc1.ps1