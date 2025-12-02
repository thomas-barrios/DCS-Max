# PC Restore Script
# Restores files from a specified backup folder (or latest if not specified) to original locations
# Accepts -BackupFolder param (optional, defaults to latest), restores files using env vars for portability
# Requires admin for some paths (e.g., ProgramData), logs to file/console
# Optional: -NoPause to skip the pause at end (for automation/UI)

param (
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder,
    [switch]$NoPause = $false
)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -BackupFolder `"$BackupFolder`" -NoPause:`$$NoPause" -Verb RunAs; exit }

# Get script and root directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$BackupsDir = Join-Path $RootDir "Backups"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

# Resolve backup folder path
if ($BackupFolder) {
    # Try various path resolutions
    if (Test-Path $BackupFolder -PathType Container) {
        $BackupFolder = (Resolve-Path $BackupFolder).Path
    } elseif (Test-Path (Join-Path $RootDir $BackupFolder) -PathType Container) {
        $BackupFolder = (Resolve-Path (Join-Path $RootDir $BackupFolder)).Path
    } elseif (Test-Path (Join-Path $BackupsDir $BackupFolder) -PathType Container) {
        $BackupFolder = (Resolve-Path (Join-Path $BackupsDir $BackupFolder)).Path
    } else {
        Write-Host ""
        Write-Host "[RESTORE] DCS Settings Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   Backup folder not found: $BackupFolder" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { pause }
        exit 1
    }
} else {
    # Find latest backup in Backups directory
    $LatestBackup = Get-ChildItem -Path $BackupsDir -Directory -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}-dcs-settings-backup$' } | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
    if ($LatestBackup) {
        $BackupFolder = $LatestBackup.FullName
    } else {
        Write-Host ""
        Write-Host "[RESTORE] DCS Settings Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   No backup folders found in Backups directory" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { pause }
        exit 1
    }
}

# === CONFIGURATION ===
$UserName = $env:USERNAME
$RestoreLog = "$env:USERPROFILE\Documents\DCS-Max\Backups\_RestoreLog.txt"

# Find Saved Games path (may be on different drive than USERPROFILE)
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

# Restore groups with labels for output (matches backup structure)
$RestoreGroups = @(
    @{
        Label = "DCS World"
        Files = @(
            @{ BackupPattern = "DCS\Config\autoexec.cfg"; Dest = "$SavedGamesPath\DCS\Config\autoexec.cfg" },
            @{ BackupPattern = "DCS\Config\options.lua"; Dest = "$SavedGamesPath\DCS\Config\options.lua" },
            @{ BackupPattern = "DCS\Config\serverSettings.lua"; Dest = "$SavedGamesPath\DCS\Config\serverSettings.lua" }
        )
        Folders = @(
            @{ BackupPattern = "DCS\Config\Input"; Dest = "$SavedGamesPath\DCS\Config\Input" }
        )
    },
    @{
        Label = "Pimax VR"
        Files = @(
            @{ BackupPattern = "Pimax\runtime\profile.json"; Dest = "$env:USERPROFILE\AppData\Local\Pimax\runtime\profile.json" },
            @{ BackupPattern = "PiTool\manifest\PiTool\Common Setting.json"; Dest = "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\Common Setting.json" }
        )
        Folders = @()
    },
    @{
        Label = "Quad Views Foveated"
        Files = @(
            @{ BackupPattern = "Quad-Views-Foveated\settings.cfg"; Dest = "$env:USERPROFILE\AppData\Local\Quad-Views-Foveated\settings.cfg" }
        )
        Folders = @()
    },
    @{
        Label = "NVIDIA Control Panel"
        Files = @(
            @{ BackupPattern = "NVIDIA Corporation\Drs\nvdrsdb0.bin"; Dest = "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb0.bin" },
            @{ BackupPattern = "NVIDIA Corporation\Drs\nvdrsdb1.bin"; Dest = "$env:PROGRAMDATA\NVIDIA Corporation\Drs\nvdrsdb1.bin" }
        )
        Folders = @()
    },
    @{
        Label = "CapFrameX"
        Files = @(
            @{ BackupPattern = "CapFrameX\Configuration\AppSettings.json"; Dest = "$env:USERPROFILE\AppData\Roaming\CapFrameX\Configuration\AppSettings.json" }
        )
        Folders = @()
    },
    @{
        Label = "Discord"
        Files = @(
            @{ BackupPattern = "discord\settings.json"; Dest = "$env:USERPROFILE\AppData\Roaming\discord\settings.json" }
        )
        Folders = @()
    }
)

# === UTILITY FUNCTIONS ===
function Write-RestoreLog {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    Add-Content -Path $RestoreLog -Value $LogMessage -ErrorAction SilentlyContinue
}

function Find-BackupFile {
    param([string]$Pattern, [string]$BackupRoot)
    # Search for file matching pattern in backup folder
    $files = Get-ChildItem -Path $BackupRoot -Recurse -File -ErrorAction SilentlyContinue | 
             Where-Object { $_.FullName -like "*$Pattern" }
    return $files | Select-Object -First 1
}

function Find-BackupFolder {
    param([string]$Pattern, [string]$BackupRoot)
    # Search for folder matching pattern in backup folder
    $folders = Get-ChildItem -Path $BackupRoot -Recurse -Directory -ErrorAction SilentlyContinue | 
               Where-Object { $_.FullName -like "*$Pattern" -and $_.Name -eq (Split-Path $Pattern -Leaf) }
    return $folders | Select-Object -First 1
}

