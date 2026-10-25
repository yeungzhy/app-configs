@echo off
rem ASCII-only launcher for uninstall.ps1 (keeps this file encoding-proof)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
