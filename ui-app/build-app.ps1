# DCS-Max UI App Build Script
# Builds the React app using Vite and copies to web folder

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Building DCS-Max UI..." -ForegroundColor Cyan

# Clean browser cache before building
Write-Host "Cleaning browser cache..." -ForegroundColor Yellow
# Cache paths (matching dev-build-and-run.ps1 for consistency)
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

foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "Cache cleaned!" -ForegroundColor Green

# Rebuild the C# application
Write-Host "`nRebuilding the C# application..." -ForegroundColor Yellow
try {
    Write-Host "Running: dotnet build DcsMaxLauncher.csproj -c Release" -ForegroundColor Cyan
    $buildOutput = dotnet build DcsMaxLauncher.csproj -c Release 2>&1
    
    # Check for build errors - only fail on actual error code
    if ($LASTEXITCODE -ne 0) {
        Write-Host "C# build failed!" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Red
        exit 1
    }
    Write-Host "C# build completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "C# build error: $_" -ForegroundColor Red
    exit 1
}

# Check if npm is available
$npmCheck = npm --version 2>$null
if (-not $npmCheck) {
    Write-Host "Error: npm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "npm version: $npmCheck"

# Install dependencies if node_modules doesn't exist
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "npm install failed!" -ForegroundColor Red
        exit 1
    }
}

# Build with Vite
Write-Host "Running Vite build..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build completed successfully!" -ForegroundColor Green
exit 0
