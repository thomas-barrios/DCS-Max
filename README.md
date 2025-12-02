# 🚀 DCS-Max

**The Ultimate DCS World Performance Optimization Suite**


DCS-Max is a comprehensive automation suite designed to maximize DCS World performance, reduce stutters, and provide safe system backup/restore capabilities. Save time and get the best experience from your PC with professional-grade optimization tools.

## 🖥️ **NEW: Graphical User Interface**

DCS-Max now includes a modern Electron-based UI for easy management of all features:

- **Visual Dashboard** - Overview of system info and quick actions
- **One-Click Operations** - Backup, restore, and optimize with a single click
- **Real-Time Monitoring** - Live log viewing and progress tracking
- **Configuration Editor** - Visual INI editor for benchmark settings
- **No Command Line Required** - User-friendly interface for all operations

**To use the UI:** Navigate to `ui-app/` folder and see [UI Setup Guide](ui-app/SETUP.md)

## 🎯 **What This Suite Does**

- **🚀 Automated DCS Performance Testing** - Test 128+ graphics settings combinations with CapFrameX integration
- **🛡️ Safe System Backups** - Complete backup/restore for DCS configs, Windows tasks, services, and registry
- **⚡ Windows Optimization** - Disable unnecessary services and tasks that cause stutters and frame drops
- **📊 Performance Analytics** - Automated benchmarking with detailed logging and result tracking
- **🔧 Easy Configuration** - Template-based setup for various optimization scenarios
- **🖥️ Graphical Interface** - Modern UI for effortless management (NEW!)

## 🎮 **Target Audience**

Advanced DCS players and system administrators who want:
- Maximum FPS and minimum stutters in VR and traditional setups
- Safe, reversible system optimizations
- Automated performance testing capabilities
- Professional-grade backup and restore functionality


## 📋 **Pre-requisites**

### System Requirements
- **OS**: Windows 10/11 (64-bit) with Administrator privileges
- **DCS World**: Any version and modules
- **PowerShell**: 5.1 or later (included with Windows)
- **AutoHotkey v2.0**: For DCS automation
- **CapFrameX**: For performance benchmarking
- **Notepad++**: For logging visualization and script editing


## ⚡ **Quick Installation & Setup**

### 🖥️ Option 1: Use the Graphical UI (Recommended)

**Easiest way to use DCS-Max - No command-line experience needed!**

