#requires -RunAsAdministrator

# PowerShell Script to Optimize Windows 11 Services for DCS World (VR + Joysticks)
# Purpose: Minimize frame times, eliminate stutters, ensure stability for competitive gaming
# Notes: Run as Administrator. Reversible via 1.3.3-services-restore-from-backup.ps1
# Optional: -NoPause to skip the pause at end (for automation/UI)

param([switch]$NoPause = $false)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Set execution policy
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
} catch {
    # Ignore - policy may already be set
}


$servicesToModify = @(
    # Telemetry & Diagnostics
    @{Name="DiagTrack"; StartupType="Disabled"; Comment="Telemetry: No impact on gaming, reduces CPU/network"},
    @{Name="DPS"; StartupType="Disabled"; Comment="Diagnostics: Resource-intensive scanning during gameplay"},
    @{Name="WdiServiceHost"; StartupType="Disabled"; Comment="Diagnostics: Background tasks cause micro-stutters"},
    @{Name="WdiSystemHost"; StartupType="Disabled"; Comment="Diagnostics: Unnecessary CPU overhead"},

    # Windows Updates
    @{Name="UsoSvc"; StartupType="Disabled"; Comment="Updates: Prevents background updates during gameplay"},
    @{Name="TrustedInstaller"; StartupType="Disabled"; Comment="Updates: Avoids update triggers causing stutters"},
    @{Name="WaaSMedicSvc"; StartupType="Disabled"; Comment="Updates: Redundant repair service"},

    # Cloud & Microsoft Services
    @{Name="wlidsvc"; StartupType="Disabled"; Comment="MS Account: Local account used, no cloud sync needed"},
    @{Name="WalletService"; StartupType="Disabled"; Comment="Wallet: Irrelevant for gaming"},
    @{Name="XboxGameBar"; StartupType="Disabled"; Comment="Xbox Game Bar: From WindowsSettings section - disable to free CPU/GPU"},
    @{Name="BackgroundApps"; StartupType="Disabled"; Comment="Background Apps: From WindowsSettings section - globally disable to cut resource spikes"},

    # Printer Services
    @{Name="Spooler"; StartupType="Disabled"; Comment="Printing: No printing needed during gaming"},
    @{Name="PrintNotify"; StartupType="Disabled"; Comment="Printing: Unnecessary notifications"},
    @{Name="PrintWorkflowUserSvc_50b27"; StartupType="Disabled"; Comment="Printing: Workflow not needed"},

    # Fax & Legacy
    @{Name="Fax"; StartupType="Disabled"; Comment="Fax: Obsolete for gaming"},

    # Search & Indexing
    @{Name="WSearch"; StartupType="Disabled"; Comment="Search: Heavy disk I/O competes with DCS"},
    @{Name="Indexing"; StartupType="Disabled"; Comment="Indexing: From WindowsSettings section - disable on game drives to minimize disk I/O"},

    # Media & Entertainment
    @{Name="MapsBroker"; StartupType="Disabled"; Comment="Maps: Irrelevant for gaming"},
    @{Name="BcastDVRUserService_50b27"; StartupType="Disabled"; Comment="GameDVR: Causes frame drops in VR"},

    # Hardware Support
    @{Name="RtkUWPService"; StartupType="Disabled"; Comment="Realtek: Conflicts with gaming audio stack"},
    @{Name="AmdPmuService"; StartupType="Disabled"; Comment="AMD: DCS uses own optimization"},
    @{Name="AmdAcpSvc"; StartupType="Disabled"; Comment="AMD: Compatibility database not needed"},
    @{Name="AmdPPService"; StartupType="Disabled"; Comment="AMD: Manual power settings better for DCS"},

    # Remote Access
    @{Name="RemoteRegistry"; StartupType="Disabled"; Comment="Remote: Security risk, not needed"},
    @{Name="TermService"; StartupType="Disabled"; Comment="RDP: Unneeded for local gaming"},

    # Backup & Sync
    @{Name="fhsvc"; StartupType="Disabled"; Comment="File History: Heavy disk I/O during gameplay"},
    @{Name="WorkFolders"; StartupType="Disabled"; Comment="Work Folders: Enterprise sync, not needed"},

    # Network Discovery
    @{Name="SSDPSRV"; StartupType="Disabled"; Comment="Network: Cuts broadcast traffic"},
    @{Name="UPnPHost"; StartupType="Disabled"; Comment="Network: No UPnP hosting needed"},
    @{Name="FDResPub"; StartupType="Disabled"; Comment="Network: No device discovery needed"},

    # Location & Sensors
    @{Name="lfsvc"; StartupType="Disabled"; Comment="Geolocation: Not used, avoids checks"},
    @{Name="SensorService"; StartupType="Disabled"; Comment="Sensors: No sensors in desktop"},
    @{Name="SensrSvc"; StartupType="Disabled"; Comment="Sensors: No sensor monitoring needed"},
    @{Name="SensorDataService"; StartupType="Disabled"; Comment="Sensors: No sensor data needed"},

    # Xbox Services
    @{Name="XblAuthManager"; StartupType="Disabled"; Comment="Xbox: Not used by DCS"},
    @{Name="XblGameSave"; StartupType="Disabled"; Comment="Xbox: No cloud saves needed"},
    @{Name="XboxNetApiSvc"; StartupType="Disabled"; Comment="Xbox: Reduces network overhead"},
    @{Name="XboxGipSvc"; StartupType="Disabled"; Comment="Xbox: No Xbox accessories used"},

    # Parental Controls
    @{Name="WPCSvc"; StartupType="Disabled"; Comment="Parental: Not needed for gaming"},

    # Telephony
    @{Name="PhoneSvc"; StartupType="Disabled"; Comment="Telephony: Desktop without telephony"},
    @{Name="MessagingService_50b27"; StartupType="Disabled"; Comment="Messaging: Not used in gaming"},

    # Insider Program
    @{Name="wisvc"; StartupType="Disabled"; Comment="Insider: Not needed for stable rig"},

    # WebDAV
    @{Name="WebClient"; StartupType="Disabled"; Comment="WebDAV: Avoids reconnects"},

    # Imaging
    @{Name="stisvc"; StartupType="Disabled"; Comment="WIA: No scanning needed"},

    # Third-Party
    @{Name="GoogleUpdaterService142.0.7416.0"; StartupType="Disabled"; Comment="Google: Not needed for gaming"},
    @{Name="GoogleUpdaterInternalService142.0.7416.0"; StartupType="Disabled"; Comment="Google: Not needed for gaming"},
    @{Name="AsusUpdateCheck"; StartupType="Disabled"; Comment="ASUS: Manual updates sufficient"},

    # File Tracking
    @{Name="TrkWks"; StartupType="Disabled"; Comment="File Tracking: No benefit for gaming"},

    # Retail Demo
    @{Name="RetailDemo"; StartupType="Disabled"; Comment="Retail: Consumer feature, not needed"},

    # Client License Service
    @{Name="ClipSVC"; StartupType="Disabled"; Comment="Client License Service: From WindowsServices section - no Store apps, saves 50-100MB RAM"},

    # Power Management
    @{Name="Power"; StartupType="Disabled"; Comment="Power: Known to cause VR stutters due to dynamic power state changes"}
)

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$displayDate = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
$backupFile = "$timestamp-services-backup.json"
$backupPath = Join-Path $backupDir $backupFile

