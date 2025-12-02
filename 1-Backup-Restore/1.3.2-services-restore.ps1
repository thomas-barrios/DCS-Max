#requires -RunAsAdministrator

# PowerShell Script to Optimize Windows 11 Services for DCS World (VR + Joysticks)
# Purpose: Minimize frame times, eliminate stutters, ensure stability for competitive gaming
# Date: October 19, 2025
# Notes: Run as Administrator. Reversible via Restore-Services function.
#
# This script disables the selected services.
# and writes a Restore-Services.ps1 file to restore changes

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Set execution policy when running interactively
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
} catch {
    # Ignore - policy may already be set or overridden by group policy
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

# Create backup before optimization
Write-Host "Creating services backup before optimization..." -ForegroundColor Yellow
$backupScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "1.3.1-services-backup.ps1"
$servicesToBackup = $servicesToModify | ForEach-Object { $_.Name }
if (Test-Path $backupScript) {
    try {
        & $backupScript -ServicesToBackup $servicesToBackup
        Write-Host "Backup completed successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Backup script failed: $_"
    }
} else {
    Write-Warning "Backup script not found: $backupScript"
}
Write-Host ""

# Store original service states for reversibility
$serviceStates = @{}

# Function to Optimize Services
function Optimize-Services {
    Write-Host "Optimizing services for DCS World performance..." -ForegroundColor Green
    
    foreach ($service in $servicesToModify) {
        $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
        if ($svc) {
            # Store original state
            $serviceStates[$service.Name] = @{
                StartupType = (Get-WmiObject -Class Win32_Service -Filter "Name='$($service.Name)'").StartMode
                State = $svc.Status
            }
            
            # Set new startup type
            Write-Host "Disabling $($service.Name): $($service.Comment)"
            try {
                Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction Stop
                if ($svc.Status -eq "Running") {
                    Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Failed to modify $($service.Name): $_"
            }
        } else {
            Write-Warning "Service $($service.Name) not found"
        }
    }
    
    Write-Host "Service optimization complete!" -ForegroundColor Green
}

# Function to Restore Original Service States
function Restore-Services {
    Write-Host "Restoring original service states..." -ForegroundColor Yellow
    
    # Define backup directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDirectory = Split-Path -Parent $scriptDir
    $backupDir = Join-Path $rootDirectory "Backups"

    # Ensure Backups directory exists
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    # Search for backup file in Backups directory
    $backupPath = Get-ChildItem "$backupDir\*services-backup.json" | Sort LastWriteTime -Descending | Select -First 1
    if (-not $backupPath) {
        Write-Host "ERROR: No backup file found in $backupDir! Run backup first." -ForegroundColor Red
        return
    }
    
    foreach ($serviceName in $serviceStates.Keys) {
        $original = $serviceStates[$serviceName]
        $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "Restoring $serviceName to $($original.StartupType)"
            try {
                Set-Service -Name $serviceName -StartupType $original.StartupType -ErrorAction Stop
                if ($original.State -eq "Running" -and $svc.Status -ne "Running") {
                    Start-Service -Name $serviceName -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Failed to restore $serviceName - $_"
            }
        }
    }
    
    Write-Host "Service restoration complete!" -ForegroundColor Yellow
}

# Execute Optimization
Optimize-Services

# Instructions for Reversal
Write-Host "`nTo revert changes, run the following command in an elevated PowerShell:" -ForegroundColor Cyan
Write-Host ".\1.3.2-services-restore.ps1"
Write-Host "`nTo verify service states, use: Get-Service | Sort-Object DisplayName | Format-Table Name, DisplayName, Status, StartType"
Write-Host "Backup created before optimization." -ForegroundColor Cyan
Write-Host "Check restoration script and json backups at same folder." -ForegroundColor Cyan
Write-Host "Restart your PC after running this script for changes to take effect." -ForegroundColor Cyan