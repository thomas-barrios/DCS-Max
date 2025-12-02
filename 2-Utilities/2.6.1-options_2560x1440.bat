@echo off
setlocal
set "CFG_DIR=D:\Users\Thomas\Saved Games\DCS\Config"
set "DEFAULT=%CFG_DIR%\_DEFAULT-2560x1440_options.lua"
set "OPTIONS=%CFG_DIR%\options.lua"

if not exist "%DEFAULT%" copy /Y "%OPTIONS%" "%DEFAULT%"
copy /Y "%DEFAULT%" "%OPTIONS%"
endlocal
