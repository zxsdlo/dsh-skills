@echo off
setlocal
chcp 65001 >nul 2>&1

rem dsh-workspace-init launcher (keep this file pure ASCII: cmd.exe reads batch in the OEM codepage)
rem   double-click              -> initialize the folder this .cmd sits in
rem   init-workspace.cmd DIR    -> initialize DIR
rem   init-workspace.cmd /push  -> initialize here, then commit + push

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "TARGET=%~1"
set "EXTRA="

if /I "%~1"=="/push" set "TARGET=%HERE%"
if /I "%~1"=="/push" set "EXTRA=-Push"
if "%TARGET%"=="" set "TARGET=%HERE%"
if /I "%~2"=="/push" set "EXTRA=-Push"
rem a trailing backslash would eat the closing quote of the PowerShell argument
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HERE%\init-workspace.ps1" -Target "%TARGET%" %EXTRA%
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (echo ALL OK) else (echo FINISHED WITH WARNINGS - see WARN lines above)
echo.
pause
endlocal
exit /b %RC%
