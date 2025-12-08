# Multi-Headset VR Support - Quick Start Guide

## 🚀 For Users

### First Time Setup (5 minutes)

#### Step 1: Install Your VR Software
Choose one (only one can be installed):
- **Meta Quest**: Download from [Meta website](https://www.meta.com/quest/quest-3/)
- **HTC Vive**: Install via Steam (search "SteamVR")
- **Pimax**: Download from [Pimax website](https://www.pimax.com/)

#### Step 2: Connect Your Headset
- **Meta Quest USB Link**: Connect via USB-C cable
- **Meta Quest Airlink**: Same WiFi network as PC
- **HTC Vive**: Plug in all cables
- **Pimax**: Follow Pimax setup guide

#### Step 3: Launch DCS-Max
1. Open Performance Testing tab
2. **Enable VR** toggle
3. VR Hardware should show **"Auto-detect"** ✓

#### Step 4: Calibrate (1-time per system)
1. Click **"Calibration Wizard"** button
2. Follow the wizard (2-3 simple steps)
3. Click **"Apply"** to save timing

**Done!** Your system is ready for benchmarking.

---

## 🔧 Troubleshooting

### "No VR headset detected"
1. Verify your VR software is **fully installed**
2. Restart DCS-Max app
3. Try selecting headset **manually** from dropdown

### Meta Quest "not connected"
1. Connect via USB-C cable
2. Power on the headset
3. Allow USB permission on headset
4. Restart DCS-Max

### HTC Vive not detected
1. Install **SteamVR** via Steam
2. Ensure headset is connected
3. Launch SteamVR once to initialize
4. Restart DCS-Max

### Benchmark timing out
1. Open Calibration Wizard
2. Let it time the VR startup
3. Add 5-10 seconds to timing
4. Try again

---

## 📋 For Developers

### Module Locations

```
DCS-Max/
├── lib/
│   └── VRHeadsetConfig.ps1          (PowerShell module - detection & backup)
├── 4-Performance-Testing/
│   ├── VRHardwareManager.ahk        (AutoHotkey module - startup & control)
│   ├── 4.1.2-dcs-testing-automation.ahk  (Updated to use modules)
│   └── testing-configuration.json   (Updated schema)
├── 1-Backup-Restore/
│   ├── 1.4.1-dcs-backup.ps1        (Updated - conditional VR backup)
│   └── 1.4.2-dcs-restore.ps1       (Compatible)
└── ui-app/src/components/
    ├── PerformanceTesting.jsx       (Updated UI - auto-detect)
    └── TestConfigEditor.jsx         (Updated dropdown)
```

### Key Integration Points

#### 1. PowerShell Module (VRHeadsetConfig.ps1)
```powershell
# Import in backup scripts
. (Join-Path $RootDir "lib\VRHeadsetConfig.ps1")

# Use functions
$installedHeadsets = Detect-InstalledHeadsets
$vrPath = Get-HeadsetPath "MetaQuest"
$backupGroups = Get-VRBackupGroups
```

#### 2. AutoHotkey Module (VRHardwareManager.ahk)
```autohotkey
; Include in main automation script
#Include "VRHardwareManager.ahk"

; Use functions
hardware := DetectInstalledHeadset()
StartVRHardware(hardware, exePath)
isRunning := CheckVRRunning(hardware)
StopVRHardware(hardware)
```

#### 3. Configuration (testing-configuration.json)
```json
{
  "vr": {
    "hardware": "auto"
  },
  "paths": {
    "metaquestLink": "auto",
    "steamVR": "auto",
    "pimax": "auto"
  }
}
```

#### 4. React Components
```jsx
// Auto-detect on startup
const detected = await window.dcsMax.detectInstalledHeadset();

// Launch VR software
await window.dcsMax.launchVRSoftware(hardware, pathOrAuto);

// Check connection (Meta Quest specific)
const connected = await window.dcsMax.checkMetaQuestConnection?.();
```

### Adding New Headset Support

To add support for a new VR headset (e.g., PlayStation VR2):

**Step 1: PowerShell Module** (`lib/VRHeadsetConfig.ps1`)
```powershell
function Test-PSVR2Installed {
    # Check registry or common paths
    # Return $true if found
}

function Get-PSVR2Path {
    # Return path to executable
    return $path
}

# Add to Detect-InstalledHeadsets()
if (Test-PSVR2Installed) {
    $installed += "PSVR2"
}

# Add to Get-HeadsetPath()
'PSVR2' { return Get-PSVR2Path }

# Add backup group to Get-VRBackupGroups()
@{
    Label = "PlayStation VR2"
    Enabled = { Test-Path "$settingsPath\..." }
    Files = @( "$settingsPath\..." )
}
```

**Step 2: AutoHotkey Module** (`VRHardwareManager.ahk`)
```autohotkey
GetPSVR2Path() {
    ; Return path to executable
    return path
}

StartPSVR2(exePath) {
    Run(exePath)
    return true
}

// Add to GetHeadsetPath()
case "PSVR2":
    return GetPSVR2Path()

// Add to StartVRHardware()
case "PSVR2":
    return StartPSVR2(exePath)

// Add to CheckVRRunning()
case "PSVR2":
    return WinExist("ahk_exe PSVR2Process.exe") > 0
```

**Step 3: Configuration** (`testing-configuration.json`)
```json
"paths": {
    "psvr2": "auto"
}
```

**Step 4: UI Components**
```jsx
<option value="PSVR2">PlayStation VR2</option>
```

---

## 📚 Documentation Files

- **VR_HEADSET_IMPLEMENTATION.md** - Complete technical reference
- **CONFIG_SCHEMA_REFERENCE.md** - Configuration schema & validation
- **IMPLEMENTATION_SUMMARY.md** - What was implemented and why

---

## 🎯 Architecture Overview

```
User selects VR hardware (auto-detect or manual)
    ↓
AutoHotkey VRHardwareManager detects/resolves paths
    ↓
PowerShell module confirms paths via registry
    ↓
VR software launched (Meta Quest, HTC Vive, or Pimax)
    ↓
Benchmark runs with CapFrameX recording
    ↓
Results collected and analyzed
```

### Key Design Principles

1. **Auto-Detection**: System finds VR software automatically
2. **Single Headset**: Only one headset type can be installed
3. **Portable Paths**: Registry + environment variables for any Windows setup
4. **Unified Interface**: Same startup/control code for all headsets
5. **Clear Errors**: Helpful messages if something goes wrong
6. **Backward Compatible**: Existing Pimax configs still work

---

## 🧪 Testing Checklist

Before deployment, verify:

- [ ] Meta Quest auto-detection works (with USB connection)
- [ ] HTC Vive auto-detection works (with Steam installed)
- [ ] Pimax auto-detection works (with Pimax software)
- [ ] Manual selection works for all three headsets
- [ ] Calibration wizard completes successfully
- [ ] Benchmark runs through full cycle
- [ ] Settings backup includes VR headset files
- [ ] Error messages are clear and helpful
- [ ] UI dropdown shows correct options (no "future" labels)
- [ ] Config schema validates correctly

---

## 📞 Support

### User Issues
1. Check troubleshooting section above
2. Verify VR software is fully installed
3. Try manual headset selection from dropdown
4. Check Windows registry for installation keys

### Developer Issues
1. Review VR_HEADSET_IMPLEMENTATION.md
2. Check function signatures in PowerShell/AutoHotkey modules
3. Verify IPC handlers in Electron main process
4. Test with actual headset hardware

---

## Version Info

- **DCS-Max**: v2.0.0+ (Multi-headset support)
- **Schema**: v2.0.0
- **AutoHotkey**: v2.0+
- **PowerShell**: 5.1+
- **Supported Headsets**: Meta Quest, HTC Vive, Pimax

---

## Quick Links

- [Full VR Implementation Guide](VR_HEADSET_IMPLEMENTATION.md)
- [Configuration Schema Reference](CONFIG_SCHEMA_REFERENCE.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
- [Main README](README.md)

---

**Ready to benchmark with your VR headset!** 🎮🥽
