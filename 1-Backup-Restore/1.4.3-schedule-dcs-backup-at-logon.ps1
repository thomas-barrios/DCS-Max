#requires -RunAsAdministrator

# Schedule DCS Backup Script for DCS-Max
# Purpose: Create automated Windows Task Scheduler entries for regular DCS backups
# Author: DCS-Max Suite
# Date: November 12, 2025
# Usage: Run as Administrator to set up automated backups

# Set execution policy to allow script to run
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "[OK] Execution policy set to RemoteSigned for current user" -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Failed to set execution policy: $_"
    exit 1
}

Write-Host "[SCHEDULE] DCS-Max: Schedule DCS Backup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "[DATE] Setup Date: $(Get-Date)" -ForegroundColor White
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScriptPath = Join-Path $scriptDir "1.4.1-dcs-backup.ps1"

# Check if backup script exists
if (-not (Test-Path $backupScriptPath)) {
    Write-Error "[ERROR] DCS backup script not found at: $backupScriptPath"
    Write-Host "Please ensure 1.4.1-dcs-backup.ps1 is in the same directory." -ForegroundColor Yellow
    exit 1
}

# Task settings
$taskName = "DCS-Max Logon Backup"
$taskDescription = "Automated DCS World configuration backup at user logon"

Write-Host "[CONFIG] Creating scheduled task:" -ForegroundColor Yellow
Write-Host "   [NAME] Task Name: $taskName" -ForegroundColor White
Write-Host "   [DATE] Schedule: At user logon" -ForegroundColor White
Write-Host "   [SCRIPT] Script: $(Split-Path $backupScriptPath -Leaf)" -ForegroundColor White
Write-Host ""

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "[WARNING] Task '$taskName' already exists." -ForegroundColor Yellow
        $response = Read-Host "Do you want to update it? (Y/N)"
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "[REMOVED] Removed existing task" -ForegroundColor Yellow
        } else {
            Write-Host "[CANCELLED] Operation cancelled by user" -ForegroundColor Red
            exit 0
        }
    }
    
    # Create the action (what the task will do)
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$backupScriptPath`""
    
    # Create the trigger (when the task will run)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    
    # Add delay to ensure system is fully loaded
    $trigger.Delay = "PT2M"  # 2 minute delay after logon
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    
    # Create the principal (run as current user with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    
    # Register the task
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $taskDescription
    Register-ScheduledTask -TaskName $taskName -InputObject $task | Out-Null
    
    Write-Host "[OK] Scheduled task created successfully!" -ForegroundColor Green
    
    # Display task information
    $createdTask = Get-ScheduledTask -TaskName $taskName
    Write-Host ""
    Write-Host "[INFO] Task Details:" -ForegroundColor Cyan
    Write-Host "   [NAME] Name: $($createdTask.TaskName)" -ForegroundColor White
    Write-Host "   [DESC] Description: $($createdTask.Description)" -ForegroundColor White
    Write-Host "   [USER] User: $($createdTask.Principal.UserId)" -ForegroundColor White
    Write-Host "   [LEVEL] Run Level: $($createdTask.Principal.RunLevel)" -ForegroundColor White
    Write-Host "   [SCHEDULE] Next Run: $((Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo).NextRunTime)" -ForegroundColor White
    
} catch {
    Write-Error "[ERROR] Failed to create scheduled task: $_"
    exit 1
}

Write-Host ""
Write-Host "[NEXT] Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Task will run automatically at user logon" -ForegroundColor White
Write-Host "   2. Check Task Scheduler to modify settings if needed" -ForegroundColor White
Write-Host "   3. Test the task by logging out and back in, or run manually" -ForegroundColor White
Write-Host ""
Write-Host "[MANAGE] Management Options:" -ForegroundColor Yellow
Write-Host "   - View Task: Get-ScheduledTask '$taskName' | Get-ScheduledTaskInfo" -ForegroundColor Gray
Write-Host "   - Remove Task: Unregister-ScheduledTask '$taskName' -Confirm:`$false" -ForegroundColor Gray
Write-Host "   - Run Now: Start-ScheduledTask '$taskName'" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK] DCS backup scheduling completed successfully!" -ForegroundColor Green
Pause