# Counters
$disabled = 0
$notFound = 0
$failed = 0
$totalServices = $servicesToModify.Count

# Ensure Backups directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Header
Write-Host ""
Write-Host "Starting optimization..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[OPTIMIZE] DCS-Max: Windows Services Optimization" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Optimization Date: $displayDate" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   Processing $totalServices services for optimization" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Create backup before optimization
Write-Host ""
Write-Host "[BACKUP] Creating backup before optimization..." -ForegroundColor Yellow
Write-Host ""

$backupScript = Join-Path $rootDirectory "1-Backup-Restore\1.3.1-services-backup.ps1"
$servicesToBackup = $servicesToModify | ForEach-Object { $_.Name }
if (Test-Path $backupScript) {
    try {
        & $backupScript -ServicesToBackup $servicesToBackup -NoPause
        Write-Host ""
        Write-Host "[OK]     Backup created successfully" -ForegroundColor Green
    } catch {
        Write-Host "[WARN]   Backup failed: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARN]   Backup script not found at: $backupScript" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[OPTIMIZE] Disabling services..." -ForegroundColor Yellow
Write-Host ""

foreach ($service in $servicesToModify) {
    $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
    if ($svc) {
        try {
            Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction Stop
            if ($svc.Status -eq "Running") {
                Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
            }
            Write-Host "[OK]     $($service.Name) -> $($service.StartupType)" -ForegroundColor Green
            $disabled++
        } catch {
            $errMsg = "$_".Trim()
            Write-Host "[FAIL]   $($service.Name) - $errMsg" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "[SKIP]   $($service.Name) (not found)" -ForegroundColor DarkGray
        $notFound++
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Optimization Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Disabled: $disabled" -ForegroundColor Green
Write-Host "[SKIP]   Not found: $notFound" -ForegroundColor DarkGray
Write-Host "[FAIL]   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host ""
Write-Host "[INFO]   $notFound services were not found on this system." -ForegroundColor Gray
Write-Host "         This is normal - not all services exist on every Windows installation." -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   To restore, run:" -ForegroundColor Gray
Write-Host "         .\1-Backup-Restore\1.3.3-services-restore-from-backup.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Windows services optimization completed!" -ForegroundColor Green
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[SUCCESS] Optimization completed successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Optimization completed with $failed errors" -ForegroundColor Yellow
}
Write-Host ""

if (-not $NoPause) { Pause }