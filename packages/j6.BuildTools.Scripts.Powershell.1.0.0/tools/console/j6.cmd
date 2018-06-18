@echo off
powershell -NoLogo -NoProfile -Command ". %~dp0\j6.ps1 %*; exit $LASTEXITCODE"
