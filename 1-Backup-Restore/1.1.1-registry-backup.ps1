# Registry Backup Script for DCS Life Saver
# Creates backup of specific registry values before optimization
# Optimized version with no code duplication

# Get timestamp for backup filename
$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$backupFile = "$timestamp-registry-backup.reg"
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDirectory = Split-Path -Parent $scriptDirectory
$backupsDirectory = Join-Path $rootDirectory "Backups"
$fullBackupPath = Join-Path $backupsDirectory $backupFile

# Ensure Backups directory exists
if (-not (Test-Path $backupsDirectory)) {
    New-Item -ItemType Directory -Path $backupsDirectory -Force | Out-Null
}

Write-Host "CREATING REGISTRY BACKUP" -ForegroundColor Green

# Create .reg file header
$regContent = @"
Windows Registry Editor Version 5.00

"@

# Function to backup a registry value
function Backup-RegistryValue {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [string]$Description
    )
    
    try {
        # Convert to PowerShell path format
        $psPath = $KeyPath -replace "HKEY_LOCAL_MACHINE", "HKLM:" -replace "HKEY_CURRENT_USER", "HKCU:"
        
        # Get current value
        $currentValue = Get-ItemProperty -Path $psPath -Name $ValueName -ErrorAction Stop
        $value = $currentValue.$ValueName
        
        # Format value based on type
        if ($value -is [int] -or $value -is [uint32]) {
            $hexValue = "{0:x8}" -f $value
            $regValue = "`"$ValueName`"=dword:$hexValue"
            $displayValue = $hexValue
        } else {
            # String value
            $regValue = "`"$ValueName`"=`"$value`""
            $displayValue = $value
        }
        
        # Add to reg content
        $script:regContent += @"
[$KeyPath]
$regValue

"@
        
        Write-Host "Backed up: $Description = $displayValue" -ForegroundColor Yellow
        
    } catch {
        Write-Host "Skipped: $Description (not currently configured)" -ForegroundColor Gray
    }
}

# Registry settings to backup
$registrySettings = @(
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
        ValueName = "Attributes"
        Description = "CPU Core Parking"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DCS.exe"
        ValueName = "CpuPriorityClass"
        Description = "CPU Priority Class"
    },
    @{
        KeyPath = "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        ValueName = "AppCaptureEnabled"
        Description = "GameDVR"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D"
        ValueName = "MaxPreRenderedFrames"
        Description = "MaxPreRenderedFrames"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        ValueName = "NetworkThrottlingIndex"
        Description = "NetworkThrottlingIndex"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        ValueName = "SystemResponsiveness"
        Description = "SystemResponsiveness"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power"
        ValueName = "PowerThrottlingOff"
        Description = "PowerThrottlingOff"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl"
        ValueName = "Win32PrioritySeparation"
        Description = "Win32PrioritySeparation"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "Affinity"
        Description = "SystemProfileGames - Affinity"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "BackgroundOnly"
        Description = "SystemProfileGames - BackgroundOnly"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "GPU Priority"
        Description = "SystemProfileGames - GPU Priority"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "Priority"
        Description = "SystemProfileGames - Priority"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "Scheduling Category"
        Description = "SystemProfileGames - Scheduling Category"
    },
    @{
        KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        ValueName = "SFIO Priority"
        Description = "SystemProfileGames - SFIO Priority"
    }
)

# Backup all registry values
foreach ($setting in $registrySettings) {
    Backup-RegistryValue -KeyPath $setting.KeyPath -ValueName $setting.ValueName -Description $setting.Description
}

# Write backup file
$regContent | Out-File -FilePath $fullBackupPath -Encoding ASCII

Write-Host "Registry backup completed:"  -ForegroundColor Green
Write-Host "To restore values double click the following restore file:"  
Write-Host $fullBackupPath -ForegroundColor Green
Pause