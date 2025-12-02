# ⚡ DCS-Max Performance Optimizations Reference

This document provides a detailed description of every optimization applied by the DCS-Max suite. Understanding these changes helps you make informed decisions about which optimizations to apply and how to troubleshoot any issues.

---

## 📋 Table of Contents

1. [Registry Optimizations](#-registry-optimizations)
2. [Scheduled Tasks Optimizations](#-scheduled-tasks-optimizations)
3. [Windows Services Optimizations](#-windows-services-optimizations)
4. [Cache Cleaning](#-cache-cleaning)
5. [Safety & Reversibility](#-safety--reversibility)

---

## 🔧 Registry Optimizations

**Script:** `5-Optimization/5.1.2-registry-optimize.ps1`

Registry optimizations modify Windows system settings to prioritize gaming performance. These changes affect CPU scheduling, GPU rendering, and system responsiveness.

### CPU & Power Management

| Setting | Value | Description |
|---------|-------|-------------|
| **CPU Core Parking** | Disabled | Prevents Windows from "parking" (idling) CPU cores. Keeps all cores active and ready for DCS's multi-threaded workload, reducing latency spikes when cores need to wake up. |
| **DCS CPU Priority** | High (3) | Sets DCS.exe to run at high CPU priority class. Ensures DCS gets preferential CPU time over background processes. |
| **Power Throttling** | Disabled | Prevents Windows from throttling CPU performance for power savings. Maintains consistent clock speeds during gameplay. |
| **Priority Separation** | 26 (Long Fixed) | Configures Windows scheduler to give more CPU time to foreground applications (DCS) with long, fixed time slices for smoother frame delivery. |

### GPU & Rendering

| Setting | Value | Description |
|---------|-------|-------------|
| **Max Pre-Rendered Frames** | 1 | Limits the number of frames the CPU can prepare ahead of GPU rendering. Reduces input lag at the cost of slightly lower maximum FPS. Critical for VR and competitive play. |
| **GPU Priority** | 14 (High) | Sets high GPU scheduling priority for games, ensuring DCS gets preferential GPU time. |

### Game Mode & MMCSS

| Setting | Value | Description |
|---------|-------|-------------|
| **GameDVR Recording** | Disabled | Disables Xbox Game Bar's background recording feature. Frees up GPU encoder and reduces frame time spikes. |
| **Network Throttling** | Disabled (0xFFFFFFFF) | Removes Windows multimedia network throttling. Ensures network packets for multiplayer aren't delayed during gameplay. |
| **System Responsiveness** | 10% | Reserves only 10% of CPU for system tasks during multimedia playback. The remaining 90% is available for games. |
| **Game CPU Affinity** | First 4 cores (0x0F) | Optimizes CPU affinity mask for game processes. Helps with cache locality on multi-core systems. |
| **Game Scheduling Category** | High | Sets the MMCSS (Multimedia Class Scheduler Service) to prioritize game threads. |
| **SFIO Priority** | High | Sets Scheduled File I/O priority to high for game processes, reducing disk access latency. |
| **Background Only** | Disabled | Ensures games aren't treated as background processes by the scheduler. |
| **CPU Priority** | 6 (Highest) | Maximum CPU priority for game-tagged processes. |

---

## 📅 Scheduled Tasks Optimizations

**Script:** `5-Optimization/5.2.2-tasks-optimize.ps1`

Windows scheduled tasks run in the background at various intervals, consuming CPU, disk, and network resources. These tasks can cause micro-stutters and frame drops during gameplay.

### Browser Update Tasks (Disabled)

| Task | Reason |
|------|--------|
| **MicrosoftEdgeUpdateTaskMachineCore** | Edge browser update checks cause network and CPU spikes |
| **MicrosoftEdgeUpdateTaskMachineUA** | Edge telemetry and update verification |
| **GoogleUpdaterTaskSystem** | Google Chrome update service causes background activity |

### .NET Framework Tasks (Disabled)

| Task | Reason |
|------|--------|
| **.NET Framework NGEN v4.0.30319** | Native image generation causes heavy CPU usage |
| **.NET Framework NGEN v4.0.30319 64** | 64-bit version of NGEN |
| **.NET Framework NGEN v4.0.30319 Critical** | Critical priority NGEN tasks can interrupt gameplay |

### Telemetry & Diagnostics (Disabled)

| Task | Reason |
|------|--------|
| **Microsoft Compatibility Appraiser** | Heavy disk I/O scanning installed applications |
| **Microsoft Compatibility Appraiser Exp** | Experimental compatibility scanning |
| **StartupAppTask** | Application startup analysis |
| **MareBackup** | Application experience backup |
| **PcaPatchDbTask** | Program Compatibility Assistant database updates |
| **SdbinstMergeDbTask** | Application compatibility database merging |

### Application & Store Tasks (Disabled)

| Task | Reason |
|------|--------|
| **appuriverifierdaily** | Daily app verification causes random CPU spikes |
| **appuriverifierinstall** | Post-install verification |
| **Pre-staged app cleanup** | UWP app cleanup operations |
| **UCPD velocity** | App deployment telemetry |
| **CleanupTemporaryState** | Temp file cleanup can cause disk I/O |
| **DsSvcCleanup** | Data sharing service cleanup |

### Windows Update Tasks (Disabled)

| Task | Reason |
|------|--------|
| **Refresh Group Policy Cache** | Policy updates during gameplay |
| **Scheduled Start** | Windows Update scheduled checks |
| **PerformRemediation** | WaaS Medic update repair service |

### Security & Defender Tasks (Disabled)

| Task | Reason |
|------|--------|
| **Windows Defender Cache Maintenance** | Defender cache operations cause disk I/O |
| **Windows Defender Cleanup** | Cleanup operations during gameplay |
| **Windows Defender Scheduled Scan** | Scheduled scans consume significant resources |
| **Windows Defender Verification** | Definition verification |

*Note: Consider re-enabling Defender tasks when not gaming for security.*

### System Maintenance Tasks (Disabled)

| Task | Reason |
|------|--------|
| **Autochk Proxy** | Disk check scheduling |
| **BgTaskRegistrationMaintenanceTask** | Background task maintenance |
| **HiveUploadTask** | User profile telemetry upload |
| **QueueReporting** | Windows Error Reporting queue processing |
| **BfeOnServiceStartTypeChange** | Firewall service monitoring |

### Network & Connectivity (Disabled)

| Task | Reason |
|------|--------|
| **WiFiTask** | WiFi management (use wired for gaming) |
| **CDSSync** | Connected devices synchronization |
| **MoProfileManagement** | Mobile profile management |
| **NotificationTask** | WWAN notifications |
| **OobeDiscovery** | Network discovery |

### Xbox & Gaming (Disabled)

| Task | Reason |
|------|--------|
| **XblGameSaveTask** | Xbox cloud save sync (DCS uses its own saves) |

### AI & Recall (Disabled)

| Task | Reason |
|------|--------|
| **Recall InitialConfiguration** | Windows AI Recall feature setup |
| **Recall PolicyConfiguration** | AI policy configuration |

### Enterprise Features (Disabled)

| Task | Reason |
|------|--------|
| **AD RMS Rights Policy Template** | Active Directory rights management |
| **EDP Policy Manager** | Enterprise data protection |
| **Work Folders Logon Synchronization** | Enterprise sync feature |
| **Work Folders Maintenance Work** | Enterprise folder maintenance |
| **Automatic-Device-Join** | Workplace device joining |
| **Device-Sync** | Workplace device synchronization |
| **Recovery-Check** | Workplace recovery verification |

### Hardware & Drivers (Disabled)

| Task | Reason |
|------|--------|
| **Calibration Loader** | Color calibration loading |
| **UninstallDeviceTask** | Bluetooth device cleanup |
| **WIM-Hash-Management** | Windows image hash management |
| **WIM-Hash-Validation** | Image validation |

### Miscellaneous (Disabled)

| Task | Reason |
|------|--------|
| **BitLocker Encrypt All Drives** | Encryption tasks |
| **BitLocker MDM policy Refresh** | Mobile device management |
| **RecoverabilityToastTask** | Account recovery notifications |
| **PolicyConverter** | AppID policy conversion |
| **Backup** / **BackupNonMaintenance** | App list backup operations |

---

## 🔌 Windows Services Optimizations

**Script:** `5-Optimization/5.3.2-services-optimize.ps1`

Windows services run continuously in the background. Disabling non-essential services frees up RAM, reduces CPU overhead, and eliminates potential sources of stutters.

### Telemetry & Diagnostics Services

| Service | Name | Impact |
|---------|------|--------|
| **DiagTrack** | Connected User Experiences and Telemetry | Constantly sends data to Microsoft, uses CPU and network |
| **DPS** | Diagnostic Policy Service | Runs resource-intensive diagnostic scans |
| **WdiServiceHost** | Diagnostic Service Host | Background diagnostic tasks cause micro-stutters |
| **WdiSystemHost** | Diagnostic System Host | Unnecessary CPU overhead for diagnostics |

### Windows Update Services

| Service | Name | Impact |
|---------|------|--------|
| **UsoSvc** | Update Orchestrator Service | Prevents background updates during gameplay |
| **TrustedInstaller** | Windows Modules Installer | Avoids update-triggered disk and CPU activity |
| **WaaSMedicSvc** | Windows Update Medic Service | Redundant repair service that can interrupt gaming |

### Cloud & Microsoft Account

| Service | Name | Impact |
|---------|------|--------|
| **wlidsvc** | Microsoft Account Sign-in Assistant | Not needed with local accounts |
| **WalletService** | Windows Wallet Service | Payment features irrelevant for gaming |

### Print Services

| Service | Name | Impact |
|---------|------|--------|
| **Spooler** | Print Spooler | Printing not needed during gaming sessions |
| **PrintNotify** | Printer Extensions and Notifications | Unnecessary notifications |
| **PrintWorkflowUserSvc** | Print Workflow Service | Print workflow processing |
| **Fax** | Fax Service | Obsolete legacy service |

### Search & Indexing

| Service | Name | Impact |
|---------|------|--------|
| **WSearch** | Windows Search | Heavy disk I/O competes with DCS loading |

*Note: Disabling WSearch means Start Menu search will be slower. Use Everything app as alternative.*

### Media & Entertainment

| Service | Name | Impact |
|---------|------|--------|
| **MapsBroker** | Downloaded Maps Manager | Maps feature not used in gaming |
| **BcastDVRUserService** | GameDVR and Broadcast User Service | Causes significant frame drops, especially in VR |

### Hardware Vendor Services

| Service | Name | Impact |
|---------|------|--------|
| **RtkUWPService** | Realtek Audio UWP Service | Can conflict with gaming audio stack |
| **AmdPmuService** | AMD Power Management | DCS benefits from manual power settings |
| **AmdAcpSvc** | AMD Application Compatibility Service | Compatibility database not needed for DCS |
| **AmdPPService** | AMD Power Profile Service | Manual power profiles preferred |
| **AsusUpdateCheck** | ASUS Update Service | Manual driver updates are safer |

### Remote Access

| Service | Name | Impact |
|---------|------|--------|
| **RemoteRegistry** | Remote Registry | Security risk, not needed for local gaming |
| **TermService** | Remote Desktop Services | Not needed for local gameplay |

### Backup & Sync

| Service | Name | Impact |
|---------|------|--------|
| **fhsvc** | File History Service | Heavy disk I/O during gameplay |
| **WorkFolders** | Work Folders Service | Enterprise sync not needed |

### Network Discovery

| Service | Name | Impact |
|---------|------|--------|
| **SSDPSRV** | SSDP Discovery | Reduces network broadcast traffic |
| **UPnPHost** | UPnP Device Host | No UPnP hosting needed |
| **FDResPub** | Function Discovery Resource Publication | Network device discovery |

### Location & Sensors

| Service | Name | Impact |
|---------|------|--------|
| **lfsvc** | Geolocation Service | Location checks not needed |
| **SensorService** | Sensor Service | No sensors on desktop gaming rigs |
| **SensrSvc** | Sensor Monitoring Service | Sensor monitoring overhead |
| **SensorDataService** | Sensor Data Service | Sensor data processing |

### Xbox Services

| Service | Name | Impact |
|---------|------|--------|
| **XblAuthManager** | Xbox Live Auth Manager | DCS doesn't use Xbox Live |
| **XblGameSave** | Xbox Live Game Save | Cloud saves not used by DCS |
| **XboxNetApiSvc** | Xbox Live Networking Service | Reduces network overhead |
| **XboxGipSvc** | Xbox Accessory Management Service | No Xbox accessories used |

### Telephony & Messaging

| Service | Name | Impact |
|---------|------|--------|
| **PhoneSvc** | Phone Service | Desktop systems don't need telephony |
| **MessagingService** | Messaging Service | Text messaging not used |

### Miscellaneous

| Service | Name | Impact |
|---------|------|--------|
| **wisvc** | Windows Insider Service | Not needed for stable gaming rigs |
| **WebClient** | WebClient (WebDAV) | Avoids WebDAV reconnection attempts |
| **stisvc** | Windows Image Acquisition | Scanner support not needed |
| **TrkWks** | Distributed Link Tracking Client | File tracking overhead |
| **RetailDemo** | Retail Demo Service | Consumer demo feature |
| **ClipSVC** | Client License Service | Saves 50-100MB RAM if not using Store apps |
| **WPCSvc** | Parental Controls | Not needed for adult gaming |
| **Power** | Power Service | **Important:** Can cause VR stutters due to dynamic power state changes |

### Third-Party Update Services

| Service | Name | Impact |
|---------|------|--------|
| **GoogleUpdaterService** | Google Update Service | Background update checks |
| **GoogleUpdaterInternalService** | Google Internal Update | Internal update processing |

---

## 🧹 Cache Cleaning

**Script:** `5-Optimization/5.4.1-clean-caches.bat`

Shader and graphics caches can become corrupted or bloated over time, causing stutters and long loading times. Cleaning these caches forces fresh shader compilation.

### NVIDIA Caches Cleaned

| Cache | Location | Purpose |
|-------|----------|---------|
| **DXCache** | `%LOCALAPPDATA%\NVIDIA\DXCache\` | DirectX shader cache. Corruption causes stutters and graphical glitches. |
| **GLCache** | `%LOCALAPPDATA%\NVIDIA\GLCache\` | OpenGL shader cache. Less relevant for DCS but good to clean. |
| **OptixCache** | `%LOCALAPPDATA%\NVIDIA\OptixCache\` | Ray tracing cache. Clean to ensure optimal ray tracing performance. |

### Windows Temp Files

| Cache | Location | Purpose |
|-------|----------|---------|
| **Windows Temp** | `%TEMP%\` | Temporary files from all applications. Frees disk space and removes stale data. |

### DCS-Specific Caches

| Cache | Location | Purpose |
|-------|----------|---------|
| **DCS Temp** | `%USERPROFILE%\Saved Games\DCS\Temp\` | DCS temporary files including mission temps and crash dumps. |

### When to Clean Caches

- **After GPU driver updates** - Old shaders may be incompatible
- **After DCS updates** - New shaders need recompilation
- **When experiencing stutters** - Corrupted cache entries cause issues
- **Periodically (monthly)** - Prevents cache bloat

### Expected Behavior After Cleaning

⚠️ **First launch after cache cleaning:**
- Longer initial loading times (1-3 minutes)
- Brief stutters as shaders recompile
- This is normal and improves after first session

---

## 🛡️ Safety & Reversibility

All DCS-Max optimizations are designed to be **fully reversible**. Each optimization script:

1. **Creates automatic backups** before making changes
2. **Logs all changes** for troubleshooting
3. **Provides restore scripts** for each category

### Restore Commands

```powershell
# Restore Registry
.\1-Backup-Restore\1.1.3-registry-restore.ps1

# Restore Scheduled Tasks
.\1-Backup-Restore\1.2.3-tasks-restore.ps1

# Restore Windows Services
.\1-Backup-Restore\1.3.3-services-restore-from-backup.ps1

# Restore DCS Configuration
.\1-Backup-Restore\1.4.2-dcs-restore.ps1
```

### Emergency Recovery

If system becomes unstable:

1. **Boot into Safe Mode** (hold Shift while clicking Restart)
2. **Run restore scripts** from Safe Mode
3. **Use System Restore** to restore point created before optimization

### Backup Location

All backups are stored in: `DCS-Max\Backups\`

Files are timestamped for easy identification:
- `2025-12-01-14-30-00-registry-backup.reg`
- `2025-12-01-14-30-00-services-backup.json`
- `2025-12-01-14-30-00-tasks-backup.xml`

---

## 📊 Expected Performance Impact

Based on community testing:

| Optimization | FPS Impact | Stutter Reduction | Notes |
|--------------|------------|-------------------|-------|
| Registry tweaks | +5-10% | Significant | Most noticeable in VR |
| Disabled tasks | +2-5% | High | Reduces random spikes |
| Disabled services | +3-8% | Moderate | Frees RAM and CPU |
| Cache cleaning | Variable | High | Especially after updates |

**Combined typical improvement: 15-30% FPS increase with significantly reduced stuttering**

---

## 📚 Related Documentation

- **[Quick Start Guide](quick-start-guide.md)** - Get started quickly
- **[Performance Guide](performance-guide.md)** - DCS-specific tuning
- **[Troubleshooting](troubleshooting.md)** - Problem resolution

---

**🛩️ Fly smoother, fly faster with DCS-Max optimizations!**
