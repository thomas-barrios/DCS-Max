#Requires -RunAsAdministrator
<#
.SYNOPSIS
    DCS-Max Cache Cleaning Script
.DESCRIPTION
    Cleans various caches that can affect DCS performance.
    Reads from config-optimizations.json to selectively clean only enabled caches.
.PARAMETER NoPause
    Skip the pause at the end of execution
.NOTES
    Version: 5.4.1
    Run as Administrator for best results
#>

param(
    [switch]$NoPause
)

# Load shared library functions
$rootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$libPath = Join-Path $rootDir "lib\Common.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Host "Warning: Common library not found at $libPath" -ForegroundColor Yellow
}

# Get root directory and load config-optimizations.json and config-global.json
$configPath = Join-Path $rootDir "config-optimizations.json"
$globalConfigPath = Join-Path $rootDir "config-global.json"

# Load global configuration for paths
$globalConfig = Load-ConfigFile -configPath $globalConfigPath -configName "config-global.json"

# Load configuration
$configData = Load-ConfigFile -configPath $configPath -configName "config-optimizations.json"

# Get DCS Saved Games location from config (expand environment variables)
$savedGamesPath = if ($globalConfig.paths -and $globalConfig.paths.savedGamesPath) {
    $path = $globalConfig.paths.savedGamesPath
    # Expand environment variables in the path
    [Environment]::ExpandEnvironmentVariables($path)
} else {
    # Fallback to default location
    "$env:USERPROFILE\Saved Games"
    Write-Host "Warning: savedGamesPath not found in config-global.json, using default: $savedGamesPath" -ForegroundColor Yellow
}

# Helper function for DCS cache cleaning
function Clean-DcsCache {
    param(
        [string]$CacheId,
        [string]$SubFolder,
        [string]$Description
    )
    
    if (Test-OptEnabled $CacheId $configData.cacheOptimizations) {
        $cachePath = Join-Path $savedGamesPath $SubFolder
        if (Test-Path $cachePath) {
            Write-Host "[$CacheId] Cleaning $Description..." -ForegroundColor Green
            Write-Host "       Path: $cachePath" -ForegroundColor Gray
            Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
        } else {
            Write-Host "[$CacheId] DCS $Description folder not found (already clean)" -ForegroundColor Gray
            Write-Host "       Path: $cachePath" -ForegroundColor Gray
        }
    } else {
        Write-Host "[$CacheId] DCS $Description - SKIPPED (disabled)" -ForegroundColor Yellow
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DCS-Max Cache Cleaner v5.4.1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cleanedCount = 0

# C001 - NVIDIA DXCache
if (Test-OptEnabled "C001" $configData.cacheOptimizations) {
    $dxCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\DXCache"
    if (Test-Path $dxCachePath) {
        Write-Host "[C001] Cleaning NVIDIA DXCache..." -ForegroundColor Green
        Write-Host "       Path: $dxCachePath" -ForegroundColor Gray
        Remove-Item -Path $dxCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C001] NVIDIA DXCache not found (already clean)" -ForegroundColor Gray
        Write-Host "       Path: $dxCachePath" -ForegroundColor Gray
    }
} else {
    Write-Host "[C001] NVIDIA DXCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C002 - NVIDIA GLCache
if (Test-OptEnabled "C002" $configData.cacheOptimizations) {
    $glCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\GLCache"
    if (Test-Path $glCachePath) {
        Write-Host "[C002] Cleaning NVIDIA GLCache..." -ForegroundColor Green
        Write-Host "       Path: $glCachePath" -ForegroundColor Gray
        Remove-Item -Path $glCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C002] NVIDIA GLCache not found (already clean)" -ForegroundColor Gray
        Write-Host "       Path: $glCachePath" -ForegroundColor Gray
    }
} else {
    Write-Host "[C002] NVIDIA GLCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C003 - NVIDIA OptixCache
if (Test-OptEnabled "C003" $configData.cacheOptimizations) {
    $optixCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\OptixCache"
    if (Test-Path $optixCachePath) {
        Write-Host "[C003] Cleaning NVIDIA OptixCache..." -ForegroundColor Green
        Write-Host "       Path: $optixCachePath" -ForegroundColor Gray
        Remove-Item -Path $optixCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C003] NVIDIA OptixCache not found (already clean)" -ForegroundColor Gray
        Write-Host "       Path: $optixCachePath" -ForegroundColor Gray
    }
} else {
    Write-Host "[C003] NVIDIA OptixCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C004 - Windows Temp
if (Test-OptEnabled "C004" $configData.cacheOptimizations) {
    Write-Host "[C004] Cleaning Windows Temp files..." -ForegroundColor Green
    $tempPath = $env:TEMP
    Write-Host "       Path: $tempPath" -ForegroundColor Gray
    if (Test-Path $tempPath) {
        Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    }
} else {
    Write-Host "[C004] Windows Temp - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C005 - DCS Temp
Clean-DcsCache -CacheId "C005" -SubFolder "Temp" -Description "Temp"

# C006 - DCS fxo (shader effects)
Clean-DcsCache -CacheId "C006" -SubFolder "fxo" -Description "fxo"

# C007 - DCS metashaders2
Clean-DcsCache -CacheId "C007" -SubFolder "metashaders2" -Description "metashaders2"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cache cleaning completed!" -ForegroundColor Green
Write-Host "Cleaned $cleanedCount cache location(s)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: First DCS launch may take longer as shaders recompile." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if (-not $NoPause) {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
