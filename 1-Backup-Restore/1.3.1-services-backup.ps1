# Windows Services Backup Script for DCS-Max
# Purpose: Create comprehensive backup of all Windows services states before optimization
# Author: DCS-Max Suite
# Date: November 12, 2025
# Usage: Run before applying service optimizations
# Optional: -ServicesToBackup @("service1", "service2") to backup only specific services
# Optional: -NoPause to skip the pause at end (for automation/UI)

param(
    [string[]]$ServicesToBackup,
    [switch]$NoPause = $false
)

# Set execution policy only when running interactively (not from UI)
if (-not $NoPause) {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
    } catch {
        # Ignore - policy may already be set or overridden by group policy
    }
}

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$backupFile = Join-Path $backupDir "$timestamp-services-backup.json"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "[FOLDER] Created backup directory: $backupDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting backup..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[BACKUP] DCS-Max: Windows Services Backup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Backup Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "[FILE]   Saving to: $backupFile" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[BACKUP] Scanning Windows services..." -ForegroundColor Yellow
Write-Host ""

try {
    $allServicesQuery = Get-Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, StartType, Status
    if ($ServicesToBackup) {
        $allServices = $allServicesQuery | Where-Object { $_.Name -in $ServicesToBackup }
        Write-Host "[INFO]   Filtering to $($ServicesToBackup.Count) specified services" -ForegroundColor Gray
    } else {
        $allServices = $allServicesQuery
    }
    
    # List each service being backed up
    foreach ($svc in $allServices) {
        Write-Host "[OK]     $($svc.Name) ($($svc.StartType))" -ForegroundColor Green
    }
    
    # Create backup object
    $backupData = @{
        BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        TotalServices = $allServices.Count
        Services = $allServices
    }
    
    # Export to JSON
    $backupData | ConvertTo-Json -Depth 3 | Out-File -FilePath $backupFile -Encoding UTF8
    
} catch {
    Write-Host "[FAIL]   Failed to backup services: $_" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Backup Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Services backed up: $($allServices.Count)" -ForegroundColor Green
Write-Host ""
Write-Host "[INFO]   To restore, run:" -ForegroundColor Gray
Write-Host "         .\1.3.3-services-restore-from-backup.ps1 -BackupFile `"$(Split-Path $backupFile -Leaf)`"" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Windows services backup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "[SUCCESS] Backup completed successfully!" -ForegroundColor Green
Write-Host ""

if (-not $NoPause) { Pause }
