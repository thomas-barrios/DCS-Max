# PC Backup Script
# Runs at logon, creates timestamped backup in %USERPROFILE%\Documents\DCS-Max\Backups
# Backs up critical user files, generates a BAT to trigger restore
# Uses env vars for portability, logs to file/console, no admin required

param([switch]$Quiet = $false)

# === CONFIGURATION ===
$UserName = $env:USERNAME
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$BackupsDir = Join-Path $RootDir "Backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$BackupFolder = "$BackupsDir\$Timestamp-dcs-settings-backup"
$LogFile = "$BackupsDir\_BackupLog.txt"
$SavedGamesPath = "$env:USERPROFILE\Saved Games"

# === UTILITY FUNCTIONS ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
    if (!$Quiet) {
        $color = switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } default { "Green" } }
        Write-Host $LogMessage -ForegroundColor $color
    }
}

Write-Log "Quiet parameter: $Quiet"

# Files to backup (grouped for readability)
$FilesToBackup = @(
    # DCS World Settings
    "$SavedGamesPath\DCS\Config\autoexec.cfg",
    "$SavedGamesPath\DCS\Config\nicknames.lua",
    "$SavedGamesPath\DCS\Config\options.lua",
    "$SavedGamesPath\DCS\Config\OptionsPresets\Custom1.lua",
    "$SavedGamesPath\DCS\Config\OptionsPresets\Custom2.lua",
    "$SavedGamesPath\DCS\Config\OptionsPresets\Custom3.lua",
    "$SavedGamesPath\DCS\Config\options.lua.nonvr",
    "$SavedGamesPath\DCS\Config\serverSettings.lua",
    
    # Pimax VR
    "$env:USERPROFILE\AppData\Local\Pimax\runtime\profile.json",
    "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\beforeConfig.json",
    "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\Common Setting.json",
    
    # Quad Views Foveated
    "$env:USERPROFILE\AppData\Local\Quad-Views-Foveated\settings.cfg",
    
    # NVIDIA Control Panel
    "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb0.bin",
    "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb1.bin",
    
    # CapFrameX
    "$env:USERPROFILE\AppData\Roaming\CapFrameX\Configuration\AppSettings.json",
    
    # Discord
    "$env:USERPROFILE\AppData\Roaming\discord\settings.json"
)

# === UTILITY FUNCTIONS ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
    if (!$Quiet) {
        $color = switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } default { "Green" } }
        Write-Host $LogMessage -ForegroundColor $color
    }
}

# === MAIN EXECUTION ===
try {
    # Create backup root and folder
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
    Write-Log "Created backup folder: $BackupFolder"

    # Backup files, preserving path structure
    $BackupCount = 0
    foreach ($File in $FilesToBackup) {
        if (Test-Path $File -PathType Leaf) {
            $DestPath = Join-Path $BackupFolder ($File -replace ':', '')
            $DestDir = Split-Path $DestPath -Parent
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
            Copy-Item -Path $File -Destination $DestPath -Force -ErrorAction Stop
            $BackupCount++
            Write-Log "$File -> $DestPath"
        } else {
            Write-Log "MISSING: $File" "WARN"
        }
    }

    # Summary
    Write-Log "=== BACKUP COMPLETE ==="
    Write-Log "Files backed up: $BackupCount / $($FilesToBackup.Count)"
    Write-Log "Backup location: $BackupFolder"
    if (!$Quiet) {
        Write-Host "`n=== BACKUP SUCCESSFUL ===" -ForegroundColor Green
        Write-Host "Backup saved to: $BackupFolder" -ForegroundColor Cyan
        Write-Host "Total files backed up: $BackupCount / $($FilesToBackup.Count)" -ForegroundColor Cyan
        Write-Host "For restoration use: .\1.4.2-dcs-restore.ps1 -BackupFolder '$BackupFolder'" -ForegroundColor Cyan
        Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}