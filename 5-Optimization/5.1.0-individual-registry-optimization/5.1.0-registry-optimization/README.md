
# DCS-Max: Windows Registry Optimization Files

## Overview

This folder contains individual Windows registry optimization files engineered for DCS-Max. Apply each tweak independently for precision tuning—every change is about speed, thrust, and smoothness.

## File Structure
Each optimization has two files:
- **`2.3.0.X-[Name].reg`** - Applies the optimization
- **`2.3.0.X-[Name]_restore.reg`** - Restores Windows defaults

## Optimizations Available

### 2.1.0.1 - CPU Core Parking
- **Purpose**: Disables CPU core parking to utilize all cores
- **Impact**: Reduces micro-stutters in VR and multiplayer
- **Files**: `2.1.0.1-CPUCoreParking.reg` / `2.1.0.1-CPUCoreParking_restore.reg`

### 2.1.0.2 - DCS CPU Priority Class  
- **Purpose**: Sets DCS.exe to High priority for better CPU scheduling
- **Impact**: DCS gets prioritized CPU time over background processes
- **Files**: `2.1.0.2-CpuPriorityClass.reg` / `2.1.0.2-CpuPriorityClass_restore.reg`

### 2.1.0.3 - GameDVR Disable
- **Purpose**: Disables Windows Game DVR recording
- **Impact**: Eliminates recording lag, improves FPS and reduces input latency  
- **Files**: `2.1.0.3-GameDVR.reg` / `2.1.0.3-GameDVR_restore.reg`

### 2.1.0.4 - MaxPreRenderedFrames
- **Purpose**: Limits Direct3D pre-rendered frames to reduce input lag
- **Impact**: Lower input latency and better responsiveness
- **Files**: `2.1.0.4-MaxPreRenderedFrames.reg` / `2.1.0.4-MaxPreRenderedFrames_restore.reg`

### 2.1.0.5 - System Profile Network & CPU
- **Purpose**: Disables network throttling and optimizes CPU allocation
- **Impact**: Better ping stability for multiplayer, more CPU for gaming
- **Files**: `2.1.0.5-SystemProfile.reg` / `2.1.0.5-SystemProfile_restore.reg`

### 2.1.0.6 - Power Throttling Disable
- **Purpose**: Prevents CPU throttling for power savings
- **Impact**: Maintains maximum CPU performance during gaming
- **Files**: `2.1.0.6-PowerThrottling.reg` / `2.1.0.6-PowerThrottling_restore.reg`

### 2.1.0.7 - Priority Separation (Recommended: 26)
- **Purpose**: Optimizes Windows CPU scheduler for gaming processes
- **Impact**: Better consistency, lower latency, improved frame times
- **Files**: `2.1.0.7-PrioritySeparation.reg` / `2.1.0.7-PrioritySeparation_restore.reg`

### 2.1.0.8 - System Profile Games Task
- **Purpose**: Gives games preferential CPU, GPU, and I/O scheduling
- **Impact**: Enhanced system resource allocation for gaming applications
- **Files**: `2.1.0.8-SystemProfileGames.reg` / `2.1.0.8-SystemProfileGames_restore.reg`

## Usage Instructions

### Applying Optimizations
1. **Create System Restore Point** (recommended before any registry changes)
2. **Double-click** the desired `.reg` file
3. **Confirm** the registry import when prompted
4. **Restart** your computer for changes to take effect

### Restoring Defaults
1. **Double-click** the corresponding `_restore.reg` file
2. **Confirm** the registry import when prompted  
3. **Restart** your computer for changes to take effect

## Safety Information

⚠️ **Important Warnings:**
- Always backup your registry before making changes
- Create a system restore point before applying optimizations
- Test changes individually to identify any compatibility issues
- All optimizations are completely reversible using restore files

✅ **Safety Features:**
- Each file includes comprehensive documentation and rationale
- All changes are reversible with corresponding restore files
- Files follow Windows registry best practices
- Changes are based on verified gaming optimization techniques

## Sources & References
Each optimization file includes detailed source links and technical explanations. Common sources include:
- DCS World community forums
- Hardware optimization guides  
- Microsoft documentation
- Gaming performance research

## Compatibility
- **OS**: Windows 10/11 (64-bit)
- **Target**: DCS World and other demanding gaming applications
- **Hardware**: All modern gaming systems
- **Safety**: Fully tested and reversible

## Related Files
- `../2.1.1-windows-registry-backup.ps1` - Creates full registry backup before optimization
- `../2.1.2-windows-registry-optimize.reg` - Combined file applying all optimizations at once
- `../2.0.0-DCS-HighEnd-PerformanceStability-v09.ini` - Main configuration documentation