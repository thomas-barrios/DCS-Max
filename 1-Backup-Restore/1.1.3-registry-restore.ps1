# Registry Restore Script for DCS-Max
# Restores registry values from a backup .reg file
# Optional: -RegFile to specify the backup file
# Optional: -NoPause to skip the pause at end (for automation/UI)

param(
    [string]$RegFile,
    [switch]$NoPause = $false
)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -RegFile `"$RegFile`" -NoPause:`$$NoPause" -Verb RunAs; exit }

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupsDirectory = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

# Find backup file
if ($RegFile) {
    if (Test-Path $RegFile) {
        $backupPath = Get-Item $RegFile
    } elseif (Test-Path (Join-Path $backupsDirectory $RegFile)) {
        $backupPath = Get-Item (Join-Path $backupsDirectory $RegFile)
    } elseif (Test-Path (Join-Path $rootDirectory $RegFile)) {
        $backupPath = Get-Item (Join-Path $rootDirectory $RegFile)
    } else {
        Write-Host ""
        Write-Host "[RESTORE] Registry Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   Backup file not found: $RegFile" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        exit 1
    }
} else {
    $backupPath = Get-ChildItem "$backupsDirectory\*registry-backup.reg" -ErrorAction SilentlyContinue | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1
    if (-not $backupPath) {
        Write-Host ""
        Write-Host "[RESTORE] Registry Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   No registry backup found in Backups folder" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        exit 1
    }
}

# Header
Write-Host ""
Write-Host "Starting restore..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[RESTORE] DCS-Max: Registry Restore" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Restore Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "[FILE]   Restoring from: $($backupPath.FullName)" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Parse the .reg file to show what will be restored
$regContent = Get-Content $backupPath.FullName -Raw
$restored = 0
$currentKey = ""

Write-Host ""
Write-Host "[RESTORE] Restoring registry values..." -ForegroundColor Yellow
Write-Host ""

# Parse and display registry entries
$lines = Get-Content $backupPath.FullName
foreach ($line in $lines) {
    # Skip empty lines and header
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match "^Windows Registry Editor") {
        continue
    }
    
    # Registry key (in square brackets)
    if ($line -match '^\[(.+)\]$') {
        $currentKey = $Matches[1]
        # Shorten the key for display
        $shortKey = $currentKey -replace "HKEY_LOCAL_MACHINE", "HKLM" -replace "HKEY_CURRENT_USER", "HKCU"
        continue
    }
    
    # Registry value (name=value)
    if ($line -match '^"(.+)"=(.+)$') {
        $valueName = $Matches[1]
        $valueData = $Matches[2]
        
        # Clean up display
        if ($valueData -match '^dword:(.+)$') {
            $displayValue = "0x$($Matches[1])"
        } elseif ($valueData -match '^"(.+)"$') {
            $displayValue = $Matches[1]
        } else {
            $displayValue = $valueData
        }
        
        Write-Host "[OK]     $valueName = $displayValue" -ForegroundColor Green
        $restored++
    }
}

Write-Host "------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[INFO]   Importing registry file..." -ForegroundColor Gray

# Import the registry file
try {
    $regPath = $backupPath.FullName
    $process = Start-Process -FilePath "reg.exe" -ArgumentList "import", "`"$regPath`"" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[SUMMARY] Restore Summary:" -ForegroundColor Cyan
        Write-Host "[OK]     Restored: $restored registry values" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
        Write-Host ""
        Write-Host "[OK]     Registry restore completed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "[SUCCESS] Restore completed successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   Registry import failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        Write-Host ""
        Write-Host "[WARN] Restore failed!" -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host "[FAIL]   Error importing registry: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "[WARN] Restore failed!" -ForegroundColor Red
}

Write-Host ""
if (-not $NoPause) { Pause }
