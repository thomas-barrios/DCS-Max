<#
.SYNOPSIS
    PC Restore Script
    Restores files from a specified backup folder (or latest if not specified) to original locations
.DESCRIPTION
    Accepts -BackupFolder param (optional, defaults to latest), restores files using env vars for portability
    Requires admin for some paths (e.g., ProgramData), logs to file/console
#>

param (
    [Parameter(Mandatory=$false)]
    [ValidateScript({ if ($_) { Test-Path $_ -PathType Container } else { $true } })]
    [string]$BackupFolder
)

# If no backup folder specified, use the latest one
if (-not $BackupFolder) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $LatestBackup = Get-ChildItem -Path $ScriptDir -Directory | 
                    Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}-dcs-settings-backup$' } | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -First 1
    if ($LatestBackup) {
        $BackupFolder = $LatestBackup.FullName
        Write-Host "Using latest backup: $BackupFolder" -ForegroundColor Cyan
    } else {
        Write-Error "No backup folders found in $ScriptDir"
        exit 1
    }
}

# === CONFIGURATION ===
$UserName = $env:USERNAME
$RestoreLog = "$env:USERPROFILE\Documents\DCS-Max\Backups\_RestoreLog.txt"
$SavedGamesPath = "$env:USERPROFILE\Saved Games"

# Path mappings for restoration
$PathMappings = @{
    "^C\\Users\\$UserName\\AppData\\Local\\" = "$env:USERPROFILE\AppData\Local\"
    "^C\\Users\\$UserName\\AppData\\Roaming\\" = "$env:USERPROFILE\AppData\Roaming\"
    "^C\\ProgramData\\" = "$env:PROGRAMDATA\"
    "^D\\Users\\$UserName\\Saved Games\\" = "$SavedGamesPath\"
}

# === UTILITY FUNCTIONS ===
function Write-RestoreLog {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level]: $Message"
    $color = switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } default { "Green" } }
    Write-Host $LogMessage -ForegroundColor $color
    Add-Content -Path $RestoreLog -Value $LogMessage -ErrorAction SilentlyContinue
}

function Test-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-RestoreLog "WARN: Admin recommended for restoring all files" "WARN"
        Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
        try {
            Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -BackupFolder `"$BackupFolder`"" -Verb RunAs -ErrorAction Stop
            exit 0
        } catch {
            Write-RestoreLog "ERROR: Failed to relaunch as Admin: $($_.Exception.Message)" "ERROR"
            Write-RestoreLog "Continuing without admin; some files may fail" "WARN"
        }
    }
}

# === MAIN EXECUTION ===
try {
    # Ensure log directory
    $LogDir = Split-Path $RestoreLog -Parent
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    Write-RestoreLog "=== RESTORE STARTED from $BackupFolder ==="

    # Check admin
    Test-Admin

    # Restore files
    $FilesRestored = 0
    $FilesSkipped = 0
    $FailedFiles = @()

    Get-ChildItem -Path $BackupFolder -Recurse -File | Where-Object { $_.Name -notlike 'Restore-*.bat' } | ForEach-Object {
        $SourcePath = $_.FullName
        $RelativePath = $SourcePath -replace [regex]::Escape($BackupFolder), '' -replace '^[\\/]', ''

        # Reconstruct original path
        $OriginalPath = $null
        foreach ($pattern in $PathMappings.Keys) {
            if ($RelativePath -match $pattern) {
                $OriginalPath = Join-Path $PathMappings[$pattern] ($RelativePath -replace $pattern, '')
                break
            }
        }
        if (-not $OriginalPath) {
            $OriginalPath = $RelativePath -replace '^([A-Z])\\', '$1:\'
        }

        # Validate path
        if ([string]::IsNullOrWhiteSpace($OriginalPath) -or $OriginalPath -eq $SourcePath) {
            Write-RestoreLog "ERROR: Invalid path for '$SourcePath'" "ERROR"
            $FilesSkipped++
            $FailedFiles += $SourcePath
            return
        }

        # Ensure destination directory
        $DestDir = Split-Path $OriginalPath -Parent
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

        # Warn if overwriting
        if (Test-Path $OriginalPath) {
            Write-RestoreLog "WARN: Overwriting '$OriginalPath'" "WARN"
        }

        # Copy and verify
        try {
            Copy-Item -Path $SourcePath -Destination $OriginalPath -Force -ErrorAction Stop
            if (Test-Path $OriginalPath) {
                Write-RestoreLog "RESTORED: $SourcePath -> $OriginalPath"
                $FilesRestored++
            } else {
                throw "File not found at destination"
            }
        } catch {
            Write-RestoreLog "ERROR: FAILED: $SourcePath -> $OriginalPath - $($_.Exception.Message)" "ERROR"
            $FilesSkipped++
            $FailedFiles += $SourcePath
        }
    }

    # Summary
    Write-RestoreLog "RESTORE COMPLETE: $FilesRestored restored, $FilesSkipped skipped"
    if ($FilesSkipped) {
        Write-RestoreLog "Failed files:"
        $FailedFiles | ForEach-Object { Write-RestoreLog "  - $_" "ERROR" }
    }
} catch {
    Write-RestoreLog "CRITICAL ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}
pause