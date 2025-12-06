# Changelog

   06 dec 2025
### [DCS-Max 1.3.0](https://github.com/thomas-barrios/dcs-max) - "Compact Testing" UI Optimization & Configuration Overhaul


### DCS-Max Core


Performance Testing & Configuration

- Added: Compact Test Settings UI - Redesigned settings rows to reduce vertical space by ~60%
  - Settings displayed in table-like rows with collapsible value selection
  - Auto-expand on enable, auto-collapse on disable for better UX
  - Impact level and restart requirement indicators
  - Filter by performance impact (HIGH/MEDIUM/LOW/NONE) and restart requirement
- Added: JSON-based configuration system (testing-configuration.json)
  - Replaces legacy INI file format with structured JSON configuration
  - Full support for VR settings, timing calibration, and mission selection
- Changed: Performance impact colors - discrete text-only badges for clarity
- Fixed: Empty status display on benchmark completion (now shows "Benchmark completed!" with green checkmark)
- Removed: Legacy INI file fallback support - app now exclusively uses JSON configuration
- Deprecated: 4.1.1-dcs-testing-configuration.ini (renamed to _DEPRECATED_4.1.1-dcs-testing-configuration.ini)


DCS Settings Schema

- Updated: All 51 graphics settings descriptions shortened to avoid truncation
  - Descriptions now ~25-45 characters for optimal UI display
  - Examples: "Level of detail for buildings and structures" → "Building and structure detail level"
- Added: Full acronym names for technical settings
  - SSAO: "SSAO (Screen Space Ambient Occlusion)"
  - SSLR: "SSLR (Screen Space Local Reflections)"


Benchmark Missions

- Renamed: Mission files with aircraft-appropriate prefixes:
  - PB-caucasus-ordzhonikidze → Su25-caucasus-ordzhonikidze (Su-25 Frogfoot)
  - PB-caucasus-tibilisi → F18-caucasus-tibilisi (F/A-18C Hornet)
  - PB-syria-telaviv → F18-syria-telaviv (F/A-18C Hornet)
- Updated: All references across UI components and automation scripts


Cleanup & Deprecation

- Removed: test-json.ahk (unused test file)
- Removed: ui-app/build.ps1 (unused build script)
- Removed: INI file handling from PerformanceTesting, Benchmarking, and automation scripts
- Added: Deprecation comments to legacy code paths


   04 dec 2025
### [DCS-Max 1.2.2](https://github.com/thomas-barrios/dcs-max) - "Viper" Bug Fixes & Automation Enhancements


### DCS-Max Core


Bug Fixes

- Fixed: Install Required Software - "Checking installed Software" would spin indefinitely (5-10+ minutes) without detecting installed applications
- Fixed: CapFrameX installation process hanging for 10+ minutes with no progress
- Fixed: Software detection inconsistency where apps showed as "Found" in Settings but not detected in Install panel
- Fixed: DCS path and other settings reverting to defaults after saving and navigating away
- Fixed: GPU detection incorrectly showing DisplayLink USB Device instead of actual GPU
- Fixed: RAM reporting showing 62GB instead of actual 64GB
- Fixed: Missing benchmark mission file error for PB-caucasus-tbilisi-multiplayer mission


### DCS-Max UI Application


- Added: Build & Run Script (build-and-run.ps1) - One-click build and launch for developers
  - Automatically closes existing DCS-Max instances before launching
  - Supports -NoBuild flag to skip compilation
  - Graceful process termination with timeout handling
- Changed: Various improvements to Benchmarking, InstallSoftware, and SettingsPanel components


### Optimization Scripts


- Added: Microsoft Defender Exclusions Script (2.7.2-Enable-Microsoft-Defender-Exclusions.ps1)
  - Adds DCS paths to Windows Defender exclusions for improved performance
- Changed: Install Software Script - Updated installation procedures


### Benchmark Automation


- Added: New single-player benchmark mission (Su25-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz)
- Changed: Enhanced logging and debugging capabilities in 4.1.2-dcs-testing-automation.ahk
- Changed: Improved settings verification workflow
- Changed: Better file I/O retry mechanisms with exponential backoff
- Removed: Deprecated multiplayer benchmark mission (replaced with clearer naming)


   02 dec 2025
### [DCS-Max 1.2.1](https://github.com/thomas-barrios/dcs-max) - "Viper" Release Cleanup


### DCS-Max Core


Release Preparation

- Added: Release Builder Script (create-release.ps1) - Automated release packaging
  - Creates clean ZIP with only user-needed files
  - Outputs to DCS-Max-Releases/ folder (outside project)
  - Excludes dev files, node_modules, source code
- Changed: Renamed Assets/ folder to lib/ - Industry-standard naming for shared utilities
- Removed: sample-ini-reader.ps1 - Obsolete prototype code
- Removed: DCS-Max.sln - Unused Visual Studio solution file
- Removed: 4-Performance-Testing/_FUTURE_4.1.4-checkpoint.txt - Empty placeholder file


Release Package Contents

- Compiled UI app (~1.7 MB)
- All PowerShell optimization scripts
- Benchmark missions
- Documentation and guides
- Total: ~26 MB zipped


   01 dec 2025
### [DCS-Max 1.2.0](https://github.com/thomas-barrios/dcs-max) - "Viper" UI Release


Introducing DCS-Max Graphical User Interface - Modern Electron-based UI application making performance optimization accessible to all users without requiring command-line expertise.


### DCS-Max UI Application


