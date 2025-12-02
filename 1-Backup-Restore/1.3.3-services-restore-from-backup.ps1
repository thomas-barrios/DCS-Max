# Windows Services Restore Script for DCS-Max
# Purpose: Restore Windows services from a specific backup file
# Author: DCS-Max Suite
# Date: December 1, 2025
# Usage: .\1.3.3-services-restore-from-backup.ps1 -BackupFile "path\to\backup.json"

param(
    [Parameter(Mandatory=$false)]
    [string]$BackupFile,
    [switch]$NoPause = $false
)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -BackupFile `"$BackupFile`" -NoPause:`$$NoPause" -Verb RunAs
    exit 
}

# Set execution policy when running interactively
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
$backupsDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

# Find backup file
if ($BackupFile) {
    # Check if it's a full path or relative
    if ([System.IO.Path]::IsPathRooted($BackupFile)) {
        $backupPath = $BackupFile
    } else {
        # Try relative to root directory first
        $backupPath = Join-Path $rootDirectory $BackupFile
        if (-not (Test-Path $backupPath)) {
            # Try relative to backups directory
            $backupPath = Join-Path $backupsDir $BackupFile
        }
        if (-not (Test-Path $backupPath)) {
            # Try as-is
            $backupPath = $BackupFile
        }
    }
    
    if (-not (Test-Path $backupPath)) {
        Write-Host ""
        Write-Host "[RESTORE] Windows Services Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   Backup file not found: $BackupFile" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        exit 1
    }
} else {
    # Find latest backup
    $backupPath = Get-ChildItem "$backupsDir\*services-backup.json" -ErrorAction SilentlyContinue | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1
    
    if (-not $backupPath) {
        Write-Host ""
        Write-Host "[RESTORE] Windows Services Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   No services backup found in Backups folder" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        exit 1
    }
    $backupPath = $backupPath.FullName
}

# Header
Write-Host ""
Write-Host "Starting restore..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[RESTORE] DCS-Max: Windows Services Restore" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Restore Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "[FILE]   Restoring from: $backupPath" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Load backup
try {
    $backupJson = Get-Content $backupPath -Raw | ConvertFrom-Json
    # Handle nested structure - services are in .Services property
    if ($backupJson.Services) {
        $backupData = $backupJson.Services
    } else {
        $backupData = $backupJson
    }
    Write-Host ""
    Write-Host "[OK]     Loaded backup with $($backupData.Count) services" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "[FAIL]   Cannot read backup file: $_" -ForegroundColor Red
    if (-not $NoPause) { Pause }
    exit 1
}

# Restore services
$restored = 0
$failed = 0
$skipped = 0
$protectedSkipped = 0

# Per-user services have a suffix like _3ab36a0 - these cannot be configured directly
# They inherit settings from their template service
$perUserServicePattern = '_[a-f0-9]{5,}$'

# Critical Windows services that are protected and cannot be modified even as admin
$protectedServices = @(
    'DcomLaunch', 'RpcSs', 'RpcEptMapper', 'LSM', 'BrokerInfrastructure',
    'CoreMessagingRegistrar', 'gpsvc', 'Schedule', 'SystemEventsBroker',
    'TimeBrokerSvc', 'TextInputManagementService', 'StateRepository',
    'WinDefend', 'WdNisSvc', 'mpssvc', 'wscsvc', 'SecurityHealthService',
    'MDCoreSvc', 'Sense', 'BFE', 'Dnscache', 'DoSvc', 'WinHttpAutoProxySvc',
    'sppsvc', 'msiserver', 'WaaSMedicSvc', 'AppIDSvc', 'AppXSvc', 'ClipSVC',
    'NgcSvc', 'NgcCtnrSvc', 'EntAppSvc', 'embeddedmode'
)

Write-Host "[RESTORE] Restoring services..." -ForegroundColor Yellow
Write-Host ""

foreach ($service in $backupData) {
    $serviceName = $service.Name
    $targetStartType = $service.StartType
    
    if (-not $serviceName) {
        continue
    }
    
    # Skip per-user services (they have a hex suffix and can't be configured directly)
    if ($serviceName -match $perUserServicePattern) {
        $protectedSkipped++
        continue
    }
    
    # Skip known protected Windows core services
    if ($protectedServices -contains $serviceName) {
        $protectedSkipped++
        continue
    }
    
    # Get current service
    $currentService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if (-not $currentService) {
        Write-Host "[SKIP]   $serviceName (not found)" -ForegroundColor DarkGray
        $skipped++
        continue
    }
    
    try {
        # Convert start type - can be string or number (0=Boot, 1=System, 2=Automatic, 3=Manual, 4=Disabled)
        $startType = switch ($targetStartType) {
            0 { "Boot" }
            1 { "System" }
            2 { "Automatic" }
            3 { "Manual" }
            4 { "Disabled" }
            "Automatic" { "Automatic" }
            "Boot" { "Boot" }
            "Disabled" { "Disabled" }
            "Manual" { "Manual" }
            "System" { "System" }
            default { "Manual" }
        }
        
        Set-Service -Name $serviceName -StartupType $startType -ErrorAction Stop
        Write-Host "[OK]     $serviceName -> $startType" -ForegroundColor Green
        $restored++
    } catch {
        Write-Host "[FAIL]   $serviceName - $_" -ForegroundColor Red
        $failed++
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Restore Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Restored: $restored" -ForegroundColor Green
Write-Host "[SKIP]   Not found: $skipped" -ForegroundColor DarkGray
Write-Host "[SKIP]   Protected (Windows core/per-user): $protectedSkipped" -ForegroundColor DarkGray
Write-Host "[FAIL]   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host ""
Write-Host "[INFO]   $protectedSkipped protected services were skipped. This is normal - Windows" -ForegroundColor Gray
Write-Host "         protects critical system services from modification." -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Services restore completed!" -ForegroundColor Green
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[SUCCESS] Restore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Restore completed with $failed errors" -ForegroundColor Yellow
}
Write-Host ""

if (-not $NoPause) { Pause }
