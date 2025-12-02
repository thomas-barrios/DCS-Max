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

# Find Saved Games path (may be on different drive than USERPROFILE)
# Check multiple possible locations for Saved Games, starting with common alternate drives
$possiblePaths = @(
    "D:\Users\$UserName\Saved Games",
    "E:\Users\$UserName\Saved Games",
    "$env:USERPROFILE\Saved Games",
    [Environment]::GetFolderPath('UserProfile') + "\Saved Games"
)
$SavedGamesPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path "$path\DCS") {
        $SavedGamesPath = $path
        break
    }
}
if (-not $SavedGamesPath) {
    $SavedGamesPath = "$env:USERPROFILE\Saved Games"
}

# Counters
$script:backedUp = 0
$script:missing = 0

# === UTILITY FUNCTIONS ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
}

# Backup groups with labels for output
$BackupGroups = @(
    @{
        Label = "DCS World"
        Files = @(
            "$SavedGamesPath\DCS\Config\autoexec.cfg",
            "$SavedGamesPath\DCS\Config\options.lua",
            "$SavedGamesPath\DCS\Config\serverSettings.lua"
        )
        Folders = @(
            "$SavedGamesPath\DCS\Config\Input"
        )
    },
    @{
        Label = "Pimax VR"
        Files = @(
            "$env:USERPROFILE\AppData\Local\Pimax\runtime\profile.json",
            "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\Common Setting.json"
        )
        Folders = @()
    },
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
    Write-Host "[DCS]    DCS location: $SavedGamesPath\DCS" -ForegroundColor Gray
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
                Write-Log "$File -> $DestPath"
            } else {
                $script:missing++
                $fileName = Split-Path $File -Leaf
                Write-Host "[SKIP]   $fileName (not found)" -ForegroundColor DarkGray
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
                Write-Log "$Folder -> $DestPath ($fileCount files)"
            } else {
                $script:missing++
                $folderName = Split-Path $Folder -Leaf
                Write-Host "[SKIP]   $folderName/ (not found)" -ForegroundColor DarkGray
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