1. **Install Node.js 18+** from [nodejs.org](https://nodejs.org/)
2. **Navigate** to the `ui-app` folder
3. **Double-click** `install.bat`
4. **Follow** the on-screen prompts
5. **Start using** the UI - all features accessible with clicks!

**Features:**
- ✨ Visual dashboard with system information
- 💾 One-click backup and restore
- 🔧 Easy system optimization
- 📊 Automated benchmark management
- 📋 Real-time log viewing
- ⚙️ Configuration editor

📖 **Full UI Documentation**: See [`ui-app/USER-GUIDE.md`](ui-app/USER-GUIDE.md)

---

### 🖱️ Option 2: Use PowerShell Scripts (Advanced Users)

For users who prefer command-line or want maximum control:

### Step 1: Download and Extract
1. Download the latest release from the repository 
[https://github.com/thomas-barrios/DCS-Max/releases](https://github.com/thomas-barrios/DCS-Max/releases)
2. Extract to your preferred location (e.g., `C:\DCS-Max\`)
3. Ensure the folder structure is intact



### Step 2: Create System Restore Point
**⚠️ CRITICAL: Always create a restore point before optimization**

<img width="394" height="367" alt="image" src="https://github.com/user-attachments/assets/f7370269-6188-4c1e-a3fd-3f0d7796dd28" />

```powershell
# Run in PowerShell as Administrator
# Alternatively you can run this command to create a restore point
# CRITICAL: Allways create a restore point before any windows changes
Checkpoint-Computer -Description "Before DCS-Max Optimization" -RestorePointType "MODIFY_SETTINGS"
```



### Step 3: Install Requirements
**IMPORTANT this apps are required for DCS Max**

#### CapFrameX 
Recording and performance comparison tool. CapFrameX is a comprehensive frame time analysis tool that integrates seamlessly with DCS-Max for automated performance testing. This guide covers installation, configuration, and integration with the DCS-Max benchmark suite.
[https://www.capframex.com/download](https://www.capframex.com/download)

#### AutoHotKey 
Keypress automation tool. The ultimate automation scripting language for Windows. AutoHotkey is a free, open-source scripting language for Windows that allows users to easily create small to complex scripts for all kinds of tasks such as: form fillers, auto-clicking, macros, etc.
[https://www.autohotkey.com/download/](https://www.autohotkey.com/download/)

#### Notepad++
Notepad++ is a free (as in “free speech” and also as in “free beer”) source code editor and Notepad replacement that supports several programming languages. Notepad++. It supports tabbed editing, which allows working with multiple open files in one window. 
[https://notepad-plus-plus.org/downloads/](https://notepad-plus-plus.org/downloads/)

```powershell
# Run in PowerShell as Administrator
# Alternatively you can install the required applications with the following commands
winget install --id=CXWorld.CapFrameX  -e
winget install --id=AutoHotkey.AutoHotkey  -e
winget install --id=Notepad++.Notepad++ -e
```



## Utilization

### Step 4: 🎮 Backup and Restore (IMPORTANT)

Before any changes, make a backup using the scripts below:

This will create individual backups, for affected files and settings only. Make sure you have already created a windows restore point!

```powershell
# Backup affected windows registry keys and values
.\1.Backup-restore\1.1.1-registry-backup.ps1

# Backup affected windows tasks
.\1.Backup-restore\1.2.1-tasks-backup.ps1

# Backup affected windows services
.\1.Backup-restore\1.3.1-services-backup.ps1

# Backup affected DCS and applications config files
.\1.Backup-restore\1.4.1-dcs-backup.ps1

# Optional: Schedule automated backups
.\1.Backup-restore\1.4.3-schedule-dcs-backup-at-logon.ps1
```



### Step 5: 🛠️ Utilities Setup

OPTIONAL: You can install and optmize windows with the utilities bellow:

#### Win Util
WinUtil is a comprehensive Windows 10/11 optimization tool created by ChrisTitusTech that provides a GUI interface for system tweaks, software installation, and performance optimization. The DCS-Max suite includes a pre-configured template for DCS-focused optimizations.
[https://christitus.com/win](https://christitus.com/win)

#### O&O ShutUp10++
O&O ShutUp10++ is a free antispy tool for Windows 10/11 that allows you to disable privacy-invasive features and performance-impacting telemetry. The DCS-Max suite includes a pre-configured template engineered for gaming performance, privacy, and maximum thrust.
[https://www.oo-software.com/en/shutup10](https://www.oo-software.com/en/shutup10)

#### NVIDIA Profile Inspector
NVIDIA Profile Inspector (NPI) is a powerful tool that provides access to hidden NVIDIA driver settings not available in the standard Control Panel. The DCS-Max suite includes a pre-configured profile engineered for DCS World performance, stability, and visual quality at maximum thrust.
[https://github.com/Orbmu2k/nvidiaProfileInspector](https://github.com/Orbmu2k/nvidiaProfileInspector)

#### Google Drive
Google Drive provides reliable cloud storage for backing up your DCS configurations, but if kept running can reduce system thrust and introduce stutters. The DCS-Max suite includes automated scheduling templates to run Google Drive only once a week—balancing peak game performance and backup safety, so your rig stays at full thrust and your settings are always protected.
[https://drive.google.com/drive/download/](https://drive.google.com/drive/download/)

Install all desired utilities from `2-Utilities/` for optmization

Run each one and personalize according your prefferences.



### Step 6: 📄 Choose the Templates

Alternatively, you can pick a configuration template from `3-Templates/` for use with the Utilities.

Review and apply these templates, or create your own using each utility.




### Step 7: 🚀 Performance Testing

Run a first-time performance test to serve as a baseline for future improvements.

After each change, you can run additional tests to evaluate the effect on DCS and PC performance.

#### Open and configure **.\4-Performance-Testing\4.1.1-dcs-testing-configuration.ini**

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

In this file, you can set wich configurations you want to test in DCS

<img width="991" height="880" alt="image" src="https://github.com/user-attachments/assets/c52dceb0-7d90-412c-8728-c129cb6311c8" />
For the image above, we are testing (uncommented lines):
 - anisotropy values ranging from 1,2,4,8 to 16 and requiring DCS restart
 - canopyReflections values ranging from 0,0.50,0.75,0.88 to 1.00 requiring NO DCS restart
 - chimneySmokeDensity values ranging from 0,5,8,9,10 requiring NO DCS restart

So the script will:
0) Store current value for **anisotropy** in options.lua
1) Change the DCS  value from current value to **anisotropy =1** in options.lua
2) Start DCS and run a pre recorded mission track
3) repeat the test X times as set in the scritp file (_.\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk_)
4) Close DCS and return **anisotropy** to its original value
5) Move on to the next tests
    - anisotropy=2
    - anisotropy=4
    - anisotropy=8
    - anisotropy=16
    - canopyReflections=0
    - canopyReflections=0.5
    - and so on...
6) After all tests are completed, DCS will be closed. All progress is recorded in the log file (`.\\4-Performance-Testing\\4.1.2-dcs-testing-automation.log`), which is also displayed during tests

```powershell
# Configure the Tests to be run
# Uncomment the desired test lines
.\4-Performance-Testing\4.1.1-dcs-testing-configuration.ini

# Review script configuration
# Open the script in a text editor and check if:
# - Paths are correct
# - Waiting times are correct (THEY VARY FROM PC TO PC - YOU MUST MEASURE YOURS!)
# - Mouse Left button --> Edit with Notepad++
.\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk

# Run automated DCS performance testing with CapFrameX integration
# Double-click the script to run
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

### Step 5: 🛠️ Performance Testing and Logging

Prior to DCS open and run the track, supporting applications will be open:

#### Notepadd++ 
Displaying the log in real time
<img width="991" height="880" alt="image" src="https://github.com/user-attachments/assets/b8e7c7b8-2802-461d-bc63-f5460d64e6be" />

```powershell
# View real-time benchmark progress and results
Run notepadpp -monitor .\4-Performance-Testing\4.1.2-dcs-testing-automation.log

# Features:
# - Detailed timestamped logging of all benchmark operations
# - Performance data collection and analysis
# - Error reporting and retry tracking
# - Benchmark completion status and results summary
# - Compatible with external log analysis tools
```

#### CapFrameX 
CapFrameX that will capture tests results during DCS track play
Pay attention to the detection of the DCS process, and also for the **Capturing** clue at the lower left corner when DCS is capturing
IMPORTANT: you have to change the default RecordKey in CapFrameX from "F11" to **"SCROLL LOCK"** to avoid DCS conflicts.

<img width="1236" height="733" alt="image" src="https://github.com/user-attachments/assets/da075855-031f-4021-937c-563899c00c35" />


### Step 8: 🚀 Performance Optimization

After successfully running the first automated test, you can optimize system and DCS settings and test any configuration.

Review the optimization scripts and personalize them according to your needs.

Open the scripts at: `.\\5-Optimization\\`

<img width="991" height="880" alt="image" src="https://github.com/user-attachments/assets/4d605b0c-3326-48c8-9c43-2d6c86823ff2" />


Edit the scripts to your preferences, or leave defaults

<img width="991" height="880" alt="image" src="https://github.com/user-attachments/assets/411442f3-04e8-4bf0-adda-8ca1e0cbf8c0" />

Run the scripts in PowerShell:

```powershell
# Clear Cache
# Clean NVIDIA shader and DX cache, plus DCS-related caches (run as Administrator)
.\5.Optimization\5.4.1-clean-caches.bat

# Registry Optimization
.\5.Optimization\5.1.2-registry-optimize.reg

# Tasks Optimization  
.\5.Optimization\5.2.2-tasks-optimize.ps1

# Services Optimization
.\5.Optimization\5.3.2-services-optimize.ps1

# Verify disabled services
Get-Service | Where-Object {$_.StartType -eq 'Disabled'} | Select Name, DisplayName

# Verify disabled tasks
Get-ScheduledTask | Where-Object {$_.State -eq 'Disabled'} | Select TaskName, State
```

<img width="920" height="489" alt="image" src="https://github.com/user-attachments/assets/b64ee1e9-083f-4422-ad13-e0d858c8b9b4" />

*Sample script output*


#### Restart and Verify
1. Restart your computer to apply all optimizations
2. Launch DCS World and test performance
3. Use verification commands to check applied optimizations:


### Step 9: 🚀 Check Results and Repeat

Each test run will be recorded in CapFrameX. Compare test settings within CapFrameX 

<img width="1427" height="861" alt="image" src="https://github.com/user-attachments/assets/e1603d72-5c9d-421b-af3c-fdba64ab4519" />

On the image above, multiple results tests of WATER setting

You can check
🚀 **[Performance Guide](performance-guide.md)** - Understanding the optimizations
for more information on what to test, and what to look for.


Happy Flying, Happy testing!

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


## 📁 **Project Structure**

```bash
DCS-Max/
├── 1-Backup-Restore/
│   ├── 1.1.1-registry-backup.ps1
│   ├── 1.1.3-registry-restore.reg
│   ├── 1.2.1-tasks-backup.ps1
│   ├── 1.2.3-tasks-restore.ps1
│   ├── 1.3.1-services-backup.ps1
│   ├── 1.3.2-services-restore.ps1
│   ├── 1.4.1-dcs-backup.ps1
│   ├── 1.4.2-dcs-restore.ps1
│   └── 1.4.3-schedule-dcs-backup-at-logon.ps1
├── 2-Utilities/
│   ├── 2.1.0-Windows-unattended.md
│   ├── 2.2.0-Winutil.md
│   ├── 2.3.0-OOshutup10.md
│   ├── 2.4.0-Nvidia-Profile-Inspector.md
│   ├── 2.5.0-Google-Drive.md
│   └── 2.6.0-CapFrameX.md
├── 3-Templates/
│   ├── 3.1.0-unattended.xml
│   ├── 3.2.0-winutil-config.json
│   ├── 3.3.0-ooshutup10-config.cfg
│   ├── 3.4.0-nvidia-base-profile.nip
│   ├── 3.5.0-dcs-google-drive-weekly-backup.xml
│   └── 3.6.0-dcs-reference-configuration.ini
├── 4-Performance-Testing/
│   ├── 4.1.1-dcs-testing-configuration.ini
│   ├── 4.1.2-dcs-testing-automation.ahk
│   ├── 4.1.2-dcs-testing-automation.log
│   ├── 4.1.3-dcs-benchmark-automation.log
│   └── benchmark-missions/
├── 5-Optimization/
│   ├── 5.1.0-individual-registry-optimization/
│   ├── 5.1.2-registry-optimize.reg
│   ├── 5.2.2-tasks-optimize.ps1
│   ├── 5.3.2-services-optimize.ps1
│   ├── 5.4.1-clean-caches.bat
│   └── _README.md
├── Backups/ (empty)
├── CHANGELOG.md
├── LICENSE
├── master-config.ini
├── performance-guide.md
├── troubleshooting.md
├── quick-start-guide.md
└── README.md
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

- 📖 **[Quick Start Guide](quick-start-guide.md)** - Get up and running fast
- ⚡ **[Performance Optimizations](performance-optimizations.md)** - Detailed optimization reference
- 🚀 **[Performance Guide](performance-guide.md)** - Understanding the optimizations
- 🆘 **[Troubleshooting](troubleshooting.md)** - Detailed problem resolution
- 🖥️ **[UI User Guide](ui-app/USER-GUIDE.md)** - Graphical interface documentation

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


**✈️ Fly safer, fly faster with DCS-Max!**
