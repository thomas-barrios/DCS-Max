@echo off
REM DCS-Max WebView2 Launcher
REM This launches the lightweight WebView2-based UI

cd /d "%~dp0"

REM Check if build exists
if exist "bin\DCS-Max.exe" (
    start "" "bin\DCS-Max.exe"
    exit /b 0
)

REM Build not found, try to build
echo DCS-Max executable not found. Building...
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1"

if exist "bin\DCS-Max.exe" (
    start "" "bin\DCS-Max.exe"
) else (
    echo Build failed! Please check the error messages above.
    pause
)
