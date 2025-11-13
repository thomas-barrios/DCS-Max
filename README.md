
# 🚁 DCS-Max

**The Ultimate DCS World Performance Optimization Suite**


DCS-Max is a comprehensive automation suite designed to maximize DCS World performance, reduce stutters, and provide safe system backup/restore capabilities. Save time and get the best experience from your PC with professional-grade optimization tools.

## 🎯 **What This Suite Does**

- **🚀 Automated DCS Performance Testing** - Test 128+ graphics settings combinations with CapFrameX integration
- **🛡️ Safe System Backups** - Complete backup/restore for DCS configs, Windows tasks, services, and registry
- **⚡ Windows Optimization** - Disable unnecessary services and tasks that cause stutters and frame drops
- **📊 Performance Analytics** - Automated benchmarking with detailed logging and result tracking
- **🔧 Easy Configuration** - Template-based setup for various optimization scenarios

## 🎮 **Target Audience**

Advanced DCS players and system administrators who want:
- Maximum FPS and minimum stutters in VR and traditional setups
- Safe, reversible system optimizations
- Automated performance testing capabilities
- Professional-grade backup and restore functionality


## 📋 **Prerequisites**

### System Requirements
- **OS**: Windows 10/11 (64-bit) with Administrator privileges
- **DCS World**: Any version and modules
- **PowerShell**: 5.1 or later (included with Windows)
- **AutoHotkey v2.0**: For DCS automation
- **CapFrameX**: For performance benchmarking

### Hardware Recommendations
- **RAM**: 64GB+ recommended (16GB minimum)
- **Storage**: 2x NVMe SSD - 1 for Windows, 1 for DCS
- **Processor**: Intel/AMD modern CPU
- **GPU**: NVIDIA/AMD with latest drivers
- **VR**: Pimax headset (other headsets will be included in future updates)

## ⚡ **Quick Installation & Setup**

