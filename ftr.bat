@echo off
IF EXIST Core/Boot/Feature.exe GOTO Run
@echo Building Core/Boot/Feature.exe
@echo off
cd Core
msbuild /t:Bootstrap /nologo /v:quiet
cd ..
:Run
CALL "./Core/Boot/Feature.exe" %1 %2 %3 %4 %5 %6 %7 %8 %9