# Backup and Disable Windows Scheduled Tasks for DCS Optimization
# Purpose: Backs up current states of specified tasks to JSON, then disables them to minimize background CPU/network usage,
# reducing frame times and stutters in DCS for competitive play (e.g., TACT, SATAL, JustDogFights servers).
# Focus: Efficient, readable code with error handling; assumes run as Administrator.
# Optimizations: Uses arrays/hashtables for fast lookups; processes in bulk; skips non-existent tasks to avoid errors.
# Usage: Run in PowerShell; restore via backup XML using 2.2.3-tasks-restore.ps1.
# Note: These disables are safe/optional for gaming setups without Edge/Google/.NET/UWP dependencies; tested for stability in HARPIA team setups.

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


# Use script folder for backup destination
$backupDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$backupPath = Join-Path $backupDir ("$timestamp-tasks-backup.xml")

# Backup current states to array (for XML export)
$backup = @()

$total = $taskIdentifiers.Count
$idx = 1
foreach ($fullId in $taskIdentifiers) {
    $lastSlashIndex = $fullId.LastIndexOf('\')
    $taskPath = if ($lastSlashIndex -ge 0) { $fullId.Substring(0, $lastSlashIndex + 1) } else { '\' }
    $taskName = if ($lastSlashIndex -ge 0) { $fullId.Substring($lastSlashIndex + 1) } else { $fullId }

    $taskObj = $null
    try {
        $taskObj = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
        $backup += $taskObj
    } catch {
        Write-Host ("[{0}/{1}] Not found: {2}" -f $idx, $total, $fullId) -ForegroundColor Yellow
    }

    if ($taskObj) {
        try {
            Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop | Out-Null
            Write-Host ("[{0}/{1}] Disabled: {2}" -f $idx, $total, $fullId) -ForegroundColor Green
        } catch {
            Write-Host ("[{0}/{1}] Failed: {2} - $($_.Exception.Message)" -f $idx, $total, $fullId) -ForegroundColor Red
        }
    }
    $idx++
}

# Save backup to XML (for compatibility with restore script)
$backup | Export-Clixml $backupPath

Write-Host "`nBackup saved to: $(Split-Path $backupPath -Leaf)" -ForegroundColor Green
Write-Host "Location: $backupDir" -ForegroundColor Green
Write-Host "Optimizations applied; reboot recommended for full effect in DCS sessions." -ForegroundColor White
Write-Host "Restore using 2.2.3-tasks-restore.ps1." -ForegroundColor White
Pause