
# DCS-Max Troubleshooting Guide


## 🚨 Emergency Thrust Recovery

### Quick System Restore
If DCS-Max optimizations cause system instability:

```powershell
# 1. Boot to Safe Mode (if needed)
# 2. Open PowerShell as Administrator

cd "C:\Path\To\DCS-Max"


# 4. Run restore scripts in reverse order
.\1-Backup-Restore\1.4.2-dcs-restore.ps1
.\1-Backup-Restore\1.3.2-services-restore.ps1
.\1-Backup-Restore\1.2.3-tasks-restore.ps1
.\1-Backup-Restore\1.1.3-registry-restore.reg





# 5. Restart system
Restart-Computer
```

### System Restore Point Recovery
```powershell
# List available restore points
Get-ComputerRestorePoint


# Restore to point before optimization
Restore-Computer -RestorePoint (Get-ComputerRestorePoint | Select-Object -First 1).SequenceNumber
```


## ⚠️ Installation Issues & Fast Fixes


### PowerShell Execution Policy Errors

#### Problem
```
File cannot be loaded because running scripts is disabled on this system.
```

#### Solutions
```powershell
# Temporary fix (current session only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Permanent fix (recommended)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# Verify policy
Get-ExecutionPolicy -List
```

#### Alternative Method
```powershell
# Run scripts with bypass flag
powershell.exe -ExecutionPolicy Bypass -File ".\script-name.ps1"
```


### Registry Files Won't Apply

#### Problem
- Double-clicking `.reg` files shows errors
- UAC prompts appear but changes don't apply
- "Registry editing has been disabled" error

#### Solutions

**Method 1: Right-click Context Menu**
- Right-click the `.reg` file and select "Merge"
- Confirm UAC prompts
- Restart if prompted

**Method 2: Manual Import**
```powershell
# Use reg command
reg import ".\5.Optimization\5.1.2-registry-optimize.reg"
```

**Method 3: PowerShell Registry Editing**
```powershell
# Example: Set DCS priority manually
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DCS.exe"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force }
Set-ItemProperty -Path $regPath -Name "CpuPriorityClass" -Value 3 -Type DWord
```


### Service/Task Restore Issues

#### Problem: Need to Quickly Restore Services and Tasks

#### Solutions
```powershell
# Services restore
.\5.Optimization\5.3.3-services-restore.ps1

# Tasks restore
.\5.Optimization\5.2.3-tasks-restore.ps1

# Verify restoration
Get-Service | Where-Object {$_.StartType -eq 'Disabled'} | Select Name, DisplayName
Get-ScheduledTask | Where-Object {$_.State -eq 'Disabled'} | Select TaskName, State
```

#### Problem: Restore Scripts Not Found
```powershell
# If restore scripts are missing, check backup files exist:
Get-ChildItem ".\5.Optimization\" -Filter "*backup*"

# Manually restore critical services
$criticalServices = @('AudioSrv', 'Dhcp', 'Dnscache', 'EventSystem', 'RpcSs')
foreach ($service in $criticalServices) {
    Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name $service -ErrorAction SilentlyContinue
}
```


## ❌ Common System Issues & Solutions


### 1. Windows Services Issues

#### Problem: Critical Service Accidentally Disabled

**Symptoms:**
- No audio in Windows/DCS
- Network connectivity issues
- System instability
- Windows features not working

#### Solution: Restore Specific Services
```powershell
# Restore audio services
Set-Service -Name "AudioSrv" -StartupType Automatic
Set-Service -Name "AudioEndpointBuilder" -StartupType Automatic
Start-Service -Name "AudioSrv"
Start-Service -Name "AudioEndpointBuilder"

# Restore networking services
Set-Service -Name "Dhcp" -StartupType Automatic
Set-Service -Name "Dnscache" -StartupType Automatic
Start-Service -Name "Dhcp"
Start-Service -Name "Dnscache"

# Restore all services (nuclear option)
.\5.Optimization\5.3.3-services-restore.ps1
```

#### Problem: Service Won't Start After Optimization

**Check Dependencies:**
```powershell
# View service dependencies
Get-Service -Name "ServiceName" | Select-Object -ExpandProperty ServicesDependedOn

# Start dependent services first
$service = Get-Service -Name "YourService"
$service.ServicesDependedOn | Start-Service
Start-Service -Name "YourService"
```


### 2. Scheduled Tasks Problems

#### Problem: Important Task Accidentally Disabled

**Common Critical Tasks:**
- Windows Update
- Security scans
- Backup tasks

#### Solution: Re-enable Specific Tasks
```powershell
# Re-enable Windows Update
Enable-ScheduledTask -TaskName "\Microsoft\Windows\WindowsUpdate\Automatic App Update"

# Re-enable Windows Defender
Enable-ScheduledTask -TaskName "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan"

# Restore all tasks
.\5.Optimization\5.2.3-tasks-restore.ps1
```

#### Problem: Task Scheduler Service Disabled
```powershell
# Check Task Scheduler service
Get-Service -Name "Schedule"

# Start if stopped
Set-Service -Name "Schedule" -StartupType Automatic
Start-Service -Name "Schedule"
```


### 3. DCS Performance Degraded After Optimization

#### Problem: DCS Runs Worse Than Before

**Immediate Checks:**
```powershell
# 1. Verify DCS process priority
Get-WmiObject Win32_Process -Filter "Name='DCS.exe'" | Select-Object Name, Priority

# 2. Check available memory
Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory

# 3. Verify GPU driver status
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion, Status
```

#### Solutions

**Step 1: Restore DCS Configuration**
```powershell
.\1-Backup-restore\1.4.2-dcs-restore.ps1
```

