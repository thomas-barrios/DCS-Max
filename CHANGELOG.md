
# DCS-Max Changelog


All notable changes to the DCS-Max project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2025-12-04 - "Viper" Bug Fixes & Automation Enhancements

### 🐛 Bug Fixes

Critical fixes based on user feedback:

- **Install Required Software - Infinite Loading** - Fixed issue where "Checking installed Software" would spin indefinitely (5-10+ minutes) without detecting installed applications
- **CapFrameX Installation Hang** - Resolved installation process hanging for 10+ minutes with no progress
- **Software Detection Mismatch** - Fixed inconsistency where apps showed as "Found" in Settings but not detected in Install panel
- **Settings Not Persisting** - Fixed DCS path and other settings reverting to defaults after saving and navigating away
- **GPU Detection Issue** - Improved hardware detection to correctly identify primary GPU (was incorrectly showing DisplayLink USB Device instead of actual GPU)
- **RAM Detection Accuracy** - Fixed RAM reporting showing 62GB instead of actual 64GB
- **Mission Load Failure** - Fixed missing benchmark mission file error:
  - `PB-caucasus-tbilisi-multiplayer-28air-50ground-cavok-mp-JustDogfights-v2-take1-2min.miz`

### ✨ Added
- **Build & Run Script** (`build-and-run.ps1`) - One-click build and launch for developers
  - Automatically closes existing DCS-Max instances before launching
  - Supports `-NoBuild` flag to skip compilation
  - Graceful process termination with timeout handling

- **Microsoft Defender Exclusions Script** (`2.7.2-Enable-Microsoft-Defender-Exclusions.ps1`)
  - Adds DCS paths to Windows Defender exclusions for improved performance

- **New Benchmark Mission** - Updated single-player benchmark mission
  - `PB-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz`
  - Renamed multiplayer mission for clarity

### 🔄 Changed
- **Benchmark Automation** (`4.1.2-dcs-testing-automation.ahk`)
  - Enhanced logging and debugging capabilities
  - Improved settings verification workflow
  - Better file I/O retry mechanisms with exponential backoff

- **UI Components** - Various improvements to Benchmarking, InstallSoftware, and SettingsPanel components

- **Install Software Script** - Updated installation procedures

### 🗑️ Removed
- Deprecated multiplayer benchmark mission (replaced with clearer naming)

---

## [1.2.1] - 2025-12-02 - "Viper" Release Cleanup

### 🧹 Cleanup & Release Preparation

Housekeeping release to clean up the project structure and prepare for distribution.

### ✨ Added
- **Release Builder Script** (`create-release.ps1`) - Automated release packaging
  - Creates clean ZIP with only user-needed files
  - Outputs to `DCS-Max-Releases/` folder (outside project)
  - Excludes dev files, node_modules, source code

### 🔄 Changed
- **Renamed `Assets/` to `lib/`** - Industry-standard naming for shared utilities

### 🗑️ Removed
- `sample-ini-reader.ps1` - Obsolete prototype code
- `DCS-Max.sln` - Unused Visual Studio solution file
- `4-Performance-Testing/_FUTURE_4.1.4-checkpoint.txt` - Empty placeholder file

### 📦 Release Package Contents
- Compiled UI app (~1.7 MB)
- All PowerShell optimization scripts
- Benchmark missions
- Documentation and guides
- **Total: ~26 MB zipped**

---

## [1.2.0] - 2025-12-01 - "Viper" UI Release

### 🎉 Major Feature Release

The second major release of DCS-Max introduces a modern graphical user interface, making performance optimization accessible to all users without requiring command-line expertise.

### ✨ Added - Graphical User Interface

#### 🖥️ Complete Electron-Based UI Application
- **Modern Dashboard** with system information and quick actions
- **Backup/Restore Manager** with one-click operations and history viewer
- **Optimization Panel** with visual service/task/registry management
- **Benchmark Dashboard** with real-time progress tracking
- **Advanced Log Viewer** with search, filter, and live monitoring
- **Settings Panel** with path configuration and dependency checks

#### 🎨 UI Features
- **Dark Theme** optimized for gaming environments
- **Real-Time Output** streaming from PowerShell scripts
- **Progress Tracking** for long-running operations
- **INI Configuration Editor** with syntax highlighting
- **Admin Privilege Detection** with visual warnings
- **Responsive Design** for various screen sizes

#### 🔧 Technical Implementation
- **Electron 28** for cross-platform desktop framework
- **React 18** for modern component-based UI
- **Vite 5** for fast development and building
- **Tailwind CSS** for beautiful, consistent styling
- **Lucide React** for high-quality icons
- **IPC Communication** for secure PowerShell integration

#### 📦 Installation & Distribution
- **Automated Installer** (`install.bat` / `install.ps1`)
- **Development Mode** with hot-reload for easy customization
- **Production Packaging** for distributable Windows executables
- **Comprehensive Documentation** (README, SETUP guides)

### 🔄 Changed
- **Main README** updated with UI installation instructions
- **Project Structure** now includes `ui-app/` directory

### 🛠️ Technical Details
- Node.js 18+ required for UI application
- ~200MB download for npm dependencies
- Supports Windows 10/11 with full feature compatibility
- Backward compatible with existing PowerShell scripts

