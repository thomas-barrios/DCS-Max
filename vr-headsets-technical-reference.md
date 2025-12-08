# VR Headsets: Command-Line Executables, Configuration Paths & Settings

Comprehensive technical reference for managing VR headsets via command line and accessing configuration files.

---

## 1. HTC VIVE (Using SteamVR)

### Executables & Command-Line Tools

#### Main SteamVR Executable
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe
```

#### SteamVR Dashboard/Status
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrdashboard.exe
```

#### Room Setup Tool
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\tools\roomsetup\bin\win64\room_setup.exe
```

#### Base Station Manager
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\lighthouse_console.exe
```

#### HTC Vive Console
```
C:\Program Files (x86)\Steam\steamapps\common\HTC Vive Console\HTC Vive Console.exe
```

### Configuration File Locations

#### SteamVR Settings File
```
C:\Program Files (x86)\Steam\config\steamvr.vrsettings
```

#### Chaperone Information
```
C:\Program Files (x86)\Steam\config\chaperone_info.vrchap
```

#### SteamVR Config Directory
```
C:\Program Files (x86)\Steam\config\
```

#### Lighthouse Base Station Data
```
C:\Program Files (x86)\Steam\config\lighthousedb.json
```

### Key Configuration Parameters

The `steamvr.vrsettings` file is JSON format and contains settings such as:
```json
{
  "jsonid": "vrsettings",
  "steamvr": {
    "ipd": 0.0635,
    "forcedDriver": "null",
    "requireHmd": false,
    "displayDebug": false,
    "loglevel": 3,
    "renderTargetMultiplier": 1.0,
    "directMode": true
  },
  "driver_lighthouse": {
    "disableimu": false,
    "usedisambiguation": "tdm",
    "primarybasestation": 0
  }
}
```

### User Settings (Human-Readable)
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\resources\settings\
```

---

## 2. VALVE INDEX (Using SteamVR)

### Executables & Command-Line Tools

All Valve Index headsets use the SteamVR runtime (same as HTC Vive above).

#### Controller Firmware Update Tool
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\tools\controlleroffloader\bin\win64\controller_offloader.exe
```

#### USB Device Info
The Valve Index communicates via USB. You can query device info using:
```powershell
Get-PnpDevice -PresentOnly | Where-Object {$_.Name -match "Index"}
```

### Configuration File Locations

Same as HTC Vive (uses shared SteamVR config):
```
C:\Program Files (x86)\Steam\config\steamvr.vrsettings
```

### Device-Specific Settings
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\tools\perf\
```

---

## 3. META QUEST / OCULUS (PC-Based)

### Executables & Command-Line Tools

#### Meta Horizon Link (PC Client)
```
C:\Program Files\Meta\Horizon\Meta Quest Link\MetaQuestLink.exe
```
Command-line options:
```powershell
MetaQuestLink.exe --help
MetaQuestLink.exe --autostart
MetaQuestLink.exe --server  # Start server mode
```

#### Oculus Desktop App (Legacy)
```
C:\Program Files\Oculus\Support\oculus-runtime\OculusServiceLauncher.exe
```

#### ADB (Android Debug Bridge) - For Meta Quest Device Control
```
C:\Program Files\Oculus\Support\oculus-runtime\platform-tools\adb.exe
```

Common ADB commands:
```powershell
adb connect <quest_ip_address>:5555
adb install -r <app_name>.apk
adb shell am start -n com.app.package/com.app.Activity
adb logcat  # View device logs
adb shell getprop  # Get device properties
```

#### OVRMonitor (Performance Monitoring)
```
C:\Program Files\Oculus\Support\oculus-runtime\OVRMonitor.exe
```

### Configuration File Locations

#### Meta Horizon Link Settings
```
C:\Users\<username>\AppData\Local\Meta\MetaQuestLink\
C:\Users\<username>\AppData\Local\Meta\MetaQuestLink\settings.json
```

#### Oculus Legacy App Data
```
C:\Users\<username>\AppData\Local\Oculus\
C:\Users\<username>\AppData\Roaming\Oculus\
```

#### Device Configuration (on Quest headset via ADB)
```
/sdcard/Oculus/
/data/com.oculus.mxhome/  # Home environment settings
/data/com.oculus.vrshell/  # VR Shell settings
```

### Key Configuration Settings
- Capture frames and performance data
- Eye tracking settings
- Guardian system configuration
- Display refresh rate settings
- Hand tracking configuration

---

## 4. PIMAX

### Executables & Command-Line Tools

#### Pimax Play Software
```
C:\Program Files\PimaxPlay\PimaxPlay.exe
```

#### Pimax Tool (for older models)
```
C:\Program Files\Pimax\Pitool\Pitool.exe
```
Command-line options:
```powershell
Pitool.exe -config  # Open configuration
Pitool.exe -steamvr  # Launch SteamVR
```

#### PiTool Executable (Legacy/8K/5K models)
```
C:\Program Files\Pimax\PiTool\PiTool.exe
```

### Configuration File Locations

#### Pimax Play Settings
```
C:\Users\<username>\AppData\Local\Pimax Play\
C:\Users\<username>\AppData\Local\Pimax Play\settings.ini
```

#### Pimax Tool Config (Legacy)
```
C:\Program Files\Pimax\Pitool\config\
C:\Users\<username>\AppData\Local\Pimax\Pitool\
```

#### Pimax Tracking & Calibration Data
```
C:\Users\<username>\AppData\Local\Pimax\tracking\
```

#### SteamVR Integration (Pimax uses OpenVR/SteamVR)
```
C:\Program Files (x86)\Steam\config\steamvr.vrsettings  # Shared with SteamVR
```

### Configuration Examples
- Field of View (FOV) settings
- Refresh rate configuration (60Hz, 72Hz, 80Hz, 90Hz)
- Brightness and color settings
- Eye tracking calibration
- Base station configuration (for lighthouse models)

---

## 5. HP REVERB G2

### Executables & Command-Line Tools

#### Windows Mixed Reality Portal
```
C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_*\MixedRealityPortal.exe
```

#### Windows Mixed Reality Setup
```
C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_*\MixedRealitySetup.exe
```

#### Speech Recognition & Eye Tracking (if available)
```
C:\Windows\System32\Speech\RecBus\SpeechRuntime.exe
C:\Program Files\HP\HP Reverb G2 Setup\HP Reverb G2 Setup.exe
```

### Configuration File Locations

#### Windows Mixed Reality Settings
```
C:\Users\<username>\AppData\Local\Packages\Microsoft.MixedReality.Portal_8wekyb3d8bbwe\LocalState\
```

#### HP Reverb G2 Specific Configuration
```
C:\Users\<username>\AppData\Local\HP\HP Reverb G2\
C:\ProgramData\HP\HP Reverb G2\
```

#### Windows XR Runtime Configuration
```
C:\Users\<username>\AppData\Local\Packages\Microsoft.MixedReality.Portal_8wekyb3d8bbwe\
```

#### Registry Keys (Windows Mixed Reality)
```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Mixed Reality
HKEY_CURRENT_USER\Software\Microsoft\Windows Mixed Reality
```

To access via PowerShell:
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Mixed Reality"
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows Mixed Reality"
```

