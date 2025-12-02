# Backup and Disable Windows Scheduled Tasks for DCS Optimization
# Purpose: Backs up current states of specified tasks to XML, then disables them to minimize background CPU/network usage,
# reducing frame times and stutters in DCS for competitive play (e.g., TACT, SATAL, JustDogFights servers).
# Focus: Efficient, readable code with error handling; assumes run as Administrator.
# Optimizations: Uses arrays/hashtables for fast lookups; processes in bulk; skips non-existent tasks to avoid errors.
# Usage: Run in PowerShell; restore via backup XML using 1.2.3-tasks-restore.ps1.
# Note: These disables are safe/optional for gaming setups without Edge/Google/.NET/UWP dependencies; tested for stability in HARPIA team setups.
# Optional: -NoPause to skip the pause at end (for automation/UI)

param([switch]$NoPause = $false)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


# List of all tasks to disable (full identifiers from SafeToDisable and OptionalToDisable)
$taskIdentifiers = @(
    "\MicrosoftEdgeUpdateTaskMachineCore{39097A80-6523-43D6-BACB-628BA6DD09F0}",
    "\MicrosoftEdgeUpdateTaskMachineUA{2A4AAE6C-2313-4523-AC90-9B058AA03A49}",
    "\GoogleSystem\GoogleUpdater\GoogleUpdaterTaskSystem142.0.7416.0{54C60EF4-20E4-4CAB-BCAB-B720B2B1352D}",
    "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 Critical",
    "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 64 Critical",
    "\Microsoft\Windows\AccountHealth\RecoverabilityToastTask",
    "\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)",
    "\Microsoft\Windows\AppID\EDP Policy Manager",
    "\Microsoft\Windows\Application Experience\MareBackup",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp",
    "\Microsoft\Windows\Application Experience\StartupAppTask",
    "\Microsoft\Windows\ApplicationData\appuriverifierdaily",
    "\Microsoft\Windows\ApplicationData\appuriverifierinstall",
    "\Microsoft\Windows\AppListBackup\Backup",
    "\Microsoft\Windows\AppListBackup\BackupNonMaintenance",
    "\Microsoft\Windows\AppxDeploymentClient\Pre-staged app cleanup",
    "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\BitLocker\BitLocker Encrypt All Drives",
    "\Microsoft\Windows\BitLocker\BitLocker MDM policy Refresh",
    "\Microsoft\Windows\Bluetooth\UninstallDeviceTask",
    "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask",
    "\Microsoft\Windows\capabilityaccessmanager\maintenancetasks",
    "\Microsoft\Windows\User Profile Service\HiveUploadTask",
    "\Microsoft\Windows\WaaSMedic\PerformRemediation",
    "\Microsoft\Windows\WCM\WiFiTask",
    "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
    "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup",
    "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
    "\Microsoft\Windows\Windows Defender\Windows Defender Verification",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange",
    "\Microsoft\Windows\WindowsAI\Recall\InitialConfiguration",
    "\Microsoft\Windows\WindowsAI\Recall\PolicyConfiguration",
    "\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache",
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
    "\Microsoft\Windows\WlanSvc\CDSSync",
    "\Microsoft\Windows\WlanSvc\MoProfileManagement",
    "\Microsoft\Windows\WOF\WIM-Hash-Management",
    "\Microsoft\Windows\WOF\WIM-Hash-Validation",
    "\Microsoft\Windows\Work Folders\Work Folders Logon Synchronization",
    "\Microsoft\Windows\Work Folders\Work Folders Maintenance Work",
    "\Microsoft\Windows\Workplace Join\Automatic-Device-Join",
    "\Microsoft\Windows\Workplace Join\Device-Sync",
    "\Microsoft\Windows\Workplace Join\Recovery-Check",
    "\Microsoft\Windows\WwanSvc\NotificationTask",
    "\Microsoft\Windows\WwanSvc\OobeDiscovery",
    "\Microsoft\XblGameSave\XblGameSaveTask",
    # Optional
    "\PauseWindowsUpdate",
    "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319",
    "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 64",
    "\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)",
    "\Microsoft\Windows\AppID\PolicyConverter",
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask",
    "\Microsoft\Windows\Application Experience\SdbinstMergeDbTask",
    "\Microsoft\Windows\ApplicationData\CleanupTemporaryState",
    "\Microsoft\Windows\ApplicationData\DsSvcCleanup",
    "\Microsoft\Windows\WindowsColorSystem\Calibration Loader"
)


# Use Backups folder for backup destination
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupDir = Join-Path $rootDirectory "Backups"
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$displayDate = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
$backupFile = "$timestamp-tasks-backup.xml"
$backupPath = Join-Path $backupDir $backupFile

# Ensure Backups directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Counters
$disabled = 0
$notFound = 0
$failed = 0
$totalTasks = $taskIdentifiers.Count

# Header
Write-Host ""
Write-Host "Starting optimization..." -ForegroundColor Cyan
Write-Host ""
Write-Host "[OPTIMIZE] DCS-Max: Scheduled Tasks Optimization" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[DATE]   Optimization Date: $displayDate" -ForegroundColor Gray
Write-Host ""
Write-Host "[FILE]   Backup file: $backupPath" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   Processing $totalTasks scheduled tasks" -ForegroundColor Gray
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Backup current states to array (for XML export)
$backup = @()

Write-Host ""
Write-Host "[OPTIMIZE] Disabling scheduled tasks..." -ForegroundColor Yellow
Write-Host ""

foreach ($fullId in $taskIdentifiers) {
    $lastSlashIndex = $fullId.LastIndexOf('\')
    $taskPath = if ($lastSlashIndex -ge 0) { $fullId.Substring(0, $lastSlashIndex + 1) } else { '\' }
    $taskName = if ($lastSlashIndex -ge 0) { $fullId.Substring($lastSlashIndex + 1) } else { $fullId }

    $taskObj = $null
    try {
        $taskObj = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
        $backup += $taskObj
    } catch {
        Write-Host "[SKIP]   $taskName (not found)" -ForegroundColor DarkGray
        $notFound++
        continue
    }

    if ($taskObj) {
        try {
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
            Write-Host "[OK]     $taskName -> Disabled" -ForegroundColor Green
            $disabled++
        } catch {
            $errMsg = $_.Exception.Message.Trim()
            Write-Host "[FAIL]   $taskName - $errMsg" -ForegroundColor Red
            $failed++
        }
    }
}

# Save backup to XML (for compatibility with restore script)
if ($backup.Count -gt 0) {
    $backup | Export-Clixml $backupPath
    Write-Host ""
    Write-Host "[OK]     Backup saved with $($backup.Count) tasks" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[SUMMARY] Optimization Summary:" -ForegroundColor Cyan
Write-Host "[OK]     Disabled: $disabled" -ForegroundColor Green
Write-Host "[SKIP]   Not found: $notFound" -ForegroundColor DarkGray
Write-Host "[FAIL]   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "DarkGray" })
Write-Host ""
Write-Host "[INFO]   Restart your PC for all changes to take effect." -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO]   To restore, run:" -ForegroundColor Gray
Write-Host "         .\1-Backup-Restore\1.2.3-tasks-restore.ps1 -XmlFile `"$backupFile`"" -ForegroundColor Gray
Write-Host ""
Write-Host "[OK]     Scheduled tasks optimization completed!" -ForegroundColor Green
Write-Host ""

if ($failed -eq 0) {
    Write-Host "[SUCCESS] Optimization completed successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Optimization completed with $failed errors" -ForegroundColor Yellow
}
Write-Host ""

if (-not $NoPause) { Pause }