**Step 2: Check Graphics Settings**
- Launch DCS
- Go to Options → Graphics
- Reset to default settings
- Apply changes and restart DCS

**Step 3: Verify VR Settings (if applicable)**
```lua
-- Check options.lua for VR settings
-- Located at: %USERPROFILE%\Saved Games\DCS\Config\options.lua

-- Common problematic settings:
["VR_pixel_density"] = 1.0,  -- If > 1.5, reduce
["VR_msaa"] = 0,             -- Should be 0 for performance
```


### 4. System Boot Issues

#### Problem: Windows Won't Boot After Optimization

**Safe Mode Recovery:**
1. Boot to Safe Mode (F8 or Shift+Restart)
2. Open Command Prompt as Administrator
3. Run restore commands:

```cmd

cd /d "C:\DCS-Max\5.Optimization"


# Import registry restore
reg import "5.1.3-registry-restore.reg"

# Use sfc to check system files
sfc /scannow

# Restart normally
shutdown /r /t 0
```

#### Problem: Boot Loops or BSOD

**Recovery Steps:**
1. Boot from Windows installation media
2. Select "Repair your computer"
3. Choose "System Restore"
4. Select restore point created before optimization
5. Complete restoration process

### 5. Network Connectivity Issues

#### Problem: Internet/Network Not Working

**Quick Fix:**
```powershell
# Reset network settings
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
ipconfig /release
ipconfig /renew

# Restart network services
Restart-Service -Name "Dhcp"
Restart-Service -Name "Dnscache"
```

**Service Check:**
```powershell
# Verify critical network services are running
$NetworkServices = @('Dhcp', 'Dnscache', 'LanmanServer', 'LanmanWorkstation')
foreach ($Service in $NetworkServices) {
    $Status = Get-Service -Name $Service
    Write-Host "$Service : $($Status.Status)"
    if ($Status.Status -ne 'Running') {
        Start-Service -Name $Service
    }
}
```


## 🔧 Advanced Troubleshooting: Regain Control

### System Performance Analysis

#### High CPU Usage After Optimization
```powershell
# Identify high CPU processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Check for runaway services
Get-WmiObject Win32_Service | Where-Object {$_.State -eq "Running"} | 
    Sort-Object ProcessId | Select-Object Name, ProcessId, StartMode
```

#### Memory Issues
```powershell
# Check memory usage by process
Get-Process | Sort-Object WorkingSet -Descending | 
    Select-Object Name, @{N='Memory(MB)';E={[math]::Round($_.WorkingSet/1MB,2)}} | 
    Select-Object -First 10

# Check for memory leaks
Get-Counter "\Process(*)\Private Bytes" -SampleInterval 5 -MaxSamples 12
```


### DCS-Specific Debugging

#### DCS Won't Start
```powershell
# Check DCS process priority setting
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DCS.exe"
Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue

# Reset DCS registry entry
Remove-Item -Path $regPath -Force -ErrorAction SilentlyContinue
```

#### VR Performance Issues
```powershell
# Check VR-related services
$VRServices = @('SensorDataService', 'SensrSvc')
foreach ($Service in $VRServices) {
    try {
        $Status = Get-Service -Name $Service -ErrorAction Stop
        Write-Host "$Service : $($Status.Status) - $($Status.StartType)"
    }
    catch {
        Write-Host "$Service : Not Found"
    }
}
```

### Logging and Diagnostics

#### Enable Detailed Logging
```powershell
# Create log directory if it doesn't exist
$LogDir = ".\Logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir }

# Enable PowerShell transcript logging
Start-Transcript -Path "$LogDir\troubleshooting-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Your troubleshooting commands here...

Stop-Transcript
```

#### System Event Logs
```powershell
# Check for system errors
Get-WinEvent -LogName System -MaxEvents 50 | 
    Where-Object {$_.LevelDisplayName -eq "Error"} |
    Select-Object TimeCreated, Id, LevelDisplayName, Message

# Check application errors
Get-WinEvent -LogName Application -MaxEvents 50 |
    Where-Object {$_.LevelDisplayName -eq "Error" -and $_.ProviderName -like "*DCS*"}
```


## 📞 Getting Help


### Before Seeking Support

1. **Create System Report**
```powershell
# Generate comprehensive system info
Get-ComputerInfo | Out-File "SystemInfo-$(Get-Date -Format 'yyyyMMdd').txt"

# Export installed services
Get-Service | Export-Csv "Services-$(Get-Date -Format 'yyyyMMdd').csv"

# Export scheduled tasks
Get-ScheduledTask | Export-Csv "Tasks-$(Get-Date -Format 'yyyyMMdd').csv"
```

2. **Document the Issue**
- What optimization step caused the problem?
- What error messages appeared?
- When did the issue start?
- What troubleshooting steps have you tried?

3. **Gather Performance Data**
```powershell
# System performance snapshot
Get-Counter "\Processor(_Total)\% Processor Time","\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 10
```


### Support Resources

1. **Documentation**: Review all `.md` files in `docs/` folder
2. **Chat Transcripts**: Check `docs/Chat-Transcripts/` for development discussions
3. **Backup Files**: All scripts create backup files for restoration
4. **System Restore**: Use Windows System Restore as last resort


### Prevention Tips for Smooth Thrust


1. **Always Create Restore Point**: Before running any optimization
2. **Test in Stages**: Don’t run all optimizations at once
3. **Monitor Performance**: Check system performance after each change
4. **Keep Backups**: Maintain multiple backup copies
5. **Document Changes**: Keep notes on what optimizations you applied


---
*For installation, see `1-README.md`*
*For performance, see `3-performance-guide.md`*