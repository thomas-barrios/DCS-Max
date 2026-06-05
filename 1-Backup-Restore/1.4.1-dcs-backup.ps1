# PC Backup Script
# Runs at logon, creates timestamped backup in %USERPROFILE%\Documents\DCS-Max\Backups
# Backs up critical user files, generates a BAT to trigger restore
# Uses env vars for portability, logs to file/console, no admin required

param([switch]$NoPause = $false, [switch]$Quiet = $false)

# === CONFIGURATION ===
$UserName = $env:USERNAME
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$BackupsDir = Join-Path $RootDir "Backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$BackupFolder = "$BackupsDir\$Timestamp-dcs-settings-backup"
$LogFile = "$BackupsDir\_BackupLog.txt"

# Import PathResolver and VR modules
$PathResolverPath = Join-Path $RootDir "lib\PathResolver.ps1"
$VRConfigPath = Join-Path $RootDir "lib\VRHeadsetConfig.ps1"

if (Test-Path $PathResolverPath) {
    . $PathResolverPath
} else {
    Write-Warning "PathResolver module not found. Using fallback path discovery."
}

if (Test-Path $VRConfigPath) {
    . $VRConfigPath
} else {
    Write-Warning "VRHeadsetConfig module not found. Some VR settings may not be backed up."
}

# Discover DCS Saved Games location from config-global.json
# Discover DCS Saved Games location from config-global.json
$globalConfigPath = Join-Path $PSScriptRoot "..\config-global.json"
$savedGamesPath = if (Test-Path $globalConfigPath) {
    try {
        $globalConfig = Get-Content -Path $globalConfigPath -Raw | ConvertFrom-Json
        if ($globalConfig.paths -and $globalConfig.paths.savedGamesPath) {
            $path = $globalConfig.paths.savedGamesPath
            [Environment]::ExpandEnvironmentVariables($path)
        } else {
            "$env:USERPROFILE\Saved Games"
        }
    } catch {
        "$env:USERPROFILE\Saved Games"
    }
} else {
    "$env:USERPROFILE\Saved Games"
}

# Check if path exists, if not auto-detect on D: or C: drives
$DCSsavedGamesPath = $savedGamesPath.TrimEnd('\\')

if (-not (Test-Path $DCSsavedGamesPath -PathType Container)) {
    Write-Log "Configured path not found: $DCSsavedGamesPath - Attempting auto-detection..." "WARN"
    
    # Search on D: and C: drives
    $detectedPath = $null
    foreach ($drive in @('D:', 'C:')) {
        $pathsToTry = @(
            "$drive\Users\$env:USERNAME\Saved Games\DCS",
            "$drive\Saved Games\DCS"
        )
        
        foreach ($tryPath in $pathsToTry) {
            if (Test-Path $tryPath -PathType Container) {
                $detectedPath = $tryPath
                Write-Log "Auto-detected DCS location: $detectedPath" "INFO"
                break
            }
        }
        
        if ($detectedPath) { break }
    }
    
    if ($detectedPath) {
        $DCSsavedGamesPath = $detectedPath
    } else {
        Write-Log "Could not auto-detect DCS saved games location" "WARN"
    }
}

# Normalize to ensure path points to the DCS folder
# (Removed: rely on user-provided savedGamesPath)
# Counters
$script:backedUp = 0
$script:missing = 0

# === UTILITY FUNCTIONS ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
}

# Get VR backup groups (conditional based on installed headsets)
$VRBackupGroups = @()
if (Test-Path function:Get-VRBackupGroups) {
    $VRBackupGroups = Get-VRBackupGroups
}

# Backup groups with labels for output
$BackupGroups = @(
    @{
        Label = "DCS World"
        Files = @(
            "$DCSsavedGamesPath\Config\autoexec.cfg",
            "$DCSsavedGamesPath\Config\options.lua",
            "$DCSsavedGamesPath\Config\serverSettings.lua"
        )
        Folders = @(
            "$DCSsavedGamesPath\Config\Input"
        )
    }
) + $VRBackupGroups + @(
    @{
        Label = "Quad Views Foveated"
        Files = @(
            "$env:USERPROFILE\AppData\Local\Quad-Views-Foveated\settings.cfg"
        )
        Folders = @()
    },
    @{
        Label = "NVIDIA Control Panel"
        Files = @(
            "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb0.bin",
            "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb1.bin"
        )
        Folders = @()
    },
    @{
        Label = "CapFrameX"
        Files = @(
            "$env:USERPROFILE\AppData\Roaming\CapFrameX\Configuration\AppSettings.json"
        )
        Folders = @()
    },
    @{
        Label = "Discord"
        Files = @(
            "$env:USERPROFILE\AppData\Roaming\discord\settings.json"
        )
        Folders = @()
    }
)

