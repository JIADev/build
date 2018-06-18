$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
msbuild /t:CleanJunctions $scriptPath\buildtools.proj
msbuild /t:CleanEmptyDirectories $scriptPath\buildtools.proj
