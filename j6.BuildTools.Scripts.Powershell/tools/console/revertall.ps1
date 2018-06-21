$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

if (test-path ".\.git")
{
	& "$scriptPath\jcmd.ps1" RevertAll $args
	exit $LastExitCode
}

$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:RevertAll $scriptPath\buildtools.proj
