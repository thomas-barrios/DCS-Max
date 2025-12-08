@echo off
REM DCS-Max Launcher
REM Double-click to start DCS-Max UI

cd /d "%~dp0"

REM Launch the WebView2 app - check release location first, then dev location
if exist "ui-app\bin\DCS-Max.exe" (
    start "" "ui-app\bin\DCS-Max.exe"
) else if exist "ui-app\bin\Release\net48\DCS-Max.exe" (
    start "" "ui-app\bin\Release\net48\DCS-Max.exe"
) else (
    echo First run - building DCS-Max...
    cd ui-app
    powershell -ExecutionPolicy Bypass -File "build-app.ps1"
    cd ..
    if exist "ui-app\bin\Release\net48\DCS-Max.exe" (
        start "" "ui-app\bin\Release\net48\DCS-Max.exe"
    ) else (
        echo Build failed! Check errors above.
        pause
    )
)
