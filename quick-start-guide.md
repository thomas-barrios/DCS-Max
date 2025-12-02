# 🛩️ DCS-Max Quick Start Guide

**Push Your Rig to Full Thrust in 5 Minutes!**


## 🎯 **What You'll Achieve**

- Create full-thrust system backups
- Apply high-performance optimizations
- Set up automated DCS benchmarking
- Boost FPS, reduce stutters, and accelerate load times


## 📋 **Prerequisites Check**

**Required Software:**
- ✅ Windows 10/11 (Admin privileges)
- ✅ PowerShell 5.1+ (built-in)
- ✅ DCS World (any version)
- ✅ AutoHotkey v2.0 – [Download](https://www.autohotkey.com/v2/)
- ✅ CapFrameX – [Download](https://www.capframex.com/)
- ✅ Notepad++ – [Download](https://notepad-plus-plus.org/)

**Optional (for GUI):**
- ✅ Node.js 18+ – [Download](https://nodejs.org/)


## 📥 **Download and Setup**

1. **Download** DCS-Max from [GitHub Releases](https://github.com/thomas-barrios/DCS-Max/releases)
2. **Extract** to a folder like `C:\DCS-Max\`
3. **Right-click PowerShell** → "Run as Administrator"
4. **Navigate** to the extracted folder:
   ```powershell
   cd "C:\DCS-Max"
   ```


## 🖥️ **Option A: Use the Graphical UI (Recommended)**

The easiest way to use DCS-Max — no command-line experience needed!

1. Navigate to the `ui-app` folder
2. Double-click `DCS-Max.bat`
3. Use the visual interface for all operations

📖 See [`ui-app/USER-GUIDE.md`](ui-app/USER-GUIDE.md) for full UI documentation.

---

## 💻 **Option B: Use PowerShell Scripts**

For users who prefer command-line or want maximum control.


### Create System Restore Point

**Always create a restore point before you push your rig to full thrust!**

```powershell
Checkpoint-Computer -Description "Before DCS-Max" -RestorePointType "MODIFY_SETTINGS"
```


### Step 1: Run the Backups

🔄 **Backup Scripts (1-Backup-Restore/)**

**Create a safety backup before any optimizations:**

```powershell
# Backup Windows Registry
.\1-Backup-Restore\1.1.1-registry-backup.ps1

# Backup Windows Tasks
.\1-Backup-Restore\1.2.1-tasks-backup.ps1

# Backup Windows Services
.\1-Backup-Restore\1.3.1-services-backup.ps1

# Backup DCS Configuration
.\1-Backup-Restore\1.4.1-dcs-backup.ps1
```


### Step 2: Download and Install the Utilities

Optional utilities for additional optimization:

- **WinUtil** – Windows optimization GUI
- **O&O ShutUp10** – Privacy and telemetry control
- **NVIDIA Profile Inspector** – Advanced GPU settings
- **Google Drive** – Cloud backup for DCS configs

See `2-Utilities/` for detailed setup instructions.


### Step 3: Import Templates for Full Thrust

**Pre-configured templates in `3-Templates/` for:**
- Windows unattended install
- WinUtil config
- O&O ShutUp10 privacy settings
- NVIDIA Profile Inspector profile
- Google Drive backup scheduling


### Step 4: Performance Check – Baseline Your Thrust

🧪 **Performance Testing Scripts (4-Performance-Testing/)**

Run a baseline test before optimization:

```powershell
# Configure test settings first
notepad .\4-Performance-Testing\4.1.1-dcs-testing-configuration.ini

# Then run DCS Testing Automation (double-click in Explorer)
.\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk
```


### Step 5: Optimization Scripts – Engage Max Thrust

⚡ **Optimization Scripts (5-Optimization/)**

```powershell
# Clean Caches first
.\5-Optimization\5.4.1-clean-caches.bat

# Registry Optimization (double-click to apply)
.\5-Optimization\5.1.2-registry-optimize.reg

# Tasks Optimization
.\5-Optimization\5.2.2-tasks-optimize.ps1

# Services Optimization
.\5-Optimization\5.3.2-services-optimize.ps1
```


### Step 6: Test Your Performance After Optimization

1. **Restart your computer** to apply all changes
2. **Run automated DCS benchmark** again:
   ```powershell
   # Double-click this file in Windows Explorer:
   .\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk
   ```
3. **Compare results** in CapFrameX to measure improvement


## 🛡️ **Safety: How to Restore Control**

If you experience any issues, restore your original settings:

```powershell
# Restore Windows Registry
.\1-Backup-Restore\1.1.3-registry-restore.reg

# Restore Windows Tasks
.\1-Backup-Restore\1.2.3-tasks-restore.ps1

# Restore Windows Services
.\1-Backup-Restore\1.3.2-services-restore.ps1

# Restore DCS Settings
.\1-Backup-Restore\1.4.2-dcs-restore.ps1
```


## 📚 **Learn More**

- **[Full README](README.md)** – Complete documentation
- **[Performance Optimizations](performance-optimizations.md)** – Detailed optimization reference
- **[Performance Guide](performance-guide.md)** – Understanding every optimization
- **[Troubleshooting](troubleshooting.md)** – Problem resolution guide
- **[UI User Guide](ui-app/USER-GUIDE.md)** – Graphical interface documentation


## 🆘 **Need Help?**

- Check the [Troubleshooting Guide](troubleshooting.md)
- Review log files created by each script
- All scripts include detailed error messages to guide you


## ⚠️ **Important Notes**

- **Always run as Administrator** for system optimization scripts
- **Restart your computer** after applying optimizations for full effect
- **Test DCS performance** before and after to measure improvements
- **Keep the backup files** created by the scripts for safety

---

**🛩️ Ready to push your rig to full thrust? Your optimized DCS experience awaits!**
