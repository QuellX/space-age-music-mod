@echo off
rem Double-click to copy the Space Age music from your own Factorio installation into this mod.
rem Optional: drag your Factorio folder onto this file, or pass it as the first argument.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-music.ps1" %*
echo.
pause