### Key Configuration Settings
- Display refresh rate
- Graphics quality settings
- Boundary/play space size
- Audio input/output selection
- Eye tracking calibration
- Hand tracking sensitivity

---

## 6. WINDOWS MIXED REALITY HEADSETS (HP, Lenovo, Asus, Samsung, etc.)

### Executables & Command-Line Tools

#### Windows Mixed Reality Portal
```
C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_*\MixedRealityPortal.exe
```

#### Windows Mixed Reality Setup
```
C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_*\setup.exe
```

#### OpenXR Runtime Manager
```
C:\Program Files\WindowsApps\Microsoft.OpenXR.Service_*\OpenXRService.exe
```

#### Per-Model Setup Tools
- **Lenovo Explorer**: `C:\Program Files\Lenovo\LenovoExplorer\LenovoExplorer.exe`
- **Asus HC102**: Asus Mixed Reality App (via Windows Store)
- **Samsung Odyssey**: Samsung Mixed Reality Portal

### Configuration File Locations

#### Windows Mixed Reality Portal Settings
```
C:\Users\<username>\AppData\Local\Packages\Microsoft.MixedReality.Portal_8wekyb3d8bbwe\LocalState\
C:\Users\<username>\AppData\Local\Packages\Microsoft.MixedReality.Portal_8wekyb3d8bbwe\LocalState\settings.json
```

#### Windows XR Registry Configuration
```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Mixed Reality
HKEY_CURRENT_USER\Software\Microsoft\Windows Mixed Reality
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Holographic
```

Access via PowerShell:
```powershell
# View WMR configuration
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Mixed Reality"
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows Mixed Reality"

# List installed MR apps
Get-AppxPackage | Where-Object {$_.Name -match "MixedReality"}
```

#### OpenXR Settings
```
C:\Users\<username>\AppData\Local\OpenXR\
C:\ProgramData\OpenXR\
```

#### Headset-Specific Configurations
```
C:\Users\<username>\AppData\Local\Packages\[Headset_Package_ID]\LocalState\
```

### Important Registry Keys

**Enable/Disable WMR:**
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Holographic
  Value: "FirstRunSucceeded" (1 = enabled, 0 = disabled)
```

**Tracking Settings:**
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Holographic\Tracking
```

