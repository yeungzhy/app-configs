@echo off
rem ASCII-only launcher for install.ps1 (keeps this file encoding-proof)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
