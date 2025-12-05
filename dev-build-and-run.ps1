# DCS-Max Build and Run Script
# Builds the UI app and launches DCS-Max

param(
    [switch]$NoBuild,
    [switch]$Release
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "=== DCS-Max Build and Run ===" -ForegroundColor Cyan

# Build the UI app unless -NoBuild is specified
if (-not $NoBuild) {
    Write-Host "`nBuilding UI app..." -ForegroundColor Yellow
    Push-Location "ui-app"
    
    try {
        & .\build.ps1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed!" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }
    catch {
        Write-Host "Build error: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSkipping build (-NoBuild specified)" -ForegroundColor Yellow
}

# Launch DCS-Max
Write-Host "`nLaunching DCS-Max..." -ForegroundColor Yellow

$exePath = Join-Path $scriptDir "ui-app\bin\DCS-Max.exe"

if (-not (Test-Path $exePath)) {
    Write-Host "Error: DCS-Max.exe not found at $exePath" -ForegroundColor Red
    Write-Host "Run without -NoBuild to build first." -ForegroundColor Yellow
    exit 1
}

# Close existing DCS-Max instance if running
$closed = $false

# Method 1: Try by exact process name
$existingProcess = Get-Process -Name "DCS-Max" -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "Closing existing DCS-Max instance..." -ForegroundColor Yellow
    $existingProcess | Stop-Process -Force -ErrorAction SilentlyContinue
    $closed = $true
}

# Method 2: If not found, try taskkill which is more reliable
if (-not $closed) {
    $tasklistResult = tasklist /FI "IMAGENAME eq DCS-Max.exe" 2>$null | Select-String "DCS-Max"
    if ($tasklistResult) {
        Write-Host "Closing DCS-Max via taskkill..." -ForegroundColor Yellow
        taskkill /F /IM "DCS-Max.exe" 2>$null | Out-Null
        $closed = $true
    }
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
}

Write-Host "Starting: $exePath" -ForegroundColor Cyan
Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath -Parent)

Write-Host "`nDCS-Max launched!" -ForegroundColor Green