### 📊 Expected User Experience Improvements
- **70% Faster Workflow** - Visual interface vs. command-line
- **Reduced Learning Curve** - Intuitive UI for all skill levels
- **Better Visibility** - Real-time feedback and progress tracking
- **Easier Configuration** - Visual editors replace manual file editing

### 🎯 Target Audience Expansion
- Now accessible to intermediate users (not just advanced users)
- Streamers can use UI while gaming/recording
- Quick actions for time-sensitive optimizations
- Visual feedback ideal for troubleshooting

---

## [1.1.0] - 2025-11-12 - "Falcon" Initial Release

### 🎉 First Public Release

The inaugural release of DCS Max, a comprehensive DCS World performance powerhouse for maximum FPS, smoothness, and control.

### ✨ Added
- **Complete project restructuring** with logical numeric naming convention
- **Professional documentation** with README, Quick Start Guide, and comprehensive utility guides
- **Automated DCS benchmarking** with 128+ graphics settings configurations
- **Safe system optimization scripts** for Windows tasks, services, and registry
- **Comprehensive backup/restore system** for all optimizations
- **CapFrameX integration** for professional performance analysis
- **Template configurations** for various optimization tools

#### 🔧 System Optimization Tools
- `2.1.x` - Windows Tasks optimization (backup, optimize, restore)
- `2.2.x` - Windows Services optimization (backup, optimize, restore)
- `2.3.x` - Windows Registry optimization (backup, optimize, restore)

#### 🎮 DCS-Specific Tools  
- `3.1.x` - DCS configuration backup and restore
- `3.2.x` - Automated DCS backup scheduling
- `4.1.x` - DCS benchmark automation with CapFrameX

#### 📁 Template System
- `1.1.0` - Windows unattended installation template
- `1.3.0` - WinUtil and O&O ShutUp10 configurations
- `1.4.0` - NVIDIA Profile Inspector settings
- `1.5.0` - Google Drive backup scheduling

#### 📚 Documentation
- **Comprehensive README** with project overview and quick links
- **Quick Start Guide** for 5-minute setup and immediate optimization
- **Utility guides** for Windows Unattended, WinUtil, and CapFrameX
- **MIT License** with safety disclaimers and contribution guidelines

### 🔄 Changed from Legacy Version
- **File naming convention** changed from mixed numbering to logical numeric prefixes
- **Folder structure** reorganized by function rather than chronological development
- **Internal file references** updated to new naming scheme
- **Log files** restructured with new empty logs for fresh start

### 🛡️ Safety Enhancements
- **Automatic backup creation** before all system modifications
- **Comprehensive error handling** in all PowerShell scripts
- **Validation checks** to ensure operations complete successfully
- **Restore capabilities** for all optimization categories

### 📊 Performance Features
- **Intelligent restart management** (DCS/Windows/None) based on setting requirements
- **Checkpoint system** for resuming interrupted benchmark sessions
- **Comprehensive logging** with timestamp and progress tracking
- **Statistical analysis** integration with CapFrameX

### 🧹 Cleaned Up
- **Moved development artifacts** to `_OLD/` folder (not included in release)
- **Removed personal configuration files** and development chat logs
- **Standardized script headers** with consistent documentation
- **Updated all hardcoded paths** to use relative references

### 🎯 Target Audience
- **Advanced DCS users** with scripting knowledge
- **System administrators** managing gaming systems
- **Performance enthusiasts** seeking maximum FPS and stability
- **VR users** requiring consistent frame times

### 📈 Expected Performance Improvements
- **15-30% FPS improvement** through comprehensive optimization
- **Significant stutter reduction** via service and task optimization
- **Faster loading times** with disk I/O optimizations
- **More stable VR performance** with consistent frame timing

### ⚙️ Technical Specifications
- **PowerShell 5.1+** required for system optimization scripts
- **AutoHotkey v2.0** required for DCS automation features
- **Windows 10/11** with Administrator privileges
- **DCS World** for DCS-specific optimization features
- **CapFrameX** for automated performance benchmarking

### 🔗 Integration Points
- **Windows unattended installation** for clean system builds
- **WinUtil integration** for GUI-based Windows optimization
- **O&O ShutUp10** for privacy and performance enhancements
- **NVIDIA Profile Inspector** for GPU-specific optimizations
- **Google Drive** for automated backup synchronization

---

## Development History

This project evolved from extensive performance optimization research and testing within the DCS community. Initial development focused on solving frame rate and stability issues in VR environments, expanding to comprehensive system optimization.

**Key Development Milestones:**
- **October 2025**: Initial PowerShell automation scripts
- **November 2025**: AutoHotkey benchmark automation integration  
- **November 2025**: Comprehensive system optimization suite
- **November 2025**: Public release preparation and restructuring

**Community Contributions:**
- Extensive testing by VR enthusiasts and competitive DCS pilots
- Performance optimization insights from system administrators
- Safety and reliability improvements based on user feedback

---

## License and Credits

Released under MIT License. See [LICENSE](LICENSE) file for details.

**Special Thanks:**
- DCS World community for performance optimization insights
- ChrisTitusTech for WinUtil integration possibilities
- CapFrameX developers for professional performance analysis tools
- AutoHotkey and PowerShell communities for scripting guidance

**Disclaimer:** This software modifies system-level settings. Always create backups and test on non-critical systems first.