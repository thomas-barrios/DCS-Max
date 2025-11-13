
# 🛩️ DCS Max Quick Start

**Push Your Rig to Full Thrust in 5 Minutes!**


## 🎯 **What You’ll Achieve**

- Create full-thrust system backups
- Apply high-performance optimizations
- Set up automated DCS benchmarking
- Boost FPS, reduce stutters, and accelerate load times


### Prerequisites Check

**Required Software:**
- ✅ Windows 10/11 (Admin)
- ✅ PowerShell (built-in)
- ✅ DCS World
- ✅ AutoHotkey v2.0 – [Download](https://www.autohotkey.com/v2/)
- ✅ CapFrameX – [Download](https://www.capframex.com/)


### Download and Setup

1. **Download** DCS Max
2. **Extract** to a folder like `C:\DCS-Max\`
3. **Right-click PowerShell** → "Run as Administrator"
4. **Navigate** to the extracted folder:
   ```powershell
   cd "C:\DCS-Max"
   ```


### Create System Restore Point (Manual)

**Always create a restore point before you push your rig to full thrust!**

```powershell
Checkpoint-Computer -Description "Before DCS Max" -RestorePointType "MODIFY_SETTINGS"
```


### Step 1: Run the Backups

🔄 **Backup Scripts (Backups/)**

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
- Windows unattended installation (if installing Windows from scratch)
- WinUtil
- O&O ShutUp10
- NVIDIA Profile Inspector
- Google Drive



### Step 3: Import Templates for Full Thrust

**Pre-configured templates in `3-Templates/` for:**
- Windows unattended install
- WinUtil config
- O&O ShutUp10 privacy
- NVIDIA Profile Inspector
- Google Drive backup



### Step 4: Performance Check – Baseline Your Thrust

🧪 **Performance Testing Scripts (4-Performance-Testing/)**

```powershell
# DCS Testing Automation (AutoHotkey script)
.\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk
```


### Step 5: Optimization Scripts – Engage Max Thrust

⚡ **Optimization Scripts (5-Optimization/)**

```powershell
# Registry Optimization (double-click to apply)
.\5-Optimization\5.1.2-registry-optimize.reg

# Tasks Optimization
.\5-Optimization\5.2.2-tasks-optimize.ps1

# Services Optimization
.\5-Optimization\5.3.2-services-optimize.ps1

# Clean Caches (Batch file)
.\5-Optimization\5.4.1-clean-caches.bat
```


### Step 6: Test Your Performance After Optimization

2. **Run automated DCS benchmark:**
   ```
   # Double-click this file in Windows Explorer:
   .\4-Performance-Testing\4.1.2-dcs-testing-automation.ahk
   ```

### Automated Performance Testing
- Set up comprehensive DCS graphics testing with the benchmark automation
- Test different settings combos to find your optimal thrust
- Use CapFrameX for detailed performance analysis




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

- **[Installation Guide](1-README.md#quick-installation--setup)** – Full-thrust setup for all features
- **[Performance Guide](3-performance-guide.md)** – Engineering every FPS gain
- **[Troubleshooting](4-troubleshooting.md)** – Regain control, restore thrust


## 🆘 **Need Help?**

- Check the [Troubleshooting Guide](4-troubleshooting.md)
- Review log files created by each script
- All scripts include detailed error messages to guide you


## ⚠️ **Important Notes**

- **Always run as Administrator** for system optimization scripts
- **Restart your computer** after applying optimizations for full effect
- **Test DCS performance** before and after to measure improvements
- **Keep the backup files** created by the scripts for safety

---


**🛩️ Ready to push your rig to full thrust? Your optimized DCS experience awaits!**