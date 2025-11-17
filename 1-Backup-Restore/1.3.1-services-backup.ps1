# Windows Services Backup Script for DCS-Max
# Purpose: Create comprehensive backup of all Windows services states before optimization
# Author: DCS-Max Suite
# Date: November 12, 2025
# Usage: Run before applying service optimizations
# Optional: -ServicesToBackup @("service1", "service2") to backup only specific services

param([string[]]$ServicesToBackup)

# Set execution policy to allow script to run
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "[OK] Execution policy set to RemoteSigned for current user" -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Failed to set execution policy: $_"
    exit 1
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

Write-Host "[BACKUP] DCS-Max: Windows Services Backup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "[DATE] Backup Date: $(Get-Date)" -ForegroundColor White
Write-Host "[FILE] Backup Location: $backupFile" -ForegroundColor White
Write-Host ""

# Get all services and their current states
Write-Host "[SCAN] Scanning all Windows services..." -ForegroundColor Yellow

try {
    $allServicesQuery = Get-Service -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, StartType, Status
    if ($ServicesToBackup) {
        $allServices = $allServicesQuery | Where-Object { $_.Name -in $ServicesToBackup }
        Write-Host "[FILTER] Backing up only specified services: $($ServicesToBackup -join ', ')" -ForegroundColor Yellow
    } else {
        $allServices = $allServicesQuery
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
    
    Write-Host "[OK] Successfully backed up $($allServices.Count) services" -ForegroundColor Green
    Write-Host "[SAVE] Backup saved to: $backupFile" -ForegroundColor Green
    
} catch {
    Write-Error "[ERROR] Failed to backup services: $_"
    exit 1
}

# Summary
Write-Host ""
Write-Host "[SUMMARY] Backup Summary:" -ForegroundColor Cyan
Write-Host "   [SAVE] Services backed up: $($allServices.Count)" -ForegroundColor White
Write-Host "   [FILE] Backup file: $(Split-Path $backupFile -Leaf)" -ForegroundColor White
Write-Host ""
Write-Host "[NEXT] Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Run 5-Optimization\5.3.2-services-optimize.ps1 to apply optimizations" -ForegroundColor White
Write-Host "   2. Test DCS performance with optimizations" -ForegroundColor White
Write-Host "   3. If needed, run 1-Backup-restore\1.3.2-services-restore.ps1 to restore" -ForegroundColor White
Write-Host ""
Write-Host "[OK] Windows Services backup completed successfully!" -ForegroundColor Green
Pause
