@echo off
IF EXIST Core/Boot/Feature.exe GOTO RunNew
IF NOT EXIST Core GOTO RunOld
@echo Building Core/Boot/Feature.exe
@echo off
cd Core
msbuild /t:Bootstrap /nologo /v:quiet
cd ..
:RunNew
CALL "./Core/Boot/Feature.exe" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO End
:RunOld
CALL "Feature.exe" %1 %2 %3 %4 %5 %6 %7 %8 %9
:End