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

# Use Backups folder for backup destination
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDir

# Load config parser and get optimization settings
$configParserPath = Join-Path $rootDirectory "Assets\config-parser.ps1"
if (Test-Path $configParserPath) {
    . $configParserPath
    $optimizationConfig = Get-OptimizationConfig
} else {
    $optimizationConfig = @{}
}

# Helper function to check if optimization is enabled
function Test-OptEnabled {
    param([string]$Id)
    if ($optimizationConfig.Count -eq 0) { return $true }
    if (-not $optimizationConfig.ContainsKey($Id)) { return $true }
    return $optimizationConfig[$Id]
}

# List of all tasks to disable with IDs for config-based filtering
$taskItems = @(
    # Browser Updates
    @{Id="T001"; Path="\MicrosoftEdgeUpdateTaskMachineCore{39097A80-6523-43D6-BACB-628BA6DD09F0}"},
    @{Id="T002"; Path="\MicrosoftEdgeUpdateTaskMachineUA{2A4AAE6C-2313-4523-AC90-9B058AA03A49}"},
    @{Id="T003"; Path="\GoogleSystem\GoogleUpdater\GoogleUpdaterTaskSystem142.0.7416.0{54C60EF4-20E4-4CAB-BCAB-B720B2B1352D}"},
    
    # .NET Framework
    @{Id="T004"; Path="\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 Critical"},
    @{Id="T005"; Path="\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 64 Critical"},
    @{Id="T006"; Path="\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319"},
    @{Id="T007"; Path="\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319 64"},
    
    # Account & Recovery
    @{Id="T008"; Path="\Microsoft\Windows\AccountHealth\RecoverabilityToastTask"},
    
    # Active Directory
    @{Id="T009"; Path="\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Automated)"},
    @{Id="T010"; Path="\Microsoft\Windows\Active Directory Rights Management Services Client\AD RMS Rights Policy Template Management (Manual)"},
    
    # App Experience
    @{Id="T011"; Path="\Microsoft\Windows\AppID\EDP Policy Manager"},
    @{Id="T012"; Path="\Microsoft\Windows\AppID\PolicyConverter"},
    @{Id="T013"; Path="\Microsoft\Windows\Application Experience\MareBackup"},
    @{Id="T014"; Path="\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"},
    @{Id="T015"; Path="\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp"},
    @{Id="T016"; Path="\Microsoft\Windows\Application Experience\StartupAppTask"},
    @{Id="T017"; Path="\Microsoft\Windows\Application Experience\PcaPatchDbTask"},
    @{Id="T018"; Path="\Microsoft\Windows\Application Experience\SdbinstMergeDbTask"},
    
    # Application Data
    @{Id="T019"; Path="\Microsoft\Windows\ApplicationData\appuriverifierdaily"},
    @{Id="T020"; Path="\Microsoft\Windows\ApplicationData\appuriverifierinstall"},
    @{Id="T021"; Path="\Microsoft\Windows\ApplicationData\CleanupTemporaryState"},
    @{Id="T022"; Path="\Microsoft\Windows\ApplicationData\DsSvcCleanup"},
    
    # App List Backup
    @{Id="T023"; Path="\Microsoft\Windows\AppListBackup\Backup"},
    @{Id="T024"; Path="\Microsoft\Windows\AppListBackup\BackupNonMaintenance"},
    
    # App Deployment
    @{Id="T025"; Path="\Microsoft\Windows\AppxDeploymentClient\Pre-staged app cleanup"},
    @{Id="T026"; Path="\Microsoft\Windows\AppxDeploymentClient\UCPD velocity"},
    
    # System Maintenance
    @{Id="T027"; Path="\Microsoft\Windows\Autochk\Proxy"},
    @{Id="T028"; Path="\Microsoft\Windows\BitLocker\BitLocker Encrypt All Drives"},
    @{Id="T029"; Path="\Microsoft\Windows\BitLocker\BitLocker MDM policy Refresh"},
    @{Id="T030"; Path="\Microsoft\Windows\Bluetooth\UninstallDeviceTask"},
    @{Id="T031"; Path="\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"},
    @{Id="T032"; Path="\Microsoft\Windows\capabilityaccessmanager\maintenancetasks"},
    
    # User Profile
    @{Id="T033"; Path="\Microsoft\Windows\User Profile Service\HiveUploadTask"},
    
    # Windows Update
    @{Id="T034"; Path="\Microsoft\Windows\WaaSMedic\PerformRemediation"},
    @{Id="T035"; Path="\Microsoft\Windows\WindowsUpdate\Refresh Group Policy Cache"},
    @{Id="T036"; Path="\Microsoft\Windows\WindowsUpdate\Scheduled Start"},
    @{Id="T037"; Path="\PauseWindowsUpdate"},
    
    # Network & Wireless
    @{Id="T038"; Path="\Microsoft\Windows\WCM\WiFiTask"},
    @{Id="T039"; Path="\Microsoft\Windows\WlanSvc\CDSSync"},
    @{Id="T040"; Path="\Microsoft\Windows\WlanSvc\MoProfileManagement"},
    @{Id="T041"; Path="\Microsoft\Windows\WwanSvc\NotificationTask"},
    @{Id="T042"; Path="\Microsoft\Windows\WwanSvc\OobeDiscovery"},
    
    # Windows Defender
    @{Id="T043"; Path="\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance"},
    @{Id="T044"; Path="\Microsoft\Windows\Windows Defender\Windows Defender Cleanup"},
    @{Id="T045"; Path="\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan"},
    @{Id="T046"; Path="\Microsoft\Windows\Windows Defender\Windows Defender Verification"},
    
    # Error Reporting
    @{Id="T047"; Path="\Microsoft\Windows\Windows Error Reporting\QueueReporting"},
    
    # Windows Filtering Platform
    @{Id="T048"; Path="\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange"},
    
    # Windows AI
    @{Id="T049"; Path="\Microsoft\Windows\WindowsAI\Recall\InitialConfiguration"},
    @{Id="T050"; Path="\Microsoft\Windows\WindowsAI\Recall\PolicyConfiguration"},
    
    # WIM & WOF
    @{Id="T051"; Path="\Microsoft\Windows\WOF\WIM-Hash-Management"},
    @{Id="T052"; Path="\Microsoft\Windows\WOF\WIM-Hash-Validation"},
    
    # Work Folders
    @{Id="T053"; Path="\Microsoft\Windows\Work Folders\Work Folders Logon Synchronization"},
    @{Id="T054"; Path="\Microsoft\Windows\Work Folders\Work Folders Maintenance Work"},
    
    # Workplace Join
    @{Id="T055"; Path="\Microsoft\Windows\Workplace Join\Automatic-Device-Join"},
    @{Id="T056"; Path="\Microsoft\Windows\Workplace Join\Device-Sync"},
    @{Id="T057"; Path="\Microsoft\Windows\Workplace Join\Recovery-Check"},
    
    # Xbox
    @{Id="T058"; Path="\Microsoft\XblGameSave\XblGameSaveTask"},
    
    # Color Calibration
    @{Id="T059"; Path="\Microsoft\Windows\WindowsColorSystem\Calibration Loader"}
)


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
$skipped = 0
$failed = 0
$totalTasks = $taskItems.Count

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

# Count enabled optimizations
$enabledCount = ($taskItems | Where-Object { Test-OptEnabled $_.Id }).Count
Write-Host "[INFO]   Processing $enabledCount of $totalTasks scheduled tasks" -ForegroundColor Gray
if ($enabledCount -lt $totalTasks) {
    Write-Host "[INFO]   ($($totalTasks - $enabledCount) tasks disabled in config)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

# Backup current states to array (for XML export)
$backup = @()

Write-Host ""
Write-Host "[OPTIMIZE] Disabling scheduled tasks..." -ForegroundColor Yellow
Write-Host ""

foreach ($task in $taskItems) {
    # Check if this optimization is enabled in config
    if (-not (Test-OptEnabled $task.Id)) {
        $taskName = $task.Path.Split('\')[-1]
        Write-Host "[SKIP]   $taskName (disabled in config)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    $fullId = $task.Path
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
Write-Host "[SKIP]   Disabled in config: $skipped" -ForegroundColor DarkGray
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