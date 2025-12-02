@echo off
setlocal
set "CFG_DIR=C:\Users\Thomas\AppData\Local\Pimax\runtime"
set "DEFAULT=%CFG_DIR%\__DEFAULT_ImageQuality62_profile.json"
set "OPTIONS=%CFG_DIR%\profile.json"

if not exist "%DEFAULT%" copy /Y "%OPTIONS%" "%DEFAULT%"
copy /Y "%DEFAULT%" "%OPTIONS%"
endlocal
