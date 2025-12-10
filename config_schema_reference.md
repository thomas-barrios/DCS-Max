# DCS-Max Configuration Schema Reference

## testing-configuration.json - Complete Schema

### Root Structure
```json
{
  "version": "2.0.0",
  "description": "DCS-Max Benchmark Testing Configuration",
  "configuration": { ... },
  "testsToRun": [ ... ]
}
```

---

## Configuration Object

### VR Settings
```json
"vr": {
  "enabled": true|false,
  "hardware": "auto|MetaQuest|HTCVive|Pimax"
}
```

**Options:**
- `"enabled"`: boolean - Enable/disable VR for benchmarks
- `"hardware"`: string
  - `"auto"` - Auto-detect installed headset (recommended)
  - `"MetaQuest"` - Force Meta Quest Link
  - `"HTCVive"` - Force HTC Vive / SteamVR
  - `"Pimax"` - Force Pimax

### Wait Times
```json
"waitTimes": {
  "vr": 18000,
  "missionReady": 35000,
  "beforeRecord": 3000,
  "recordLength": 60000,
  "capFrameXWrite": 5000,
  "missionRestart": 30000
}
```

**All times in milliseconds:**
- `"vr"`: Time for VR software to initialize (18000ms = 18s)
  - Meta Quest: 18000-20000ms recommended
  - HTC Vive: 15000-18000ms recommended
  - Pimax: 15000ms recommended
  - **Adjust via Calibration Wizard**

- `"missionReady"`: Time for DCS cold start (35000ms = 35s)
  - Adjust based on your system (SSD vs HDD)
  - Shared across all headsets

- `"missionRestart"`: Time for DCS mission restart (30000ms = 30s)
  - In-game restart via Shift+R
  - Shared across all headsets

- `"beforeRecord"`: Delay before starting CapFrameX recording (3000ms)
  - Allows stabilization between loading and recording

- `"recordLength"`: Duration of each benchmark recording (60000ms = 60s)
  - Set to desired benchmark length

- `"capFrameXWrite"`: Time for CapFrameX to write data (5000ms)
  - Allow time for file I/O

### Paths

#### Auto-Detected Paths
```json
"paths": {
  "metaquestLink": "auto",
  "steamVR": "auto",
  "pimax": "auto"
}
```

Setting to `"auto"` enables automatic detection:
- **metaquestLink**: Queries registry `HKEY_LOCAL_MACHINE\SOFTWARE\Meta`
- **steamVR**: Queries registry `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam`
- **pimax**: Searches `C:\Program Files\Pimax\...`

#### Manual Paths (Optional)
```json
"paths": {
  "metaquestLink": "C:\\Program Files\\Meta\\MetaQuestLink\\MetaQuestLink.exe",
  "steamVR": "C:\\Program Files (x86)\\Steam\\steamapps\\common\\SteamVR",
  "pimax": "C:\\Program Files\\Pimax\\PimaxClient\\pimaxui\\PimaxClient.exe"
}
```

#### Environment Variable Support
Paths support these variables:
- `%USERPROFILE%` - User home directory
- `%PROGRAMFILES%` - Program Files directory
- `%PROGRAMFILES(X86)%` - Program Files (x86) directory
- `%APPDATA%` - AppData directory
- `%LOCALAPPDATA%` - LocalAppData directory

Example:
```json
"savedGamesPath": "%USERPROFILE%\\Saved Games"
```

#### Required Paths (DCS & Tools)
```json
"paths": {
  "savedGamesPath": "%USERPROFILE%\\Saved Games",
  "dcsExe": "C:\\Program Files\\Eagle Dynamics\\DCS World\\bin\\DCS.exe",
  "capframex": "C:\\Program Files (x86)\\CapFrameX\\CapFrameX.exe",
  "capframexFolder": "%USERPROFILE%\\Documents\\CapFrameX\\Captures",
  "notepadpp": "C:\\Program Files\\Notepad++\\notepad++.exe"
}
```

- `"savedGamesPath"`: Windows Saved Games directory (DCS data is in subfolder)
- `"dcsExe"`: DCS World executable
- `"capframex"`: CapFrameX benchmark tool
- `"capframexFolder"`: CapFrameX output directory
- `"notepadpp"`: Notepad++ for log display

### Other Configuration
```json
"dryRun": false,
"mission": "Su25-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz",
"numberOfRuns": 3,
"maxRetries": 1
```

- `"dryRun"`: boolean - Run without actually collecting data
- `"mission"`: string - Mission filename (relative to benchmark-missions/)
- `"numberOfRuns"`: integer - Repetitions of each test setting
- `"maxRetries"`: integer - Automatic retry count on failure

---

## Test Configuration

### Test Structure
```json
"testsToRun": [
  {
    "setting": "SSAO",
    "values": [0, 1],
    "enabled": true
  },
  {
    "setting": "shadows",
    "values": [1, 3],
    "enabled": false
  }
]
```

