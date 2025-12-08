# VR Headset Support - Implementation Guide

## Overview

DCS-Max now supports multiple VR headsets with auto-detection and unified configuration:
- **Meta Quest** (USB Link + Airlink)
- **HTC Vive / SteamVR** (including Valve Index)
- **Pimax**

## Architecture

### Components

#### 1. **lib/VRHeadsetConfig.ps1** (PowerShell Module)
Provides VR headset detection and configuration management:
- `Detect-InstalledHeadsets()` - Returns array of installed headsets
- `Get-MetaQuestPath()` - Resolves Meta Quest executable path
- `Get-SteamVRPath()` - Resolves SteamVR installation path
- `Get-PimaxPath()` - Resolves Pimax executable path
- `Get-VRBackupGroups()` - Returns backup configuration for all VR headsets

Uses environment variables and registry queries for maximum portability.

#### 2. **4-Performance-Testing/VRHardwareManager.ahk** (AutoHotkey Module)
Provides VR hardware startup and control:
- `DetectInstalledHeadset()` - Detects first available headset
- `StartVRHardware(hardware, exePath)` - Starts VR software
- `CheckVRRunning(hardware)` - Checks if VR is active
- `StopVRHardware(hardware)` - Cleanly stops VR software
- `CheckMetaQuestConnection()` - Verifies Meta Quest USB connection

#### 3. **Backup/Restore Integration**
Updated `1-Backup-Restore/1.4.1-dcs-backup.ps1` to:
- Import VRHeadsetConfig module
- Auto-detect installed VR headsets
- Conditionally backup only detected headsets' settings

## Configuration

### testing-configuration.json Schema

```json
{
  "configuration": {
    "vr": {
      "enabled": true,
      "hardware": "auto"  // Options: "auto", "MetaQuest", "HTCVive", "Pimax"
    },
    "waitTimes": {
      "vr": 18000,        // Global VR startup timing (milliseconds)
      "missionReady": 35000,
      "missionRestart": 30000
    },
    "paths": {
      "metaquestLink": "auto",  // Auto-detect from registry
      "steamVR": "auto",        // Auto-detect from Steam registry
      "pimax": "auto"           // Auto-detect from Pimax registry
    }
  }
}
```

## Usage

### Automatic Detection

The system automatically detects installed headsets:

1. **On Calibration**: Select "Auto-detect" in VR Hardware dropdown
2. **On Benchmark Start**: System queries registry and Program Files
3. **On Settings Backup**: Only backs up detected headset settings

### Manual Selection

Users can manually select a specific headset:
1. Open Performance Testing tab
2. Enable VR
3. Select from dropdown: "Meta Quest", "HTC Vive", "Pimax"

### Path Resolution Priority

For each headset type:

**Meta Quest:**
1. Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Meta`
2. Standard paths: `C:\Program Files\Meta\MetaQuestLink\MetaQuestLink.exe`

**HTC Vive / SteamVR:**
1. Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam` (InstallPath)
2. Standard path: `C:\Program Files (x86)\Steam\steamapps\common\SteamVR`

**Pimax:**
1. Standard paths: `C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe`
2. Registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Pimax`

## Timing Calibration

Each VR headset requires calibration one time per system:

### Default Timings (Baseline)
- **Meta Quest**: 18,000ms (includes USB handshake + Link client init)
- **HTC Vive**: 15,000ms (SteamVR startup)
- **Pimax**: 15,000ms (Pimax Client startup)

### User Calibration Process

1. Open Performance Testing → Calibration Wizard
2. Select "Auto-detect" or specific headset
3. Follow wizard through 2-3 timing steps:
   - VR Hardware startup time
   - DCS cold start time (shared)
   - DCS mission restart time (shared)
4. Wizard applies 5-second safety buffer automatically

## Settings Backup

### Meta Quest

**Backup Location**: `%APPDATA%\Meta\MetaQuestLink\settings.json`

**Contents:**
- Link settings
- Display preferences
- Guardian boundaries
- Performance settings

### HTC Vive / SteamVR

**Backup Location**: `%ProgramFiles(x86)%\Steam\config\steamvr.vrsettings`

**Contents:**
- SteamVR runtime settings
- Resolution and supersampling
- Performance settings
- Audio configuration

### Pimax

**Backup Locations:**
- `%APPDATA%\Local\Pimax\runtime\profile.json`
- `%APPDATA%\Roaming\PiTool\manifest\PiTool\Common Setting.json`

**Contents:**
- Pimax runtime configuration
- Headset profile settings
- Performance tuning

## Advanced Features

### Meta Quest Airlink Support

Meta Quest users can use:
- **USB Link**: Traditional wired connection (more stable)
- **Airlink**: Wireless connection over local network

The system supports both without manual configuration. The app detects whichever is active.

### Environment Variable Support

Paths support environment variable expansion:
- `%USERPROFILE%` → User home directory
- `%PROGRAMFILES%` → Program Files directory
- `%PROGRAMFILES(X86)%` → Program Files (x86) directory

## Troubleshooting

### "No VR headset detected"

**Solution:** Ensure your headset software is installed:
- Meta Quest: Download from Meta website
- HTC Vive: Install via Steam
- Pimax: Install Pimax software

### Meta Quest connection fails

**Solution:**
1. Connect headset via USB-C
2. Power on the headset
3. Enable USB debugging in Meta Quest settings
4. Allow USB connection permission on headset

### Benchmark hangs on VR startup

**Solution:**
1. Increase `waitTimes.vr` in configuration (add 5000ms)
2. Verify VR software is responding (check taskbar)
3. Restart VR software and try again

## File Locations Reference

### Configuration
- Main config: `4-Performance-Testing/testing-configuration.json`
- PowerShell module: `lib/VRHeadsetConfig.ps1`
- AutoHotkey module: `4-Performance-Testing/VRHardwareManager.ahk`

### Backup/Restore Scripts
- Backup: `1-Backup-Restore/1.4.1-dcs-backup.ps1`
- Restore: `1-Backup-Restore/1.4.2-dcs-restore.ps1`

### Automation
- Main automation: `4-Performance-Testing/4.1.2-dcs-testing-automation.ahk`

## Implementation Details for Developers

### Adding New Headset Support

To add support for a new VR headset (e.g., PlayStation VR2):

1. **PowerShell Module** (`lib/VRHeadsetConfig.ps1`):
   ```powershell
   function Test-PSVR2Installed { ... }
   function Get-PSVR2Path { ... }
   ```

2. **AutoHotkey Manager** (`VRHardwareManager.ahk`):
   ```autohotkey
   case "PSVR2":
       return StartPSVR2(exePath)
   ```

3. **Configuration** (`testing-configuration.json`):
   ```json
   "psvr2": "auto"  // Add to paths
   ```

4. **UI** (React components):
   ```jsx
   <option value="PSVR2">PlayStation VR2</option>
   ```

## Version History

- **v2.0.0**: Multi-headset support with auto-detection
  - Added Meta Quest support
  - Added HTC Vive / SteamVR support
  - Unified VR configuration
  - Global VR timing (not per-headset)
  - Auto-detection on startup
  - Environment variable support for paths