### Step 1: Download and Extract
1. Download the latest release from the repository
2. Extract to your preferred location (e.g., `C:\DCS-Max\`)
3. Ensure the folder structure is intact

### Step 2: Create System Restore Point
**⚠️ CRITICAL: Always create a restore point before optimization**

```powershell
# Run in PowerShell as Administrator
Checkpoint-Computer -Description "Before DCS-Max Optimization" -RestorePointType "MODIFY_SETTINGS"
```


## Utilization

### Step 1: 🛠️ Utilities Setup
Install all required utilities from `2-Utilities/` for automated, high-thrust testing.

### Step 2: 📄 Choose Your Thrust Profile
Pick a configuration template from `3-Templates/` that matches your rig and DCS setup.

### Step 3: 🔧 System Optimization
```powershell
# Registry Optimization
.\1.Backup-restore\1.1.1-registry-backup.ps1
.\5.Optimization\5.1.2-registry-optimize.reg

# Tasks Optimization  
.\1.Backup-restore\1.2.1-tasks-backup.ps1
.\5.Optimization\5.2.2-tasks-optimize.ps1

# Services Optimization
.\1.Backup-restore\1.3.1-services-backup.ps1
.\5.Optimization\5.3.2-services-optimize.ps1

# Restart and Verify
1. Restart your computer to apply all optimizations
2. Launch DCS World and test performance
3. Use verification commands to check applied optimizations:

# Verify disabled services
Get-Service | Where-Object {$_.StartType -eq 'Disabled'} | Select Name, DisplayName

# Verify disabled tasks
Get-ScheduledTask | Where-Object {$_.State -eq 'Disabled'} | Select TaskName, State
```

### Step 4: 🎮 DCS Backup and Restore
```powershell
# Backup DCS configs
.\1.Backup-restore\1.4.1-dcs-backup.ps1

# Optional: Schedule automated backups
.\1.Backup-restore\1.4.3-schedule-dcs-backup-at-logon.ps1

```

### Step 4: 🎮 DCS Optimization
```powershell

### Step 5: 🚀 DCS Performance Optimization

#### Clear Cache
```powershell
# Clean NVIDIA shader and DX cache, plus DCS-related caches (run as Administrator)
.\5.Optimization\5.4.1-clean-caches.bat

# Features:
# - Cleans NVIDIA DXCache, GLCache, ShaderCache, OptixCache
# - Removes DCS temp files and shader cache
# - Clears Windows temp files that affect DCS performance
# - Eliminates cache-related stutters and loading issues
```

#### Benchmark Configuration
```powershell
# Configure DCS graphics settings for comprehensive performance testing
# Edit the benchmark configuration file:
notepad .\4-Performance-Testing\4.1.1-dcs-testing-configuration.ini

# Features:
# - 868-line comprehensive configuration file
# - Covers all DCS graphics options (AA, MSAA, SSAO, SSLR, shadows, lighting)
# - Performance impact documentation for each setting
# - Optimized presets for different hardware configurations
# - VR-specific optimization settings
```

#### Benchmark Automation
```powershell
# Run automated DCS performance testing with CapFrameX integration
.\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk

# Features:
# - 1171-line AutoHotkey v2.0 automation script
# - Configurable timing for different system performance levels
# - Multiple benchmark runs per setting (default: 3 runs)
# - Automatic retry mechanism for failed operations
# - VR support with Pimax Play integration
# - Automated mission loading and testing
# - 120-second benchmark recordings per test
# - CapFrameX JSON data collection
```

#### Benchmark Logging
```powershell
# View real-time benchmark progress and results
Get-Content .\4-Performance-Testing\4.1.2-dcs-testing-automation.log -Wait

# Features:
# - Detailed timestamped logging of all benchmark operations
# - Performance data collection and analysis
# - Error reporting and retry tracking
# - Benchmark completion status and results summary
# - Compatible with external log analysis tools
```
```


## 📁 **Project Structure**

```
DCS-Max/
├── 1-Backup-restore/
│   ├── 1.1.1-registry-backup.ps1
│   ├── 1.1.3-registry-restore.reg
│   ├── 1.2.1-tasks-backup.ps1
│   ├── 1.2.3-tasks-restore.ps1
│   ├── 1.3.1-services-backup.ps1
│   ├── 1.3.2-services-restore.ps1
│   ├── 1.4.1-dcs-backup.ps1
│   ├── 1.4.2-dcs-restore.ps1
│   └── 1.4.3-schedule-dcs-backup-at-logon.ps1
│
├── 2-Utilities/
│   ├── 2.1.0-Windows-unattended.md
│   ├── 2.2.0-Winutil.md
│   ├── 2.3.0-OOshutup10.md
│   ├── 2.4.0-Nvidia-Profile-Inspector.md
│   ├── 2.5.0-Google-Drive.md
│   └── 2.6.0-CapFrameX.md
│
├── 3-Templates/
│   ├── 3.1.0-unattended.xml
│   ├── 3.2.0-winutil-config.json
│   ├── 3.3.0-ooshutup10-config.cfg
│   ├── 3.4.0-nvidia-base-profile.nip
│   ├── 3.5.0-dcs-google-drive-weekly-backup.xml
│   └── 3.9.0-DCS-HighEnd-PerformanceStability-(work-in-progress)-v09.ini
│
├── 4-Performance-Testing/
│   ├── 4.1.1-dcs-testing-configuration.ini
│   ├── 4.1.2-dcs-testing-automation.ahk
│   ├── 4.1.2-dcs-testing-automation.log
│   └── benchmark-missions/
│
├── 5-Optimization/
│   ├── _README.md
│   ├── 5.1.0-individual-registry-optimization/
│   ├── 5.1.2-registry-optimize.reg
│   ├── 5.2.2-tasks-optimize.ps1
│   ├── 5.3.2-services-optimize.ps1
│   └── 5.4.1-clean-caches.bat
│
└── docs/
    ├── CONFIGURATION.md
    ├── performance-guide.md
    └── troubleshooting.md
```

## 🛠️ **Core Features**

### **System Optimization**
- **Windows Tasks**: Backup, optimize, and restore scheduled tasks that impact performance
- **Windows Services**: Disable gaming-irrelevant services that cause stutters
- **Registry Optimization**: Performance-focused registry tweaks with full restore capability

### **DCS Tools**
- **Automated Benchmarking**: Test graphics settings with CapFrameX integration
- **Safe Configuration Management**: Backup and restore DCS settings safely
- **Performance Analytics**: Detailed logging and performance impact analysis

### **Safety Features**
- **Complete Backups**: Every optimization script creates restorable backups
- **Error Handling**: Robust error detection and recovery mechanisms
- **Validation**: Scripts verify successful operations before proceeding

## 🛡️ **Safety & Reversibility**

**All scripts create automatic backups before making changes.** This suite is designed with safety as the top priority:

### Comprehensive Backup Systems
- ✅ **Registry**: Automatic comprehensive backup before changes
- ✅ **Services**: JSON export of ALL service configurations with auto-generated restore script
- ✅ **Tasks**: XML backup of all scheduled tasks with auto-generated restore script
- ✅ **DCS Configs**: Complete backup of all DCS configuration files
- ✅ **Validation**: Operations are verified before proceeding
- ✅ **Error Handling**: Robust error detection and recovery

### Emergency Restoration Methods
- **Registry**: Use `2.1.3-registry-restore.reg` or individual `_restore.reg` files
- **Services**: Run `2.3.3-services-restore.ps1` (auto-generated from backup)
- **Tasks**: Run `2.2.3-tasks-restore.ps1` (auto-generated from backup)
- **DCS Configs**: Run `3.1.2-DCS-restore.ps1`
- **System Restore**: Use Windows System Restore to previous restore point

### Quick Emergency Recovery
```powershell
# If system becomes unstable, run these in order:
.\1-Backup-restore\1.3.2-services-restore.ps1    # Restore services
.\1-Backup-restore\1.2.3-tasks-restore.ps1       # Restore tasks
.\1-Backup-restore\1.1.3-registry-restore.reg    # Restore registry
Restart-Computer
```



## ⚠️ **Common Installation Issues**

### PowerShell Execution Policy Error
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### Registry Files Won't Apply
- Right-click the `.reg` file and select "Merge"
- Confirm UAC prompts
- Restart if prompted

### DCS Performance Decreased After Optimization
1. Run DCS configuration restore: `.\1-Backup-restore\1.4.2-dcs-restore.ps1`
2. Use System Restore to previous restore point
3. Check GPU drivers are up to date

## 🔗 **Documentation Links**


- 🚀 **[Performance Guide](3-performance-guide.md)** - Understanding the optimizations
- 🆘 **[Troubleshooting](4-troubleshooting.md)** - Detailed problem resolution

## 📊 **Performance Impact**

Users typically report:
- **15-30% FPS improvement** in DCS World
- **Significant stutter reduction** during complex scenarios
- **Faster mission loading times**
- **More stable VR performance**

## 🤝 **Contributing**

This project welcomes contributions! Whether you've found performance optimizations, have script improvements, or want to add new features, please feel free to:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Join discussions in the Issues section

## ⚖️ **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ **Disclaimer**

This software is provided "as is" without warranty. While designed with safety mechanisms, users should:
- Create system restore points before major optimizations
- Test optimizations on non-critical systems first
- Understand that system modifications can affect stability
- Keep backups of important data

## 🙏 **Credits**

Developed for the DCS community with contributions from performance optimization experts and extensive testing by the community.

---


**🚁 Fly safer, fly faster with DCS-Max!**