# === MAIN EXECUTION ===
try {
    # Ensure log directory
    $LogDir = Split-Path $RestoreLog -Parent
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-RestoreLog "Restore started from $BackupFolder"
    
    # Header
    Write-Host ""
    Write-Host "Starting restore..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[RESTORE] DCS-Max: DCS Settings Restore" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[DATE]   Restore Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[FILE]   Restoring from: $BackupFolder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[DCS]    DCS location: $SavedGamesPath\DCS" -ForegroundColor Gray
    Write-Host ""
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "[RESTORE] Restoring DCS settings..." -ForegroundColor Yellow
    Write-Host ""

    # Counters
    $FilesRestored = 0
    $FilesMissing = 0
    $FilesFailed = 0

    # Process each restore group
    foreach ($Group in $RestoreGroups) {
        $groupHasItems = $false
        
        # Check if group has any files to restore
        foreach ($FileInfo in $Group.Files) {
            $backupFile = Find-BackupFile -Pattern $FileInfo.BackupPattern -BackupRoot $BackupFolder
            if ($backupFile) { $groupHasItems = $true; break }
        }
        if (-not $groupHasItems) {
            foreach ($FolderInfo in $Group.Folders) {
                $backupFolder = Find-BackupFolder -Pattern $FolderInfo.BackupPattern -BackupRoot $BackupFolder
                if ($backupFolder) { $groupHasItems = $true; break }
            }
        }
        
        # Show group label if it has items
        if ($groupHasItems) {
            Write-Host "         --- $($Group.Label) ---" -ForegroundColor Yellow
        }
        
        # Restore files in this group
        foreach ($FileInfo in $Group.Files) {
            $backupFile = Find-BackupFile -Pattern $FileInfo.BackupPattern -BackupRoot $BackupFolder
            $fileName = Split-Path $FileInfo.Dest -Leaf
            
            if ($backupFile) {
                try {
                    $destDir = Split-Path $FileInfo.Dest -Parent
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    Copy-Item -Path $backupFile.FullName -Destination $FileInfo.Dest -Force -ErrorAction Stop
                    Write-Host "[OK]     $fileName" -ForegroundColor Green
                    Write-RestoreLog "RESTORED: $($backupFile.FullName) -> $($FileInfo.Dest)"
                    $FilesRestored++
                } catch {
                    Write-Host "[FAIL]   $fileName - $($_.Exception.Message)" -ForegroundColor Red
                    Write-RestoreLog "FAILED: $fileName - $($_.Exception.Message)" "ERROR"
                    $FilesFailed++
                }
            } else {
                Write-Host "[SKIP]   $fileName (not in backup)" -ForegroundColor DarkGray
                Write-RestoreLog "MISSING: $($FileInfo.BackupPattern)" "WARN"
                $FilesMissing++
            }
        }
        
        # Restore folders in this group
        foreach ($FolderInfo in $Group.Folders) {
            $backupFolderPath = Find-BackupFolder -Pattern $FolderInfo.BackupPattern -BackupRoot $BackupFolder
            $folderName = Split-Path $FolderInfo.Dest -Leaf
            
            if ($backupFolderPath) {
                try {
                    $destDir = Split-Path $FolderInfo.Dest -Parent
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    
                    # Remove existing folder and copy fresh
                    if (Test-Path $FolderInfo.Dest) {
                        Remove-Item -Path $FolderInfo.Dest -Recurse -Force -ErrorAction Stop
                    }
                    Copy-Item -Path $backupFolderPath.FullName -Destination $FolderInfo.Dest -Recurse -Force -ErrorAction Stop
                    
                    $fileCount = (Get-ChildItem $FolderInfo.Dest -Recurse -File).Count
                    Write-Host "[OK]     $folderName/ ($fileCount files)" -ForegroundColor Green
                    Write-RestoreLog "RESTORED: $($backupFolderPath.FullName) -> $($FolderInfo.Dest) ($fileCount files)"
                    $FilesRestored += $fileCount
                } catch {
                    Write-Host "[FAIL]   $folderName/ - $($_.Exception.Message)" -ForegroundColor Red
                    Write-RestoreLog "FAILED: $folderName/ - $($_.Exception.Message)" "ERROR"
                    $FilesFailed++
                }
            } else {
                Write-Host "[SKIP]   $folderName/ (not in backup)" -ForegroundColor DarkGray
                Write-RestoreLog "MISSING FOLDER: $($FolderInfo.BackupPattern)" "WARN"
                $FilesMissing++
            }
        }
    }

    # Summary
    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host "[SUMMARY] Restore Summary:" -ForegroundColor Cyan
    Write-Host "[OK]     Restored: $FilesRestored files" -ForegroundColor Green
    Write-Host "[SKIP]   Missing: $FilesMissing" -ForegroundColor DarkGray
    Write-Host "[FAIL]   Failed: $FilesFailed" -ForegroundColor $(if ($FilesFailed -gt 0) { "Red" } else { "DarkGray" })
    Write-Host ""
    Write-Host "[INFO]   Restart DCS for changes to take effect." -ForegroundColor Gray
    Write-Host ""
    Write-Host "[OK]     DCS settings restore completed!" -ForegroundColor Green
    Write-Host ""
    
    if ($FilesFailed -eq 0) {
        Write-Host "[SUCCESS] Restore completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Restore completed with $FilesFailed errors" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-RestoreLog "Restore complete: $FilesRestored restored, $FilesMissing missing, $FilesFailed failed"
} catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host "[FAIL]   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[WARN] Restore failed!" -ForegroundColor Red
    Write-Host ""
    Write-RestoreLog "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}
if (-not $NoPause) { pause }
