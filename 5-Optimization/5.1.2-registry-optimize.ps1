# Registry Optimization Script for DCS-Max
# Purpose: Apply registry optimizations for gaming performance with detailed output
# Author: DCS-Max Suite
# Date: December 1, 2025
# Optional: -NoPause to skip the pause at end (for automation/UI)

param([switch]$NoPause = $false)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -NoPause:`$$NoPause" -Verb RunAs
    exit 
}

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$regFile = Join-Path $scriptDir "5.1.2-registry-optimize.reg"
$backupDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$displayDate = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'

# Counters
$optimized = 0
$failed = 0

# Ensure Backups directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Registry optimizations to apply (matches the .reg file)
$registryOptimizations = @(
    @{
        Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
        Name = "Attributes"
        Value = 0
        Type = "DWord"
        Description = "CPU Core Parking"
        DisplayValue = "Disabled (unpark all cores)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DCS.exe"
        Name = "CpuPriorityClass"
        Value = 3
        Type = "DWord"
        Description = "DCS CPU Priority"
        DisplayValue = "High (3)"
    },
    @{
        Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
        Name = "PowerThrottlingOff"
        Value = 1
        Type = "DWord"
        Description = "Power Throttling"
        DisplayValue = "Disabled"
    },
    @{
        Key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        Name = "AppCaptureEnabled"
        Value = 0
        Type = "DWord"
        Description = "GameDVR Recording"
        DisplayValue = "Disabled"
    },
    @{
        Key = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Direct3D"
        Name = "MaxPreRenderedFrames"
        Value = 1
        Type = "DWord"
        Description = "Max Pre-Rendered Frames"
        DisplayValue = "1 (minimum latency)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Name = "NetworkThrottlingIndex"
        Value = 0xffffffff
        Type = "DWord"
        Description = "Network Throttling"
        DisplayValue = "Disabled (0xFFFFFFFF)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Name = "SystemResponsiveness"
        Value = 10
        Type = "DWord"
        Description = "System Responsiveness"
        DisplayValue = "10% (more CPU for games)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "Affinity"
        Value = 0x0000000f
        Type = "DWord"
        Description = "Game CPU Affinity"
        DisplayValue = "First 4 cores (0x0F)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "BackgroundOnly"
        Value = 0
        Type = "DWord"
        Description = "Background Only"
        DisplayValue = "Disabled"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "GPU Priority"
        Value = 14
        Type = "DWord"
        Description = "GPU Priority"
        DisplayValue = "14 (high)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "Priority"
        Value = 6
        Type = "DWord"
        Description = "CPU Priority"
        DisplayValue = "6 (highest)"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "Scheduling Category"
        Value = "High"
        Type = "String"
        Description = "Scheduling Category"
        DisplayValue = "High"
    },
    @{
        Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Name = "SFIO Priority"
        Value = "High"
        Type = "String"
        Description = "SFIO Priority"
        DisplayValue = "High"
    },
    @{
        Key = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        Name = "Win32PrioritySeparation"
        Value = 0x1a
        Type = "DWord"
        Description = "Priority Separation"
        DisplayValue = "26 (Long Fixed, foreground boost)"
    }
)

# Header
Write-Host ""
Write-Host "Starting optimization..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[OPTIMIZE] DCS-Max: Registry Optimization" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Optimization Date: $displayDate" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   Applying $($registryOptimizations.Count) registry optimizations" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Create backup first
Write-Host ""
Write-Host "[BACKUP] Creating registry backup..." -ForegroundColor Yellow
Write-Host ""

$backupScript = Join-Path $rootDirectory "1-Backup-Restore\1.1.1-registry-backup.ps1"
if (Test-Path $backupScript) {
    try {
        & $backupScript -NoPause
        Write-Host ""
        Write-Host "[OK]     Backup created successfully" -ForegroundColor Green
    } catch {
        Write-Host "[WARN]   Backup failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARN]   Backup script not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[OPTIMIZE] Applying registry optimizations..." -ForegroundColor Yellow
Write-Host ""

# Apply each optimization
foreach ($opt in $registryOptimizations) {
    try {
        # Ensure key exists
        if (-not (Test-Path $opt.Key)) {
            New-Item -Path $opt.Key -Force | Out-Null
        }
        
        # Set the value
        if ($opt.Type -eq "String") {
            Set-ItemProperty -Path $opt.Key -Name $opt.Name -Value $opt.Value -Type String -Force
        } else {
            Set-ItemProperty -Path $opt.Key -Name $opt.Name -Value $opt.Value -Type DWord -Force
        }
        
        Write-Host "[OK]     $($opt.Description) -> $($opt.DisplayValue)" -ForegroundColor Green
        $optimized++
    } catch {
        $errMsg = "$_".Trim()
        Write-Host "[FAIL]   $($opt.Description) - $errMsg" -ForegroundColor Red
        $failed++
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Optimization Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Optimized: $optimized" -ForegroundColor Green
Write-Host "[FAIL]   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host ""
Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   To restore, run:" -ForegroundColor Gray
Write-Host "         .\1-Backup-Restore\1.1.3-registry-restore.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Registry optimization completed!" -ForegroundColor Green
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[SUCCESS] Optimization completed successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Optimization completed with $failed errors" -ForegroundColor Yellow
}
Write-Host ""

if (-not $NoPause) { Pause }
