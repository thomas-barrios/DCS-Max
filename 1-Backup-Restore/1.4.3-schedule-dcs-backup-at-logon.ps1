# Schedule DCS Backup Script for DCS-Max
# Purpose: Create automated Windows Task Scheduler entries for regular DCS backups
# Author: DCS-Max Suite
# Date: November 12, 2025
# Usage: Run to set up automated backups

param([switch]$NoPause = $false)

# Assure administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -NoPause:`$$NoPause" -Verb RunAs
    exit 
}

Write-Host ""
Write-Host "[SCHEDULE] DCS-Max: Schedule DCS Backup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[DATE]   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

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

Write-Host "[TASK]   $taskName" -ForegroundColor Gray
Write-Host "[SCRIPT] $(Split-Path $backupScriptPath -Leaf)" -ForegroundColor Gray
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

try {
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask) {
        Write-Host "[INFO]   Task already exists, updating..." -ForegroundColor Yellow
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-Host "[OK]     Removed existing task" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL]   Failed to remove existing task: $_" -ForegroundColor Red
            Write-Host "[INFO]   Run as administrator or manually delete in Task Scheduler" -ForegroundColor Gray
            exit 1
        }
    }
    
    # Create the action (what the task will do)
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$backupScriptPath`" -NoPause -Quiet"
    
    # Create the trigger (when the task will run)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    
    # Add delay to ensure system is fully loaded
    # $trigger.Delay = "PT2M"  # 2 minute delay after logon
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false
    
    # Create the principal (run as current user)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    # Register the task
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $taskDescription
    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
    
    Write-Host "[OK]     Scheduled task created" -ForegroundColor Green
    
    # Display task information
    Write-Host "[OK]     Trigger: At user logon" -ForegroundColor Green
    Write-Host "[OK]     User: $env:USERNAME" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL]   Failed to create scheduled task: $_" -ForegroundColor Red
    exit 1
}

Write-Host "------------------------------------------------" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Task scheduled successfully" -ForegroundColor Cyan
Write-Host "[INFO]   Task will run automatically at each logon" -ForegroundColor Gray
Write-Host "[INFO]   View in Task Scheduler: $taskName" -ForegroundColor Gray
Write-Host "[DONE]   DCS backup scheduling complete" -ForegroundColor Green
Write-Host ""

if (-not $NoPause) {
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}