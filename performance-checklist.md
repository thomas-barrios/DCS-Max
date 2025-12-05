# 🎯 DCS Performance Checklist

**A comprehensive checklist with known and proven settings to improve DCS World performance.**

---

## 🔧 **Phase 1: Hardware Optimization**

### 1️⃣ BIOS Configuration (AMD 9800X3D Example)

- ✅ Reset BIOS to defaults
- ✅ Load Defaults (`F5`)
- ✅ Set CoresRatio: **AI Optimized**

### 2️⃣ BIOS Memory OC Profiles

- ✅ Select **EXPO I** profile

> 💡 **How AI Optimization Works:** With AI Optimized enabled, each time the CPU restarts, the motherboard tests overclock parameters and automatically applies the results to the BIOS. For the motherboard to "understand" the CPU's limits, the CPU and memory need to be stressed using Cinebench and/or other stress testing tools.

### 3️⃣ Stress Testing & AI Training

#### 3.1 Benchmate Stress Testing

Install and run [Benchmate](https://benchmate.org/) with the following benchmarks:

**Benchmarks to Run:**
- ✅ 7-Zip
- ✅ Cinebench 2024 (Single Core)
- ✅ Cinebench 2024 (Multi Core)
- ✅ PYPrime: 2B
- ✅ Super PI: 1M
- ✅ pifast: 10M
- ✅ wPrime: 32M

> ⚠️ **Note:** Some benchmarks may not run or may crash. If this happens, simply **IGNORE** it and try the next one.

#### 3.2 Cinebench Testing

Install [Cinebench 2024](https://www.maxon.net/en/downloads/cinebench-2024-downloads) and run:

- ✅ Cinebench 2024 (Single Core)
- ✅ Cinebench 2024 (Multi Core)

**After stress testing:**
1. Save the results in BenchMate (`F6`)
2. Restart your computer **5 times**

> 💡 With each restart, the motherboard will retrieve the data stored during the stress test and reconfigure the BIOS to optimize the CPU. You should see a gradual increase in processor and memory speed.

---

## 🖥️ **Phase 2: Windows Optimization**

### 4.1 Debloat Windows with Chris Titus Tech's Windows Utility

1. Open PowerShell as Administrator (`Win + X` → PowerShell Admin)
2. Run the following command:

```powershell
irm "https://christitus.com/win" | iex
```

3. Navigate and select what to uninstall, disable, or remove

### 4.2 O&O ShutUp10++ Privacy Settings

**Option A:** Go back to the TWEAKS tab in CTT and scroll to the bottom, click on **RUN OO SHUTUP 10**

**Option B:** Download [O&O ShutUp10++](https://www.oo-software.com/en/shutup10) directly

**Recommended Settings - Do NOT disable:**
- ❌ Disable search and website suggestions (removes history/suggestions of visited URLs)
- ❌ Disable Windows tracking of app starts (removes history from the Windows RUN window)

> 💡 Settings apply immediately when selected — no need to save/apply manually.

### 4.3 Install Essential Drivers Only

**ASUS Motherboard Drivers:**
1. Visit [ASUS ROG Motherboards](https://rog.asus.com/motherboards)
2. Download and install:
   - ✅ Audio Driver
   - ✅ Chipset Driver
   - ✅ LAN Driver

**NVIDIA GPU Drivers:**
1. Visit [NVIDIA Driver Downloads](https://www.nvidia.com/en-us/geforce/drivers/)
2. Manually search for your GPU model
3. Install the **Game Ready** driver

### 4.4 Install DCS World

Download and install/reinstall DCS World.

> ⚠️ **IMPORTANT: Install DCS on a dedicated NVMe drive (e.g., `D:\`)!**
>
> ⚠️ **IMPORTANT: Move "Saved Games" folder to `D:\`!**
>
> 🚀 **This alone almost doubled 0.1% low FPS and 1% low FPS!**

### 4.5 Microsoft Defender Exclusions

Add all DCS-related folders to be excluded from Microsoft Defender scanning:

1. `Win + X` → Settings
2. Navigate to: **Windows Security** → **Virus & threat protection** → **Manage settings** → **Add or remove exclusions**

**Recommended Exclusions:**

```
C:\Program Files (x86)\CapFrameX
C:\Program Files (x86)\NVIDIA Corporation
C:\Program Files (x86)\RivaTuner Statistics Server
C:\Program Files (x86)\Tacview
C:\Program Files\AutoHotkey
C:\Program Files\Eagle Dynamics
C:\Program Files\Notepad++
C:\Program Files\NVIDIA Corporation
C:\Program Files\nvidiaProfileInspector
C:\Program Files\obs-studio
C:\Program Files\OpenXR-Quad-Views-Foveated
C:\Program Files\OpenXR-Toolkit
C:\Program Files\Pimax
C:\Program Files\PimaxXR
C:\Program Files\Process Lasso
C:\Program Files\XRFrameTools
C:\ProgramData\DCS-SimpleRadio-Standalone
C:\Users\<YourUser>\Documents\CapFrameX
C:\Users\<YourUser>\Documents\Tacview
D:\Program Files\Eagle Dynamics\DCS World
D:\Users\<YourUser>\Saved Games\DCS
```

---

## ✈️ **Phase 3: DCS Optimization**

### 5.1 Move "Saved Games" Folder to D:\

1. Right-click the "Saved Games" folder → **Properties** → **Location**
2. Select: `D:\Users\<YourUser>\Saved Games`
3. Click **Apply**

### 5.2 NVIDIA Profile Inspector

Download [NVIDIA Profile Inspector](https://github.com/Orbmu2k/nvidiaProfileInspector) and configure:

**Recommended Settings:**
| Setting | Value |
|---------|-------|
| SR: Latest DLL | Off |
| SR: Preset | Latest Preset (v310+) |
| RR: Latest DLL | Off |
| RR: Preset | Latest Preset (v310+) |
| Maximum Pre-Rendered Frames | 1 |
| Ultra Low Latency - CPL State | Ultra |
| Ultra Low Latency - Enabled | On |
| PhysX - Indicator Overlay | Off |
| Power Management - Mode | Prefer maximum performance |

### 5.3 MSConfig - Disable Non-Microsoft Services

1. Press `Win + R`
2. Type `msconfig` and press Enter
3. Go to **Services** tab
4. Check **"Hide All Microsoft Services"**
5. Click **"Disable All"**
6. Go to **Startup** tab → **Open Task Manager**
7. Select each startup item and click **"Disable"**

### 5.4 Disable Non-Essential Windows Services

> 💡 **Pro Tip:** Use DCS-Max's built-in service optimization scripts instead of manual configuration!

```powershell
# Run the DCS-Max service optimization script
.\5-Optimization\5.3.2-services-optimize.ps1
```

**Manual Alternative:**
1. Press `Win + R` → type `services.msc`
2. Go to **Action** → **Export List** → Save as `Services1.txt`
3. Use AI tools to analyze which services can be safely disabled for gaming

> ⚠️ **IMPORTANT:** Always evaluate recommendations carefully before applying!

### 5.5 Export.lua - Reduce Stutters

Rename or delete the `Export.lua` file from the DCS Scripts folder to reduce crashes.

> ⚠️ **Note:** This is the file in the **Program Files** folder, NOT the "Saved Games" folder!

```powershell
# Navigate to DCS Scripts folder
cd "D:\Program Files\Eagle Dynamics\DCS World\Scripts"

# Rename the file
Rename-Item -Path "Export.lua" -NewName "_OLD_Export.lua"
```

### 5.6 Disable Hardware-Accelerated GPU Scheduling (HAGS)

1. Go to: **Settings** → **System** → **Display** → **Graphics** → **Change default graphics settings**
2. Turn **OFF** the "Hardware Accelerated GPU Scheduling" option
3. **Restart** your computer

> ⚠️ **Note:** This is controversial — some systems may run better with HAGS **ON**. Test both configurations!

### 5.7 Delete Temporary NVIDIA and DCS Shader Files

Clear shader caches for a fresh start:

**NVIDIA Cache Folders:**
```
%LOCALAPPDATA%\NVIDIA\DXCache
%LOCALAPPDATA%\NVIDIA\GLCache
%LOCALAPPDATA%\NVIDIA\ShaderCache
%LOCALAPPDATA%\NVIDIA\OptixCache
%LOCALAPPDATA%\NVIDIA Corporation\NV_CrashDump
%LOCALAPPDATA%\NVIDIA Corporation\NvTelemetry
```

**DCS Cache Folders:**
```
%USERPROFILE%\Saved Games\DCS\fxo
%USERPROFILE%\Saved Games\DCS\metashaders2
```

> 💡 **Pro Tip:** Use DCS-Max's cache cleaning script:
> ```powershell
> .\5-Optimization\5.4.1-clean-caches.ps1
> ```

---

## 🧪 **Phase 4: Performance and Stability Testing**

By this point, you should see significant stutter reduction. For deeper optimization:

### 6.1 Verify CPU is Idle

DCS, especially with VR, is **EXTREMELY** sensitive to background processes. Any CPU usage can cause stutters.

**Testing Procedure:**
1. Restart your computer
2. Visit [TestUFO Animation Time Graph](https://testufo.com/animation-time-graph)
3. Check if the line shows minimal variations
4. If variations exist, find and disable background processes

### 6.2 Use Specialized Testing Software

> 💡 **Don't trust your senses!** Human perception is prone to errors and bias. Even opening the FPS window in DCS impacts performance.

**Recommended Tools:**
- ✅ **CapFrameX** — For screen/monitor testing
- ✅ **XRFrameTools** or **CapFrameX** — For VR testing

**Testing Workflow:**
1. Register data
2. Look for patterns
3. Experiment with settings
4. Repeat

### 6.3 CapFrameX Benchmarking

[CapFrameX](https://www.capframex.com/) allows you to capture frame rate measurements during a session and compare them to another — ideal for measuring the impact of any configuration change.

**The Gold Standard:**
- Low frame times (e.g., ≤15ms) for 99.8% of the session
- This means 99.8% of frames render in under 15ms

**Testing Procedure:**

1. **Record a track in DCS** on a heavy map with many flying units or ground activity
2. **Keep it short** (~2 minutes) but stressful to quickly test changes
3. **Run the track** while capturing with CapFrameX
4. **Review results** in CapFrameX's comparison screen
5. **Document changes** between each session

### 📊 Performance Tier Classification

Use the 99.8% Frame Time Percentile and 0.2% FPS Percentile to classify your results:

| Tier | 99.8% Frame Time Percentile | 0.2% FPS Percentile |
|:----:|:---------------------------:|:-------------------:|
| 🥇 #1 | ≤11.11ms | ≥90.00 FPS |
| 🥈 #2 | ≤13.88ms | ≥72.00 FPS |
| 🥉 #3 | ≤15.49ms | ≥64.70 FPS |
| #4 | ≤22.99ms | ≥43.00 FPS |
| #5 | ≤23.99ms | ≥41.00 FPS |

### 📈 Understanding the Metrics

**Tier #1 Analysis:**
- To run at **90 FPS**, frame times must be **< 11.11ms**
- Any frame time **> 11.11ms** results in **< 90 FPS** — this causes stutters
- If **99.8%** of frames have frame times **≤ 11.11ms**, the session is smooth
- The **0.2% worst frames** determine your perceived stutter level

> 🎯 **Your Goal:** You cannot eliminate stutters entirely or maintain perfect FPS at all times — that's impossible! Instead, aim to **minimize the 0.2% low FPS metric**.

---

## 🆘 **Need Help?**

- Check the [Troubleshooting Guide](troubleshooting.md)
- Review the [Performance Optimizations](performance-optimizations.md) documentation
- Use DCS-Max's automated scripts for consistent results

---

**🛩️ Hope this helps! Happy flying with maximum performance!**

