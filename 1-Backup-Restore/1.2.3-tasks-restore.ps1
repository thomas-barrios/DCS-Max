# TASKS RESTORATION
# NO PROMPTS. FULLY AUTOMATED.
# Run AS ADMIN. Restores from latest tasks-backup.xml in current folder, or specified XML.
# Backup must exist: 2025-11-13-12-25-10-tasks-backup.xml (ISO timestamped)
#
# Usage:
# .\2.2.3-tasks-restore.ps1                            # Restores from latest backup
# .\2.2.3-tasks-restore.ps1 -XmlFile "filename.xml"    # Restores from specific XML file

param([string]$XmlFile)

if ($XmlFile) {
    if (Test-Path $XmlFile) {
        $backupPath = Get-Item $XmlFile
    } else {
        Write-Host "ERROR: Specified XML file not found: $XmlFile" -ForegroundColor Red
        return
    }
} else {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $rootDirectory = Split-Path -Parent $scriptDir
    $backupsDirectory = Join-Path $rootDirectory "Backups"
    $backupPath = Get-ChildItem "$backupsDirectory\*tasks-backup.xml" | 
                  Sort LastWriteTime -Descending | Select -First 1
    if (-not $backupPath) {
        Write-Host "ERROR: No backup file found in $backupsDirectory! Run backup first." -ForegroundColor Red
        return
    }
}

Write-Host "RESTORING from: $($backupPath.Name)`n" -ForegroundColor Cyan

$tasks = Import-Clixml $backupPath.FullName

$restored = 0; $enabled = 0
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
                Write-Host "REGISTERED: $($task.TaskPath)$($task.TaskName)" -ForegroundColor Green
                $restored++
        }

        # Re-enable if was enabled
        if ($task.State -eq "Ready" -or $task.State -eq "Running") {
            try {
                Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath | Out-Null
                Write-Host "ENABLED: $($task.TaskPath)$($task.TaskName)" -ForegroundColor Cyan
                $enabled++
            } catch {
                Write-Host "FAILED TO ENABLE: $($task.TaskPath)$($task.TaskName)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "FAILED: $($task.TaskPath)$($task.TaskName) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

    Write-Host "`nRESTORE COMPLETE: $restored registered, $enabled re-enabled.`n" -ForegroundColor Green
    Write-Host "Verify: Get-ScheduledTask | ? State -eq Ready | Select TaskName" -ForegroundColor White