# === MAIN EXECUTION ===
try {
    # Create backup root and folder
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
    
    # Header
    Write-Host ""
    Write-Host "Starting backup..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[BACKUP] DCS-Max: DCS Settings Backup" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[DATE]   Backup Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[PATH]   Saving to: $BackupFolder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[BACKUP] Backing up DCS settings..." -ForegroundColor Yellow
    Write-Host ""
    Write-Log "Backup started: $BackupFolder"

    # Process each backup group
    foreach ($Group in $BackupGroups) {
        $groupHasItems = $false
        
        # Check if group has any existing files or folders
        foreach ($File in $Group.Files) {
            if (Test-Path $File -PathType Leaf) { $groupHasItems = $true; break }
        }
        if (-not $groupHasItems) {
            foreach ($Folder in $Group.Folders) {
                if (Test-Path $Folder -PathType Container) { $groupHasItems = $true; break }
            }
        }
        
        # Show group label if it has items
        if ($groupHasItems) {
            Write-Host "         --- $($Group.Label) ---" -ForegroundColor Yellow
        }
        
        # Backup files in this group
        foreach ($File in $Group.Files) {
            if (Test-Path $File -PathType Leaf) {
                $DestPath = Join-Path $BackupFolder ($File -replace ':', '')
                $DestDir = Split-Path $DestPath -Parent
                New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
                Copy-Item -Path $File -Destination $DestPath -Force -ErrorAction Stop
                $script:backedUp++
                $fileName = Split-Path $File -Leaf
                Write-Host "[OK]     $fileName" -ForegroundColor Green
                Write-Host "         Path: $File" -ForegroundColor DarkGray
                Write-Log "$File -> $DestPath"
            } else {
                $script:missing++
                $fileName = Split-Path $File -Leaf
                Write-Host "[SKIP]   $fileName (not found)" -ForegroundColor DarkGray
                Write-Host "         Path: $File" -ForegroundColor DarkGray
                Write-Log "MISSING: $File" "WARN"
            }
        }
        
        # Backup folders in this group
        foreach ($Folder in $Group.Folders) {
            if (Test-Path $Folder -PathType Container) {
                $DestPath = Join-Path $BackupFolder ($Folder -replace ':', '')
                $fileCount = (Get-ChildItem $Folder -Recurse -File).Count
                Copy-Item -Path $Folder -Destination $DestPath -Recurse -Force -ErrorAction Stop
                $script:backedUp += $fileCount
                $folderName = Split-Path $Folder -Leaf
                Write-Host "[OK]     $folderName/ ($fileCount files)" -ForegroundColor Green
                Write-Host "         Path: $Folder" -ForegroundColor DarkGray
                Write-Log "$Folder -> $DestPath ($fileCount files)"
            } else {
                $script:missing++
                $folderName = Split-Path $Folder -Leaf
                Write-Host "[SKIP]   $folderName/ (not found)" -ForegroundColor DarkGray
                Write-Host "         Path: $Folder" -ForegroundColor DarkGray
                Write-Log "MISSING FOLDER: $Folder" "WARN"
            }
        }
    }

    # Summary
    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host "[SUMMARY] Backup Summary:" -ForegroundColor Cyan
    Write-Host "[OK]     Backed up: $script:backedUp files" -ForegroundColor Green
    Write-Host "[SKIP]   Missing: $script:missing" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[INFO]   To restore, run:" -ForegroundColor Gray
    Write-Host "         .\1.4.2-dcs-restore.ps1 -BackupFolder `"$Timestamp-dcs-settings-backup`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[OK]     DCS settings backup completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[SUCCESS] Backup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Log "Backup complete: $script:backedUp files"
    
    if (-not $NoPause) {
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host "[FAIL]   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[WARN] Backup failed!" -ForegroundColor Red
    Write-Host ""
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}