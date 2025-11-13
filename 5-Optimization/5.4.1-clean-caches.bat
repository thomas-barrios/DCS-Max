@echo off
REM DCS-Max Cache Cleaning Script
REM Version: 5.4.1
REM Purpose: Clean various caches that can affect DCS performance

echo ========================================
echo DCS-Max Cache Cleaner v5.4.1
echo ========================================
echo.

echo Cleaning NVIDIA caches...
if exist "%LOCALAPPDATA%\NVIDIA\DXCache\" (
    echo Cleaning NVIDIA DXCache...
    del /q /s "%LOCALAPPDATA%\NVIDIA\DXCache\*.*" 2>nul
    rmdir /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" 2>nul
)

if exist "%LOCALAPPDATA%\NVIDIA\GLCache\" (
    echo Cleaning NVIDIA GLCache...
    del /q /s "%LOCALAPPDATA%\NVIDIA\GLCache\*.*" 2>nul
    rmdir /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" 2>nul
)

if exist "%LOCALAPPDATA%\NVIDIA\OptixCache\" (
    echo Cleaning NVIDIA OptixCache...
    del /q /s "%LOCALAPPDATA%\NVIDIA\OptixCache\*.*" 2>nul
    rmdir /s /q "%LOCALAPPDATA%\NVIDIA\OptixCache" 2>nul
)

echo.
echo Cleaning Windows temp files...
del /q /s "%TEMP%\*.*" 2>nul

echo.
echo Cleaning DCS-related temp files...
if exist "%USERPROFILE%\Saved Games\DCS\Temp\" (
    echo Cleaning DCS Temp folder...
    del /q /s "%USERPROFILE%\Saved Games\DCS\Temp\*.*" 2>nul
)

echo.
echo Cache cleaning completed!
echo Please restart your computer for full effect.
echo.
pause