- Added: Complete Electron-Based UI Application
  - Modern Dashboard with system information and quick actions
  - Backup/Restore Manager with one-click operations and history viewer
  - Optimization Panel with visual service/task/registry management
  - Benchmark Dashboard with real-time progress tracking
  - Advanced Log Viewer with search, filter, and live monitoring
  - Settings Panel with path configuration and dependency checks
- Added: Dark Theme optimized for gaming environments
- Added: Real-Time Output streaming from PowerShell scripts
- Added: Progress Tracking for long-running operations
- Added: INI Configuration Editor with syntax highlighting
- Added: Admin Privilege Detection with visual warnings
- Added: Responsive Design for various screen sizes


Technical Implementation

- Electron 28 for cross-platform desktop framework
- React 18 for modern component-based UI
- Vite 5 for fast development and building
- Tailwind CSS for beautiful, consistent styling
- Lucide React for high-quality icons
- IPC Communication for secure PowerShell integration


Installation & Distribution

- Added: Automated Installer (install.bat / install.ps1)
- Added: Development Mode with hot-reload for easy customization
- Added: Production Packaging for distributable Windows executables
- Added: Comprehensive Documentation (README, SETUP guides)


### DCS-Max Core


- Changed: Main README updated with UI installation instructions
- Changed: Project Structure now includes ui-app/ directory


Technical Requirements

- Node.js 18+ required for UI application
- ~200MB download for npm dependencies
- Supports Windows 10/11 with full feature compatibility
- Backward compatible with existing PowerShell scripts


   12 nov 2025
### [DCS-Max 1.1.0](https://github.com/thomas-barrios/dcs-max) - "Falcon" Initial Release


First public release of DCS-Max - A comprehensive DCS World performance powerhouse for maximum FPS, smoothness, and control.


### DCS-Max Core


- Added: Complete project restructuring with logical numeric naming convention
- Added: Professional documentation with README, Quick Start Guide, and comprehensive utility guides
- Added: Automated DCS benchmarking with 128+ graphics settings configurations
- Added: Safe system optimization scripts for Windows tasks, services, and registry
- Added: Comprehensive backup/restore system for all optimizations
- Added: CapFrameX integration for professional performance analysis
- Added: Template configurations for various optimization tools


System Optimization Tools

- 5.1.x - Windows Registry optimization (backup, optimize, restore)
- 5.2.x - Windows Tasks optimization (backup, optimize, restore)
- 5.3.x - Windows Services optimization (backup, optimize, restore)


DCS-Specific Tools

- 1.4.x - DCS configuration backup and restore
- 1.4.3 - Automated DCS backup scheduling at logon
- 4.1.x - DCS benchmark automation with CapFrameX


Template System

- 3.1.0 - Windows unattended installation template
- 3.2.0 - WinUtil configuration
- 3.3.0 - O&O ShutUp10 configuration
- 3.4.0 - NVIDIA Profile Inspector settings
- 3.5.0 - Google Drive backup scheduling


Documentation

- Comprehensive README with project overview and quick links
- Quick Start Guide for 5-minute setup and immediate optimization
- Utility guides for Windows Unattended, WinUtil, and CapFrameX
- MIT License with safety disclaimers and contribution guidelines


Safety Enhancements

- Automatic backup creation before all system modifications
- Comprehensive error handling in all PowerShell scripts
- Validation checks to ensure operations complete successfully
- Restore capabilities for all optimization categories


Performance Features

- Intelligent restart management (DCS/Windows/None) based on setting requirements
- Checkpoint system for resuming interrupted benchmark sessions
- Comprehensive logging with timestamp and progress tracking
- Statistical analysis integration with CapFrameX


### Technical Specifications


- PowerShell 5.1+ required for system optimization scripts
- AutoHotkey v2.0 required for DCS automation features
- Windows 10/11 with Administrator privileges
- DCS World for DCS-specific optimization features
- CapFrameX for automated performance benchmarking


### Integration Points


- Windows unattended installation for clean system builds
- WinUtil integration for GUI-based Windows optimization
- O&O ShutUp10 for privacy and performance enhancements
- NVIDIA Profile Inspector for GPU-specific optimizations
- Google Drive for automated backup synchronization


### Expected Performance Improvements


- 15-30% FPS improvement through comprehensive optimization
- Significant stutter reduction via service and task optimization
- Faster loading times with disk I/O optimizations
- More stable VR performance with consistent frame timing


---

## Development History

This project evolved from extensive performance optimization research and testing within the DCS community. Initial development focused on solving frame rate and stability issues in VR environments, expanding to comprehensive system optimization.

Key Development Milestones:
- October 2025: Initial PowerShell automation scripts
- November 2025: AutoHotkey benchmark automation integration
- November 2025: Comprehensive system optimization suite
- November 2025: Public release preparation and restructuring
- December 2025: User Interface added for easy utilization no need for comand prompts

Community Contributions:
- Extensive testing by VR enthusiasts and competitive DCS pilots
- Performance optimization insights from system administrators
- Safety and reliability improvements based on user feedback


---

## License and Credits

Released under MIT License. See [LICENSE](LICENSE) file for details.

Special Thanks:
- DCS World community for performance optimization insights
- ChrisTitusTech for WinUtil integration possibilities
- CapFrameX developers for professional performance analysis tools
- AutoHotkey and PowerShell communities for scripting guidance

Disclaimer: This software modifies system-level settings. Always create backups and test on non-critical systems first.