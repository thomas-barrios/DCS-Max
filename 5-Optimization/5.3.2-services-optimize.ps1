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

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir

# Load config parser and get optimization settings
$configParserPath = Join-Path $rootDirectory "Assets\config-parser.ps1"
if (Test-Path $configParserPath) {
    . $configParserPath
    $optimizationConfig = Get-OptimizationConfig
} else {
    $optimizationConfig = @{}
}

# Helper function to check if optimization is enabled
function Test-OptEnabled {
    param([string]$Id)
    if ($optimizationConfig.Count -eq 0) { return $true }
    if (-not $optimizationConfig.ContainsKey($Id)) { return $true }
    return $optimizationConfig[$Id]
}

$servicesToModify = @(
    # Telemetry & Diagnostics
    @{Id="S001"; Name="DiagTrack"; StartupType="Disabled"; Comment="Telemetry: No impact on gaming, reduces CPU/network"},
    @{Id="S002"; Name="DPS"; StartupType="Disabled"; Comment="Diagnostics: Resource-intensive scanning during gameplay"},
    @{Id="S003"; Name="WdiServiceHost"; StartupType="Disabled"; Comment="Diagnostics: Background tasks cause micro-stutters"},
    @{Id="S004"; Name="WdiSystemHost"; StartupType="Disabled"; Comment="Diagnostics: Unnecessary CPU overhead"},

    # Windows Updates
    @{Id="S005"; Name="UsoSvc"; StartupType="Disabled"; Comment="Updates: Prevents background updates during gameplay"},
    @{Id="S006"; Name="TrustedInstaller"; StartupType="Disabled"; Comment="Updates: Avoids update triggers causing stutters"},
    @{Id="S007"; Name="WaaSMedicSvc"; StartupType="Disabled"; Comment="Updates: Redundant repair service"},

    # Cloud & Microsoft Services
    @{Id="S008"; Name="wlidsvc"; StartupType="Disabled"; Comment="MS Account: Local account used, no cloud sync needed"},
    @{Id="S009"; Name="WalletService"; StartupType="Disabled"; Comment="Wallet: Irrelevant for gaming"},
    @{Id="S010"; Name="XboxGameBar"; StartupType="Disabled"; Comment="Xbox Game Bar: From WindowsSettings section - disable to free CPU/GPU"},
    @{Id="S011"; Name="BackgroundApps"; StartupType="Disabled"; Comment="Background Apps: From WindowsSettings section - globally disable to cut resource spikes"},

    # Printer Services
    @{Id="S012"; Name="Spooler"; StartupType="Disabled"; Comment="Printing: No printing needed during gaming"},
    @{Id="S013"; Name="PrintNotify"; StartupType="Disabled"; Comment="Printing: Unnecessary notifications"},
    @{Id="S014"; Name="PrintWorkflowUserSvc_50b27"; StartupType="Disabled"; Comment="Printing: Workflow not needed"},

    # Fax & Legacy
    @{Id="S015"; Name="Fax"; StartupType="Disabled"; Comment="Fax: Obsolete for gaming"},

    # Search & Indexing
    @{Id="S016"; Name="WSearch"; StartupType="Disabled"; Comment="Search: Heavy disk I/O competes with DCS"},
    @{Id="S017"; Name="Indexing"; StartupType="Disabled"; Comment="Indexing: From WindowsSettings section - disable on game drives to minimize disk I/O"},

    # Media & Entertainment
    @{Id="S018"; Name="MapsBroker"; StartupType="Disabled"; Comment="Maps: Irrelevant for gaming"},
    @{Id="S019"; Name="BcastDVRUserService_50b27"; StartupType="Disabled"; Comment="GameDVR: Causes frame drops in VR"},

    # Hardware Support
    @{Id="S020"; Name="RtkUWPService"; StartupType="Disabled"; Comment="Realtek: Conflicts with gaming audio stack"},
    @{Id="S021"; Name="AmdPmuService"; StartupType="Disabled"; Comment="AMD: DCS uses own optimization"},
    @{Id="S022"; Name="AmdAcpSvc"; StartupType="Disabled"; Comment="AMD: Compatibility database not needed"},
    @{Id="S023"; Name="AmdPPService"; StartupType="Disabled"; Comment="AMD: Manual power settings better for DCS"},

    # Remote Access
    @{Id="S024"; Name="RemoteRegistry"; StartupType="Disabled"; Comment="Remote: Security risk, not needed"},
    @{Id="S025"; Name="TermService"; StartupType="Disabled"; Comment="RDP: Unneeded for local gaming"},

    # Backup & Sync
    @{Id="S026"; Name="fhsvc"; StartupType="Disabled"; Comment="File History: Heavy disk I/O during gameplay"},
    @{Id="S027"; Name="WorkFolders"; StartupType="Disabled"; Comment="Work Folders: Enterprise sync, not needed"},

    # Network Discovery
    @{Id="S028"; Name="SSDPSRV"; StartupType="Disabled"; Comment="Network: Cuts broadcast traffic"},
    @{Id="S029"; Name="UPnPHost"; StartupType="Disabled"; Comment="Network: No UPnP hosting needed"},
    @{Id="S030"; Name="FDResPub"; StartupType="Disabled"; Comment="Network: No device discovery needed"},

    # Location & Sensors
    @{Id="S031"; Name="lfsvc"; StartupType="Disabled"; Comment="Geolocation: Not used, avoids checks"},
    @{Id="S032"; Name="SensorService"; StartupType="Disabled"; Comment="Sensors: No sensors in desktop"},
    @{Id="S033"; Name="SensrSvc"; StartupType="Disabled"; Comment="Sensors: No sensor monitoring needed"},
    @{Id="S034"; Name="SensorDataService"; StartupType="Disabled"; Comment="Sensors: No sensor data needed"},

    # Xbox Services
    @{Id="S035"; Name="XblAuthManager"; StartupType="Disabled"; Comment="Xbox: Not used by DCS"},
    @{Id="S036"; Name="XblGameSave"; StartupType="Disabled"; Comment="Xbox: No cloud saves needed"},
    @{Id="S037"; Name="XboxNetApiSvc"; StartupType="Disabled"; Comment="Xbox: Reduces network overhead"},
    @{Id="S038"; Name="XboxGipSvc"; StartupType="Disabled"; Comment="Xbox: No Xbox accessories used"},

    # Parental Controls
    @{Id="S039"; Name="WPCSvc"; StartupType="Disabled"; Comment="Parental: Not needed for gaming"},

    # Telephony
    @{Id="S040"; Name="PhoneSvc"; StartupType="Disabled"; Comment="Telephony: Desktop without telephony"},
    @{Id="S041"; Name="MessagingService_50b27"; StartupType="Disabled"; Comment="Messaging: Not used in gaming"},

    # Insider Program
    @{Id="S042"; Name="wisvc"; StartupType="Disabled"; Comment="Insider: Not needed for stable rig"},

    # WebDAV
    @{Id="S043"; Name="WebClient"; StartupType="Disabled"; Comment="WebDAV: Avoids reconnects"},

    # Imaging
    @{Id="S044"; Name="stisvc"; StartupType="Disabled"; Comment="WIA: No scanning needed"},

    # Third-Party
    @{Id="S045"; Name="GoogleUpdaterService142.0.7416.0"; StartupType="Disabled"; Comment="Google: Not needed for gaming"},
    @{Id="S046"; Name="GoogleUpdaterInternalService142.0.7416.0"; StartupType="Disabled"; Comment="Google: Not needed for gaming"},
    @{Id="S047"; Name="AsusUpdateCheck"; StartupType="Disabled"; Comment="ASUS: Manual updates sufficient"},

    # File Tracking
    @{Id="S048"; Name="TrkWks"; StartupType="Disabled"; Comment="File Tracking: No benefit for gaming"},

    # Retail Demo
    @{Id="S049"; Name="RetailDemo"; StartupType="Disabled"; Comment="Retail: Consumer feature, not needed"},

    # Client License Service
    @{Id="S050"; Name="ClipSVC"; StartupType="Disabled"; Comment="Client License Service: From WindowsServices section - no Store apps, saves 50-100MB RAM"},

    # Power Management
    @{Id="S051"; Name="Power"; StartupType="Disabled"; Comment="Power: Known to cause VR stutters due to dynamic power state changes"}
)

# Paths
$backupDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$displayDate = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
$backupFile = "$timestamp-services-backup.json"
$backupPath = Join-Path $backupDir $backupFile

# Counters
$disabled = 0
$notFound = 0
$skipped = 0
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

# Count enabled optimizations
$enabledCount = ($servicesToModify | Where-Object { Test-OptEnabled $_.Id }).Count
Write-Host "[INFO]   Processing $enabledCount of $totalServices services for optimization" -ForegroundColor Gray
if ($enabledCount -lt $totalServices) {
    Write-Host "[INFO]   ($($totalServices - $enabledCount) services disabled in config)" -ForegroundColor DarkGray
}
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
    # Check if this optimization is enabled in config
    if (-not (Test-OptEnabled $service.Id)) {
        Write-Host "[SKIP]   $($service.Name) (disabled in config)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

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
Write-Host "[SKIP]   Disabled in config: $skipped" -ForegroundColor DarkGray
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