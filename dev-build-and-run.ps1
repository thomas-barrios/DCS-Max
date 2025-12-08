# DCS-Max Build and Run Script
# Builds the UI app and launches DCS-Max

param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Define cache paths constant (shared with build-app.ps1)
$cachePaths = @(
    "$env:APPDATA\DCS-Max",
    "$env:LOCALAPPDATA\DCS-Max",
    "$env:TEMP\DCS-Max",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\IndexedDB",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Local Storage"
)

Write-Host "=== DCS-Max Build and Run ===" -ForegroundColor Cyan

# Clean all caches before building
Write-Host "`nCleaning all caches..." -ForegroundColor Yellow

# Clean browser cache
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Clean Vite cache and build directories
Write-Host "Cleaning Vite cache and dist..." -ForegroundColor Yellow
$viteCachePath = Join-Path $scriptDir "ui-app\node_modules\.vite"
$distPath = Join-Path $scriptDir "ui-app\dist"
Remove-Item -Path $viteCachePath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $distPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "All caches cleaned!" -ForegroundColor Green

# Close existing DCS-Max instance BEFORE building
Write-Host "`nChecking for existing DCS-Max instances..." -ForegroundColor Yellow
$closed = $false

# Method 1: Try taskkill first (most reliable)
$tasklistResult = tasklist /FI "IMAGENAME eq DCS-Max.exe" 2>$null | Select-String "DCS-Max"
if ($tasklistResult) {
    Write-Host "Closing DCS-Max via taskkill..." -ForegroundColor Yellow
    taskkill /F /IM "DCS-Max.exe" 2>$null | Out-Null
    $closed = $true
}

# Method 2: Also try by process name as backup
$existingProcess = Get-Process -Name "DCS-Max" -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "Closing existing DCS-Max instance via Stop-Process..." -ForegroundColor Yellow
    $existingProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    $closed = $true
}

# Wait for process to fully terminate
if ($closed) {
    Write-Host "Waiting for process to terminate..." -ForegroundColor Yellow
    $timeout = 10
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $stillRunning = Get-Process -Name "DCS-Max" -ErrorAction SilentlyContinue
        if (-not $stillRunning) {
            break
        }
        Start-Sleep -Milliseconds 500
        $elapsed += 0.5
    }
    if ($elapsed -ge $timeout) {
        Write-Host "Warning: Process may still be running" -ForegroundColor Red
    } else {
        Write-Host "Process terminated successfully" -ForegroundColor Green
    }
    # Extra wait for file handles to be released
    Start-Sleep -Seconds 1
}

# Build the UI app unless -NoBuild is specified
if (-not $NoBuild) {
    Write-Host "`nBuilding UI app..." -ForegroundColor Yellow
    
    $buildScriptPath = Join-Path $scriptDir "ui-app\build-app.ps1"
    
    try {
        & powershell -ExecutionPolicy Bypass -File $buildScriptPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed!" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "Build error: $_" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSkipping build (-NoBuild specified)" -ForegroundColor Yellow
}

# Launch DCS-Max
Write-Host "`nLaunching DCS-Max..." -ForegroundColor Yellow

$exePath = Join-Path $scriptDir "ui-app\bin\Release\net48\DCS-Max.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "Error: DCS-Max.exe not found at $exePath" -ForegroundColor Red
    Write-Host "Run without -NoBuild to build first." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting: $exePath" -ForegroundColor Cyan
Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath -Parent)

Write-Host "`nDCS-Max launched!" -ForegroundColor Green
