@echo off
:: Elevate to Admin if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Launch in Windows Terminal if available, else PowerShell
where wt >nul 2>&1
if %errorLevel% == 0 (
    wt.exe --title "PC Clean & IP Reset" powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0PcClean-IpReset.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0PcClean-IpReset.ps1"
)