- `"setting"`: DCS graphics setting name
- `"values"`: Array of values to test
- `"enabled"`: boolean - Include this setting in benchmark

### Combinatorial Explosion
Total test combinations = ∏(number of values per enabled setting) × numberOfRuns

Example:
- SSAO: 2 values
- shadows: 2 values
- numberOfRuns: 3
- Total: 2 × 2 × 3 = **12 combinations**

---

## Common Configuration Scenarios

### Scenario 1: Meta Quest User
```json
{
  "vr": {
    "enabled": true,
    "hardware": "auto"
  },
  "waitTimes": {
    "vr": 18000,
    "missionReady": 35000,
    "missionRestart": 30000
  },
  "paths": {
    "metaquestLink": "auto",
    "steamVR": "auto",
    "pimax": "auto"
  }
}
```

### Scenario 2: HTC Vive User with SSD
```json
{
  "vr": {
    "enabled": true,
    "hardware": "auto"
  },
  "waitTimes": {
    "vr": 15000,
    "missionReady": 30000,  // Faster on SSD
    "missionRestart": 25000
  }
}
```

### Scenario 3: No VR (Monitor Only)
```json
{
  "vr": {
    "enabled": false
  },
  "waitTimes": {
    "vr": 0,
    "missionReady": 25000,  // Skip VR init
    "missionRestart": 20000
  }
}
```

### Scenario 4: Manual Pimax Path
```json
{
  "vr": {
    "enabled": true,
    "hardware": "Pimax"
  },
  "paths": {
    "pimax": "D:\\CustomInstall\\Pimax\\PimaxClient.exe"
  }
}
```

---

## Calibration Workflow

### Before First Benchmark
1. Open **Performance Testing** tab
2. Enable VR
3. Select **"Auto-detect"** (or choose specific headset)
4. Click **"Calibration Wizard"**
5. Follow 2-3 steps:
   - VR Hardware startup
   - DCS cold start
   - DCS mission restart
6. Wizard updates config automatically

### What Gets Updated
```json
{
  "waitTimes": {
    "vr": 18500,        // Calibrated value + 5s buffer
    "missionReady": 37000,
    "missionRestart": 32000
  }
}
```

### Re-calibration
Only needed if:
- System hardware changes significantly
- Windows installed on different drive
- Different VR headset installed

---

## Validation Rules

### Required Fields
- `vr.enabled`: Must be boolean
- `vr.hardware`: Must be "auto", "MetaQuest", "HTCVive", or "Pimax"
- `waitTimes.vr`: Must be integer >= 5000
- `waitTimes.recordLength`: Must be integer >= 30000 (at least 30 seconds)
- `numberOfRuns`: Must be integer >= 1

### Path Validation
- All executable paths must exist or be set to "auto"
- Directory paths must exist
- Environment variables are expanded before validation

### Test Validation
- Each test setting must have at least 1 value
- Test value types must match DCS setting types (int, float, string)
- Maximum 10 enabled tests (to prevent excessive runtime)

---

## Default Values

If not specified in config, these defaults are used:

```json
{
  "version": "2.0.0",
  "dryRun": false,
  "vr": {
    "enabled": false,
    "hardware": "auto"
  },
  "waitTimes": {
    "vr": 18000,
    "missionReady": 35000,
    "beforeRecord": 3000,
    "recordLength": 60000,
    "capFrameXWrite": 5000,
    "missionRestart": 30000
  },
  "numberOfRuns": 3,
  "maxRetries": 1
}
```

---

## Tips for Optimization

### Faster Benchmarks
- Reduce `waitTimes` values (after calibration confirms shorter times work)
- Reduce `numberOfRuns` (trade statistical accuracy for speed)
- Reduce `recordLength` (but keep >= 30 seconds)
- Test fewer settings combinations

### More Accurate Results
- Increase `numberOfRuns` to 5-10
- Extend `recordLength` to 120+ seconds
- Ensure `waitTimes` have 5-10 second buffer over actual times

### Stable Results
- Keep VR hardware paths set to "auto"
- Allow full wait times (don't reduce below calibrated values)
- Close unnecessary background applications
- Run benchmarks in consistent environment

---

## Troubleshooting

### Config Won't Load
- Validate JSON syntax (missing commas, quotes, brackets)
- Check file encoding (UTF-8)
- Verify all paths exist or are set to "auto"

### Benchmark Times Out
- Increase `waitTimes` values
- Check if DCS/VR software actually started
- Verify mission file exists at configured path

### Meta Quest Not Detected
- Verify Meta Quest software is installed
- Check USB connection (if using USB Link)
- Verify registry: `HKEY_LOCAL_MACHINE\SOFTWARE\Meta` exists

### SteamVR Not Detected
- Verify Steam is installed at default location
- Check registry: `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam`
- Verify SteamVR app installed in Steam (should be free)

---

## Schema Version History

- **v2.0.0** (Current): Multi-headset support, auto-detection, global VR timing
- **v1.0.0** (Legacy): Single Pimax support, manual paths only
