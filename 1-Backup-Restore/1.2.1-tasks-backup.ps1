# HARPIA DCS Task Backup - DCS OPTIMIZED TASKS ONLY (Win11 25H2, Oct 2025)
# Backs up DCS-optimized Scheduled Tasks (state, triggers, actions) to XML.
# RESTORE: Import-Clixml + Enable-ScheduledTask
# Run AS ADMIN. Path: Auto-saves to script folder.


# Use Backups folder for backup destination
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir
$backupDir = Join-Path $rootDirectory "Backups"

# Ensure Backups directory exists
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}


# 1. BACKUP DCS-OPTIMIZED TASKS
$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$fullBackupPath = Join-Path $backupDir ("$timestamp-tasks-backup.xml")

$tasksToOptmize = @(
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

$ourTasks = @()
foreach ($fullId in $tasksToOptmize) {
    $lastSlashIndex = $fullId.LastIndexOf('\')
    $taskPath = if ($lastSlashIndex -ge 0) { $fullId.Substring(0, $lastSlashIndex + 1) } else { '\' }
    $taskName = if ($lastSlashIndex -ge 0) { $fullId.Substring($lastSlashIndex + 1) } else { $fullId }

    try {
        $task = Get-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
        $ourTasks += $task
        Write-Host "BACKED UP: $fullId" -ForegroundColor Green
    } catch {
        Write-Host "NOT FOUND: $fullId" -ForegroundColor Yellow
    }
}

if ($ourTasks.Count -gt 0) {
    $ourTasks | Export-Clixml $fullBackupPath
    Write-Host "`nDCS TASKS BACKUP CREATED!`nFile: $(Split-Path $fullBackupPath -Leaf)`nLocation: $backupDir`nRestore anytime with restore script.`n" -ForegroundColor Green
} else {
    Write-Host "No DCS-optimized tasks found to backup." -ForegroundColor Yellow
}

Pause