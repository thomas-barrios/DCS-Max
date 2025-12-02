# TASKS RESTORATION
# NO PROMPTS. FULLY AUTOMATED.
# Run AS ADMIN. Restores from latest tasks-backup.xml in current folder, or specified XML.
# Backup must exist: 2025-11-13-12-25-10-tasks-backup.xml (ISO timestamped)
#
# Usage:
# .\1.2.3-tasks-restore.ps1                            # Restores from latest backup
# .\1.2.3-tasks-restore.ps1 -XmlFile "filename.xml"    # Restores from specific XML file
# Optional: -NoPause to skip the pause at end (for automation/UI)

param(
    [string]$XmlFile,
    [switch]$NoPause = $false
)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Counters
$registered = 0
$enabled = 0
$failed = 0

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupsDirectory = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'

if ($XmlFile) {
    # Check various path possibilities
    if (Test-Path $XmlFile) {
        $backupPath = Get-Item $XmlFile
    } elseif (Test-Path (Join-Path $rootDirectory $XmlFile)) {
        $backupPath = Get-Item (Join-Path $rootDirectory $XmlFile)
    } elseif (Test-Path (Join-Path $backupsDirectory $XmlFile)) {
        $backupPath = Get-Item (Join-Path $backupsDirectory $XmlFile)
    } else {
        Write-Host ""
        Write-Host "[RESTORE] Scheduled Tasks Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   Backup file not found: $XmlFile" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        return
    }
} else {
    $backupPath = Get-ChildItem "$backupsDirectory\*tasks-backup.xml" | 
                  Sort LastWriteTime -Descending | Select -First 1
    if (-not $backupPath) {
        Write-Host ""
        Write-Host "[RESTORE] Scheduled Tasks Restore" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor DarkGray
        Write-Host "[FAIL]   No backup file found in $backupsDirectory" -ForegroundColor Red
        Write-Host ""
        if (-not $NoPause) { Pause }
        return
    }
}

# Header
Write-Host ""
Write-Host "Starting restore..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[RESTORE] DCS-Max: Scheduled Tasks Restore" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Restore Date: $(Get-Date -Format 'MM/dd/yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
Write-Host "[FILE]   Restoring from: $($backupPath.FullName)" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

$tasks = Import-Clixml $backupPath.FullName

Write-Host ""
Write-Host "[OK]     Loaded backup with $($tasks.Count) tasks" -ForegroundColor Green
Write-Host ""
Write-Host "[RESTORE] Restoring scheduled tasks..." -ForegroundColor Yellow
Write-Host ""

foreach ($task in $tasks) {
    try {
        $existing = Get-ScheduledTask $task.TaskName -ErrorAction SilentlyContinue
        if (-not $existing) {
            # Re-register FULL task (actions, triggers, settings)
            $params = @{
                TaskName    = $task.TaskName
                TaskPath    = $task.TaskPath
                Action      = $task.Actions
                Trigger     = $task.Triggers
                Settings    = $task.Settings
                Principal   = $task.Principal
                Description = $task.Description
                Force       = $true
            }
            Register-ScheduledTask @params | Out-Null
            Write-Host "[OK]     Registered: $($task.TaskName)" -ForegroundColor Green
            $registered++
        }

        # Re-enable if was enabled
        if ($task.State -eq "Ready" -or $task.State -eq "Running") {
            try {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath | Out-Null
                Write-Host "[OK]     Enabled: $($task.TaskName)" -ForegroundColor Green
                $enabled++
            } catch {
                Write-Host "[FAIL]   Enable failed: $($task.TaskName)" -ForegroundColor Red
                $failed++
            }
        }
    }
    catch {
        Write-Host "[FAIL]   $($task.TaskName): $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Restore Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Registered: $registered" -ForegroundColor Green
Write-Host "[OK]     Enabled: $enabled" -ForegroundColor Green
Write-Host "[FAIL]   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host ""
Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Scheduled tasks restore completed!" -ForegroundColor Green
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[SUCCESS] Restore completed successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Restore completed with $failed errors" -ForegroundColor Yellow
}
Write-Host ""

if (-not $NoPause) { Pause }