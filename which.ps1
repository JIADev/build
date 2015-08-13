$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$strBin = "$scriptPath\bin"
$strWhichExe = "$strBin\which.exe"
if(test-path $strWhichExe) {
}
else {
     if(test-path $strBin) { }
     else {
     	  md $strBin
     }
     $msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
     & $msbuild /t:BuildWhichExe $scriptPath\buildtools.proj
}
& $strWhichExe $args