**Display Settings:**
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Holographic\Display
```

**Performance Settings:**
```
HKCU\Software\Microsoft\Windows\CurrentVersion\Holographic\Performance
```

### Key Configuration Settings
- Tracking mode and calibration
- Play space/boundary configuration
- Audio input/output selection
- Display resolution and refresh rate
- Motion controller sensitivity
- Eye tracking (if supported)
- Performance quality levels

---

## COMMON OPENVR/STEAMVR TOOLS & UTILITIES

### OpenVR Documentation & API Reference
- **GitHub**: https://github.com/ValveSoftware/openvr
- **API Documentation**: https://github.com/ValveSoftware/openvr/wiki/API-Documentation
- **Driver Documentation**: https://github.com/ValveSoftware/openvr/wiki/Driver-Documentation

### SteamVR System Paths
```
C:\Program Files (x86)\Steam\steamapps\common\SteamVR\
C:\Program Files (x86)\Steam\config\
```

### Log Files Location
```
C:\Program Files (x86)\Steam\logs\vrserver.txt
C:\Program Files (x86)\Steam\logs\vrdashboard.txt
C:\Users\<username>\AppData\Local\SteamVR\logs\
```

### Accessing SteamVR Console/Debug
1. Press Dashboard button in VR
2. Enable "Developer Show Console"
3. Launch console: `C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrconsole.exe`

---

## PERFORMANCE MONITORING & DIAGNOSTICS

### HMD Status Information
```powershell
# Get connected USB VR devices
Get-PnpDevice -PresentOnly | Where-Object {$_.Name -match "VR|HTC|Valve|Pimax|Index"}

# Get device driver info
Get-PnpDevice -PresentOnly -Class HIDClass | Get-PnpDeviceProperty
```

### SteamVR Performance Overlay
Enable in SteamVR settings to monitor:
- Frame rate (FPS)
- GPU/CPU utilization
- Memory usage
- Frame timing

### Log Monitoring
```powershell
# Monitor SteamVR logs in real-time
Get-Content "C:\Program Files (x86)\Steam\logs\vrserver.txt" -Wait

# Monitor Windows Mixed Reality logs
Get-WinEvent -LogName "Microsoft-Windows-Holographic/Operational"
```

---

## COMMAND-LINE LAUNCH EXAMPLES

### Launch SteamVR Apps
```powershell
# Start SteamVR
& "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe"

# Launch specific app via Steam
& "C:\Program Files (x86)\Steam\steam.exe" -applaunch <AppID>

# Example: Launch Half-Life Alyx
& "C:\Program Files (x86)\Steam\steam.exe" -applaunch 546560
```

### Query Headset Status via SteamVR
```powershell
# Use SteamVR console
$vrconsole = "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrconsole.exe"
& $vrconsole
# Then in console: hmd_status
```

### USB Device Reset (if necessary)
```powershell
# Restart USB root hub to reset devices
$devices = Get-PnpDevice -PresentOnly | Where-Object {$_.Name -match "USB Root Hub"}
foreach ($device in $devices) {
    Disable-PnpDevice -InstanceName $device.InstanceId -Confirm:$false
    Start-Sleep -Seconds 1
    Enable-PnpDevice -InstanceName $device.InstanceId -Confirm:$false
}
```

---

## TROUBLESHOOTING COMMANDS

### Validate SteamVR Installation
```powershell
Test-Path "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\"
Get-ChildItem "C:\Program Files (x86)\Steam\config\steamvr.vrsettings"
```

### Reset SteamVR to Defaults
```powershell
# Backup current config
Copy-Item "C:\Program Files (x86)\Steam\config\steamvr.vrsettings" `
  "C:\Program Files (x86)\Steam\config\steamvr.vrsettings.backup"

# Delete to regenerate on next launch
Remove-Item "C:\Program Files (x86)\Steam\config\steamvr.vrsettings"
```

### Check Windows Mixed Reality Status
```powershell
# Get WMR diagnostic information
Get-WinEvent -LogName "Microsoft-Windows-Holographic/Operational" `
  -MaxEvents 50 | Format-Table TimeCreated, Message -AutoSize
```

### Verify Meta Quest Connection
```powershell
# Test Quest connectivity
adb connect <quest_ip>:5555
adb shell getprop ro.build.version.release  # Get OS version
adb shell getprop ro.product.model  # Get device model
```

---

## NOTES & RECOMMENDATIONS

1. **File Paths**: All paths assume standard Windows installation. Adjust based on your Steam installation location.

2. **Registry Keys**: Windows Mixed Reality settings are stored in registry. Always backup before modifying:
   ```powershell
   reg export "HKEY_CURRENT_USER\Software\Microsoft\Windows Mixed Reality" backup.reg
   ```

3. **Administrator Rights**: Most VR setup and configuration requires administrator privileges.

4. **SteamVR Configuration**: The `steamvr.vrsettings` file is shared across all SteamVR-compatible headsets (HTC Vive, Valve Index, Pimax using SteamVR).

5. **Backup Important Files**: Before modifying configuration files, always create backups:
   ```powershell
   Copy-Item -Path <config_file> -Destination <config_file>.backup
   ```

6. **OpenXR Compatibility**: Windows Mixed Reality uses OpenXR standard. Some VR applications may require OpenXR runtime configuration.

7. **Logs for Debugging**: Always check log files when troubleshooting:
   - SteamVR: `C:\Program Files (x86)\Steam\logs\`
   - Windows MR: Event Viewer → Windows Logs → Applications and Services
   - Meta Quest: ADB logcat output

---

**Last Updated**: December 2025
**Relevant Standards**: OpenXR, OpenVR, Windows Mixed Reality Platform
