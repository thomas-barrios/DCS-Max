#Requires -RunAsAdministrator
<#
.SYNOPSIS
    DCS-Max Cache Cleaning Script
.DESCRIPTION
    Cleans various caches that can affect DCS performance.
    Reads from performance-optimizations.ini to selectively clean only enabled caches.
.PARAMETER NoPause
    Skip the pause at the end of execution
.NOTES
    Version: 5.4.1
    Run as Administrator for best results
#>

param(
    [switch]$NoPause
)

# Import shared config parser
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configParserPath = Join-Path (Split-Path -Parent $scriptDir) "Assets\config-parser.ps1"
if (Test-Path $configParserPath) {
    . $configParserPath
} else {
    Write-Host "Warning: Config parser not found at $configParserPath" -ForegroundColor Yellow
    Write-Host "All cache cleaning options will be enabled by default." -ForegroundColor Yellow
}

# Get optimization config
$configPath = Join-Path $scriptDir "performance-optimizations.ini"
$config = @{}
if (Get-Command Get-OptimizationConfig -ErrorAction SilentlyContinue) {
    $config = Get-OptimizationConfig -ConfigPath $configPath
}

# Helper function to check if optimization is enabled
function Test-OptEnabled {
    param([string]$Id)
    if ($config.Count -eq 0) { return $true }  # Default to enabled if no config
    if (-not $config.ContainsKey($Id)) { return $true }  # Default to enabled if not in config
    return $config[$Id]
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DCS-Max Cache Cleaner v5.4.1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$cleanedCount = 0

# C001 - NVIDIA DXCache
if (Test-OptEnabled "C001") {
    $dxCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\DXCache"
    if (Test-Path $dxCachePath) {
        Write-Host "[C001] Cleaning NVIDIA DXCache..." -ForegroundColor Green
        Remove-Item -Path $dxCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C001] NVIDIA DXCache not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C001] NVIDIA DXCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C002 - NVIDIA GLCache
if (Test-OptEnabled "C002") {
    $glCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\GLCache"
    if (Test-Path $glCachePath) {
        Write-Host "[C002] Cleaning NVIDIA GLCache..." -ForegroundColor Green
        Remove-Item -Path $glCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C002] NVIDIA GLCache not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C002] NVIDIA GLCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C003 - NVIDIA OptixCache
if (Test-OptEnabled "C003") {
    $optixCachePath = Join-Path $env:LOCALAPPDATA "NVIDIA\OptixCache"
    if (Test-Path $optixCachePath) {
        Write-Host "[C003] Cleaning NVIDIA OptixCache..." -ForegroundColor Green
        Remove-Item -Path $optixCachePath -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    } else {
        Write-Host "[C003] NVIDIA OptixCache not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C003] NVIDIA OptixCache - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C004 - Windows Temp
if (Test-OptEnabled "C004") {
    Write-Host "[C004] Cleaning Windows Temp files..." -ForegroundColor Green
    $tempPath = $env:TEMP
    if (Test-Path $tempPath) {
        Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $cleanedCount++
    }
} else {
    Write-Host "[C004] Windows Temp - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C005 - DCS Temp
if (Test-OptEnabled "C005") {
    $dcsVersions = @("DCS", "DCS.openbeta")
    $foundAny = $false
    foreach ($ver in $dcsVersions) {
        $dcsTempPath = Join-Path $env:USERPROFILE "Saved Games\$ver\Temp"
        if (Test-Path $dcsTempPath) {
            Write-Host "[C005] Cleaning $ver Temp folder..." -ForegroundColor Green
            Remove-Item -Path $dcsTempPath -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
            $foundAny = $true
        }
    }
    if (-not $foundAny) {
        Write-Host "[C005] DCS Temp folders not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C005] DCS Temp - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C006 - DCS fxo (shader effects)
if (Test-OptEnabled "C006") {
    $dcsVersions = @("DCS", "DCS.openbeta")
    $foundAny = $false
    foreach ($ver in $dcsVersions) {
        $fxoPath = Join-Path $env:USERPROFILE "Saved Games\$ver\fxo"
        if (Test-Path $fxoPath) {
            Write-Host "[C006] Cleaning $ver fxo folder..." -ForegroundColor Green
            Remove-Item -Path $fxoPath -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
            $foundAny = $true
        }
    }
    if (-not $foundAny) {
        Write-Host "[C006] DCS fxo folders not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C006] DCS fxo - SKIPPED (disabled)" -ForegroundColor Yellow
}

# C007 - DCS metashaders2
if (Test-OptEnabled "C007") {
    $dcsVersions = @("DCS", "DCS.openbeta")
    $foundAny = $false
    foreach ($ver in $dcsVersions) {
        $metashadersPath = Join-Path $env:USERPROFILE "Saved Games\$ver\metashaders2"
        if (Test-Path $metashadersPath) {
            Write-Host "[C007] Cleaning $ver metashaders2 folder..." -ForegroundColor Green
            Remove-Item -Path $metashadersPath -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedCount++
            $foundAny = $true
        }
    }
    if (-not $foundAny) {
        Write-Host "[C007] DCS metashaders2 folders not found (already clean)" -ForegroundColor Gray
    }
} else {
    Write-Host "[C007] DCS metashaders2 - SKIPPED (disabled)" -ForegroundColor Yellow
}

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
