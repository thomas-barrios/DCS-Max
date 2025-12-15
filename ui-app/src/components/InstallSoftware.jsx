import React, { useState, useEffect } from 'react';
import { 
  Download,
  CheckCircle,
  XCircle,
  AlertCircle,
  Package,
  ExternalLink,
  Loader,
  FolderOpen,
  RefreshCw,
  Save,
  Scan
} from 'lucide-react';

// Path configuration fields - split into DCS and Software paths
const dcsPathFields = [
  { key: 'dcsPath', label: 'DCS World Executable', required: true },
  { key: 'savedGamesPath', label: 'DCS Saved Games Folder', required: true, isFolder: true }
];

const softwarePathFields = [
  { key: 'capframexPath', label: 'CapFrameX', required: false, statusKey: 'capframex' },
  { key: 'autoHotkeyPath', label: 'AutoHotkey v2', required: false, statusKey: 'autohotkey' },
  { key: 'notepadppPath', label: 'Notepad++', required: false, statusKey: 'notepadpp' }
];

const pathFields = [...dcsPathFields, ...softwarePathFields];

const requiredSoftware = [
  {
    id: 'capframex',
    name: 'CapFrameX',
    description: 'Performance benchmarking and analysis tool',
    wingetId: 'CXWorld.CapFrameX',
    website: 'https://www.capframex.com/',
    required: true,
    portable: true  // Always installs as portable, needs Start Menu shortcut
  },
  {
    id: 'autohotkey',
    name: 'AutoHotkey v2',
    description: 'Automation scripting for benchmark workflows',
    wingetId: 'AutoHotkey.AutoHotkey',
    website: 'https://www.autohotkey.com/',
    required: true,
    portable: false
  },
  {
    id: 'notepadpp',
    name: 'Notepad++',
    description: 'Log viewer and configuration editor',
    wingetId: 'Notepad++.Notepad++',
    website: 'https://notepad-plus-plus.org/',
    required: true,
    portable: false
  }
];

function InstallSoftware() {
  const [installing, setInstalling] = useState(null);
  const [installStatus, setInstallStatus] = useState({});
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [output, setOutput] = useState('');
  
  // VR Configuration state (simplified)
  const [vrEnabled, setVrEnabled] = useState(false);
  const [vrRuntimePath, setVrRuntimePath] = useState('');
  const [vrDetecting, setVrDetecting] = useState(false);
  
  // Path configuration state
  const [settings, setSettings] = useState({
    dcsPath: '',
    savedGamesPath: '',
    capframexPath: '',
    autoHotkeyPath: '',
    notepadppPath: '',
    benchmarkMissionPath: ''
  });
  const [pathStatus, setPathStatus] = useState({});
  const [pathSources, setPathSources] = useState({});
  const [projectRoot, setProjectRoot] = useState('');  
  const [checkingPaths, setCheckingPaths] = useState(false);
  
  // CapFrameX hotkey configuration state
  const [capframexHotkeyConfigured, setCapframexHotkeyConfigured] = useState(false);
  const [checkingCapframexHotkey, setCheckingCapframexHotkey] = useState(false);
  const skipHotkeyCheckRef = React.useRef(false);
  
  // Ref for output console auto-scroll
  const outputRef = React.useRef(null);

  useEffect(() => {
    initializeAll();
  }, []);
  
  // Auto-scroll to output when installation starts or output changes
  useEffect(() => {
    if (output && outputRef.current) {
      outputRef.current.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, [output, installing]);

  const JSON_CONFIG_PATH = 'config-tests.json';
  const GLOBAL_CONFIG_PATH = 'config-global.json';

  const initializeAll = async () => {
    setCheckingStatus(true);
    let root = '';
    
    // Get project root
    try {
      const rootResult = await window.dcsMax.getProjectRoot();
      if (rootResult.success) {
        root = rootResult.path;
        setProjectRoot(root);
      }
    } catch (err) {
      console.error('Failed to get project root:', err);
    }

    const newSettings = { ...settings };
    const sources = {};

    // Helper to check if a path value is a placeholder (not a real path)
    const isPlaceholder = (value) => !value || value === 'auto' || value === '' || value.toLowerCase() === 'auto';

    // Load paths from global config and test config
    try {
      // Load global config for paths
      const globalResult = await window.dcsMax.readJsonConfig(GLOBAL_CONFIG_PATH);
      if (globalResult.success && globalResult.data?.paths) {
        const paths = globalResult.data.paths;

        // Map JSON keys to settings keys (ignore placeholder values)
        if (paths.dcsExe && !isPlaceholder(paths.dcsExe)) {
          newSettings.dcsPath = paths.dcsExe;
          sources.dcsPath = 'config';
        }
        if (paths.savedGamesPath && !isPlaceholder(paths.savedGamesPath)) {
          newSettings.savedGamesPath = paths.savedGamesPath;
          sources.savedGamesPath = 'config';
        }
        if (paths.capframexFolder && !isPlaceholder(paths.capframexFolder)) {
          // Note: capframexFolder is used by AutoHotkey for JSON file location, not for launching
          // UI uses detected paths for CapFrameX launching to avoid conflicts
          // newSettings.capframexPath = paths.capframexFolder;
          // sources.capframexPath = 'config';
        }
        if (paths.notepadpp && !isPlaceholder(paths.notepadpp)) {
          newSettings.notepadppPath = paths.notepadpp;
          sources.notepadppPath = 'config';
        }
        if (paths.pimax && !isPlaceholder(paths.pimax)) {
          newSettings.pimaxPath = paths.pimax;
          sources.pimaxPath = 'config';
        }
        if (paths.autohotkey && !isPlaceholder(paths.autohotkey)) {
          newSettings.autoHotkeyPath = paths.autohotkey;
          sources.autoHotkeyPath = 'config';
        }
      }

      // Load VR settings from global config
      if (globalResult.success && globalResult.data?.vr) {
        const vr = globalResult.data.vr;
        if (vr.enabled && vr.runtimePath && !isPlaceholder(vr.runtimePath)) {
          setVrEnabled(true);
          setVrRuntimePath(vr.runtimePath);
        } else {
          setVrEnabled(false);
          setVrRuntimePath('');
        }
      }

      // Load test config for mission settings
      const testResult = await window.dcsMax.readJsonConfig(JSON_CONFIG_PATH);
      if (testResult.success && testResult.data?.testConfiguration) {
        const testConfig = testResult.data.testConfiguration;

        // Benchmark mission (stored as filename only, relative to benchmark-missions folder)
        if (testConfig.mission && !isPlaceholder(testConfig.mission)) {
          newSettings.benchmarkMissionPath = testConfig.mission;
          sources.benchmarkMissionPath = 'config';
        }
      }
    } catch (err) {
      console.error('Failed to read settings from JSON:', err);
    }

    // Detect paths and check software status (this also checks CapFrameX hotkey)
    await checkInstalledSoftware(newSettings, sources, root);
  };

  const checkInstalledSoftware = async (currentSettings = settings, currentSources = pathSources, root = projectRoot) => {
    setCheckingStatus(true);
    const status = {};
    const newSettings = { ...currentSettings };
    const sources = { ...currentSources };
    
    try {
      const pathsResult = await window.dcsMax.detectPaths();
      
      if (pathsResult.success && pathsResult.paths) {
        // Update DCS path if not already set from INI
        const dcsPath = pathsResult.paths.dcsPath;
        if (!newSettings.dcsPath && dcsPath?.path) {
          newSettings.dcsPath = dcsPath.path;
          sources.dcsPath = dcsPath.found ? `detected (${dcsPath.source})` : 'default';
        }
        
        // Update DCS Saved Games path if not already set from INI
        const dcsSavedGames = pathsResult.paths.dcsSavedGamesPath;
        if (!newSettings.savedGamesPath && dcsSavedGames?.path) {
          newSettings.savedGamesPath = dcsSavedGames.path;
          sources.savedGamesPath = dcsSavedGames.found ? `detected (${dcsSavedGames.source})` : 'default';
        }
        
        // Check required software - ALWAYS use detected path (override saved config)
        const capframex = pathsResult.paths.capframexPath;
        status['capframex'] = capframex?.found ? 'installed' : 'not-installed';
        if (capframex?.path) {
          // Always prefer fresh detection over saved config
          newSettings.capframexPath = capframex.path;
          sources.capframexPath = capframex.found ? `detected (${capframex.source})` : 'default';
        }
        
        const autohotkey = pathsResult.paths.autoHotkeyPath;
        status['autohotkey'] = autohotkey?.found ? 'installed' : 'not-installed';
        if (autohotkey?.path) {
          newSettings.autoHotkeyPath = autohotkey.path;
          sources.autoHotkeyPath = autohotkey.found ? `detected (${autohotkey.source})` : 'default';
        }
        
        const notepadpp = pathsResult.paths.notepadppPath;
        status['notepadpp'] = notepadpp?.found ? 'installed' : 'not-installed';
        if (notepadpp?.path) {
          newSettings.notepadppPath = notepadpp.path;
          sources.notepadppPath = notepadpp.found ? `detected (${notepadpp.source})` : 'default';
        }
      } else {
        for (const software of requiredSoftware) {
          status[software.id] = 'unknown';
        }
      }
    } catch (err) {
      console.error('Path detection error:', err);
      for (const software of requiredSoftware) {
        status[software.id] = 'unknown';
      }
    }
    
    setSettings(newSettings);
    setPathSources(sources);
    setInstallStatus(status);
    setCheckingStatus(false);
    
    // Verify all paths
    verifyAllPaths(root, newSettings);
    
    // Check CapFrameX hotkey if installed (but skip if we just configured it)
    if (status['capframex'] === 'installed' && !skipHotkeyCheckRef.current) {
      setTimeout(() => checkCapFrameXHotkey(status['capframex']), 500);
    }
    // Reset the skip flag
    skipHotkeyCheckRef.current = false;
    
    // Return the new settings so callers can use them immediately
    return newSettings;
  };

  // Path verification functions
  const verifyAllPaths = async (root = projectRoot, currentSettings = null) => {
    setCheckingPaths(true);
    const status = {};
    
    // Always use the current settings state to avoid stale values
    const settingsToUse = currentSettings || settings;
    
    for (const field of pathFields) {
      const path = settingsToUse[field.key];
      if (path) {
        status[field.key] = await verifyPath(path, field.isFolder, field.isRelative, root);
      } else {
        status[field.key] = 'empty';
      }
    }
    
    setPathStatus(status);
    setCheckingPaths(false);
  };

  const verifyPath = async (path, isFolder = false, isRelative = false, root = projectRoot) => {
    try {
      let fullPath = path;
      
      // Handle relative paths (like benchmark missions)
      if (isRelative && !path.includes(':') && root) {
        fullPath = `${root}\\4-Performance-Testing\\benchmark-missions\\${path}`;
      }
      
      // Use PowerShell to expand environment variables and test path
      const testCommand = isFolder 
        ? `$p = [Environment]::ExpandEnvironmentVariables('${fullPath}'); Test-Path -Path $p -PathType Container`
        : `$p = [Environment]::ExpandEnvironmentVariables('${fullPath}'); Test-Path -Path $p -PathType Leaf`;
      
      const result = await window.dcsMax.executeCommand(testCommand);
      return result.stdout && result.stdout.trim().toLowerCase() === 'true' ? 'valid' : 'invalid';
    } catch (err) {
      console.error('Path verification error:', err);
      return 'error';
    }
  };

  const verifySinglePath = async (key, pathToVerify = null) => {
    const field = pathFields.find(f => f.key === key);
    let path = pathToVerify || settings[key];
    
    if (path) {
      setPathStatus(prev => ({ ...prev, [key]: 'checking' }));
      const status = await verifyPath(path, field?.isFolder, field?.isRelative, projectRoot);
      setPathStatus(prev => ({ ...prev, [key]: status }));
    }
  };

  const getPathStatusIcon = (key) => {
    const status = pathStatus[key];
    if (checkingPaths || status === 'checking') {
      return <Loader className="w-4 h-4 text-slate-400 animate-spin" />;
    }
    switch (status) {
      case 'valid':
        return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'invalid':
        return <XCircle className="w-4 h-4 text-red-500" />;
      case 'empty':
        return <XCircle className="w-4 h-4 text-slate-500" />;
      default:
        return <XCircle className="w-4 h-4 text-yellow-500" />;
    }
  };

  const detectVR = async () => {
    setVrDetecting(true);
    try {
      // Known VR runtime paths to check
      const knownVRPaths = [
        { name: 'Meta Quest', path: 'C:\\Program Files\\Oculus\\Support\\oculus-client\\OculusClient.exe' },
        { name: 'SteamVR', path: 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\SteamVR\\bin\\win64\\vrstartup.exe' },
        { name: 'Pimax', path: 'C:\\Program Files\\Pimax\\PimaxClient\\pimaxui\\PimaxClient.exe' },
        { name: 'HTC Vive', path: 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\SteamVR\\bin\\win64\\vrstartup.exe' },
        { name: 'Varjo', path: 'C:\\Program Files\\Varjo\\Varjo Base\\VarjoBase.exe' }
      ];

      // Check each path using file verification
      let foundPath = '';
      for (const vr of knownVRPaths) {
        const status = await verifyPath(vr.path, false, false, projectRoot);
        if (status === 'valid') {
          foundPath = vr.path;
          break;
        }
      }

      if (foundPath) {
        setVrRuntimePath(foundPath);
        setVrEnabled(true);
        // Save to config
        await saveVRConfig(true, foundPath);
        alert(`VR runtime detected: ${foundPath}`);
      } else {
        setVrEnabled(false);
        setVrRuntimePath('');
        alert('No VR runtime detected. You can manually enter the path below.');
      }
    } catch (error) {
      console.error('VR detection error:', error);
      alert('Error detecting VR: ' + error.message);
    }
    setVrDetecting(false);
  };

  const handleVRPathChange = async (path) => {
    setVrRuntimePath(path);
    // Validate the path
    if (path) {
      const status = await verifyPath(path, false, false, projectRoot);
      if (status === 'valid') {
        setVrEnabled(true);
      } else {
        setVrEnabled(false);
      }
    } else {
      setVrEnabled(false);
    }
  };

  const saveVRConfig = async (enabled, runtimePath) => {
    try {
      const result = await window.dcsMax.readJsonConfig(GLOBAL_CONFIG_PATH);
      if (!result.success) {
        throw new Error('Failed to read global config');
      }

      const config = result.data;
      if (!config.vr) config.vr = {};
      
      config.vr.enabled = enabled;
      config.vr.runtimePath = runtimePath || '';

      const writeResult = await window.dcsMax.writeJsonConfig(GLOBAL_CONFIG_PATH, config);
      if (!writeResult.success) {
        throw new Error('Failed to save VR config');
      }
    } catch (err) {
      console.error('Error saving VR config:', err);
      throw err;
    }
  };

  const browseForPath = async (settingKey) => {
    try {
      if (!window.dcsMax) {
        alert('Bridge not available. Please enter the path manually.');
        return;
      }

      const field = pathFields.find(f => f.key === settingKey);
      const isFolder = field?.isFolder || settingKey === 'savedGamesPath';
      const isMission = settingKey === 'benchmarkMissionPath';
      
      let result;
      if (isFolder) {
        result = await window.dcsMax.browseForFolder('Select Folder');
      } else {
        let filter = 'Executable Files (*.exe)|*.exe|All Files (*.*)|*.*';
        if (isMission) {
          filter = 'Mission Files (*.miz)|*.miz|All Files (*.*)|*.*';
        }
        result = await window.dcsMax.browseForFile('Select File', filter);
      }
      
      if (result && result.success && result.path) {
        let pathToStore = result.path;
        
        // For benchmark missions, store only the filename (relative to benchmark-missions folder)
        if (isMission) {
          pathToStore = result.path.split(/[\\\/]/).pop();
        }
        
        const newSettings = { ...settings, [settingKey]: pathToStore };
        setSettings(newSettings);
        setPathSources(prev => ({ ...prev, [settingKey]: 'user selected' }));
        
        // Verify immediately with the new path, don't wait for state update
        setTimeout(() => verifySinglePath(settingKey, pathToStore), 100);
      }
    } catch (error) {
      console.error('Browse error:', error);
      alert('Error opening file browser: ' + error.message);
    }
  };

  const handleSavePaths = async () => {
    try {
      // Read current global config for paths
      const globalResult = await window.dcsMax.readJsonConfig(GLOBAL_CONFIG_PATH);
      if (!globalResult.success) {
        alert('Error reading global configuration: ' + (globalResult.error || 'Unknown error'));
        return;
      }

      const globalConfig = globalResult.data;
      if (!globalConfig.paths) globalConfig.paths = {};

      // Save paths to global config
      if (settings.dcsPath) {
        globalConfig.paths.dcsExe = settings.dcsPath;
      }
      if (settings.savedGamesPath) {
        globalConfig.paths.savedGamesPath = settings.savedGamesPath;
      }
      if (settings.capframexPath) {
        // Note: Don't save capframexPath to capframexFolder - capframexFolder is reserved for captures directory
        // UI uses detected paths for CapFrameX launching, AutoHotkey uses capframexFolder for JSON files
        // globalConfig.paths.capframexFolder = settings.capframexPath;
      }
      if (settings.autoHotkeyPath) {
        globalConfig.paths.autohotkey = settings.autoHotkeyPath;
      }
      if (settings.notepadppPath) {
        globalConfig.paths.notepadpp = settings.notepadppPath;
      }
      // Write updated global config
      const globalWriteResult = await window.dcsMax.writeJsonConfig(GLOBAL_CONFIG_PATH, globalConfig);
      if (!globalWriteResult.success) {
        alert('Error saving paths to global config: ' + (globalWriteResult.error || 'Unknown error'));
        return;
      }

      // Read current test config for test-related settings
      const testResult = await window.dcsMax.readJsonConfig(JSON_CONFIG_PATH);
      if (!testResult.success) {
        alert('Error reading test configuration: ' + (testResult.error || 'Unknown error'));
        return;
      }

      const testConfig = testResult.data;
      if (!testConfig.testConfiguration) testConfig.testConfiguration = {};

      // Save test-related settings to test config
      if (settings.benchmarkMissionPath) {
        // Store only the filename - mission is relative to benchmark-missions folder
        const filename = settings.benchmarkMissionPath.split(/[\\\/]/).pop();
        testConfig.testConfiguration.mission = filename;
      }

      // Write updated test config
      const testWriteResult = await window.dcsMax.writeJsonConfig(JSON_CONFIG_PATH, testConfig);
      
      // Save VR configuration to global config
      await saveVRConfig(vrEnabled, vrRuntimePath);
      
      if (testWriteResult.success) {
        alert('Configuration saved successfully!');
      } else {
        alert('Error saving test config: ' + (testWriteResult.error || 'Unknown error'));
      }
    } catch (err) {
      console.error('Save error:', err);
      alert('Error saving configuration: ' + err.message);
    }
  };

  const installSoftware = async (software) => {
    if (!confirm(`Install ${software.name} using winget?`)) {
      return;
    }
    
    setInstalling(software.id);
    setOutput(`Installing ${software.name}...\nThis may take a minute, please wait...\n`);

    try {
      // Use appropriate scope based on software type
      // Portable apps (like CapFrameX) don't support --scope=machine
      const scope = software.portable ? 'user' : 'machine';
      const command = `winget install --id=${software.wingetId} --exact --scope=${scope} --accept-package-agreements --accept-source-agreements --disable-interactivity`;
      const result = await window.dcsMax.executeCommand(command);
      
      // Clean ANSI escape codes and progress bar garbage from output
      const cleanOutput = (text) => {
        if (!text) return '';
        // Split into lines and filter out noisy lines
        const lines = text.split(/\r?\n/);
        const cleanedLines = lines.filter(line => {
          // Skip empty lines or lines with only whitespace
          if (!line.trim()) return false;
          // Skip spinner lines (just - \ | /)
          if (/^[\s]*[-\\|\/][\s]*$/.test(line)) return false;
          // Skip lines that are mostly progress bar characters (█ ▒ or garbled versions)
          if (/[█▒â–ˆâ–']{3,}/.test(line)) return false;
          // Skip lines with garbled UTF-8 progress bars
          if (/â–/.test(line)) return false;
          // Skip lines that look like progress (MB / MB patterns with mostly whitespace/symbols)
          if (/^\s*[\d.]+\s*(KB|MB|GB)\s*\/\s*[\d.]+\s*(KB|MB|GB)\s*$/.test(line.trim())) return false;
          return true;
        });
        return cleanedLines
          .join('\n')
          .replace(/\x1b\[[0-9;]*[a-zA-Z]/g, '')  // ANSI escape codes
          .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, '') // Control characters
          .replace(/\n{3,}/g, '\n\n')              // Collapse multiple blank lines
          .trim();
      };
      
      // Check for success - winget returns 0 for success, or already installed messages
      const stdout = result.stdout || '';
      const cleanedOutput = cleanOutput(stdout);
      const isAlreadyInstalled = stdout.includes('already installed') || stdout.includes('No available upgrade');
      const isSuccess = result.success || result.exitCode === 0 || isAlreadyInstalled;
      
      if (isSuccess) {
        if (isAlreadyInstalled) {
          setOutput(prev => prev + cleanedOutput + `\n\n✓ ${software.name} is already installed!\n`);
        } else {
          setOutput(prev => prev + cleanedOutput + `\n\n✓ ${software.name} installed successfully!\n`);
        }
        
        // Create Start Menu shortcut for portable apps
        if (software.portable) {
          setOutput(prev => prev + `\n📁 Creating Start Menu shortcut...\n`);
          try {
            await window.dcsMax.createStartMenuShortcut(software.id);
            setOutput(prev => prev + `✓ Start Menu shortcut created\n`);
          } catch (e) {
            setOutput(prev => prev + `⚠️ Could not create shortcut: ${e.message}\n`);
          }
        }
        
        // Auto-configure CapFrameX hotkey after installation
        if (software.id === 'capframex') {
          setOutput(prev => prev + `\n⚙️ Configuring CapFrameX for DCS-Max compatibility...\n`);
          await configureCapFrameXHotkey();
        }
        
        setOutput(prev => prev + `\nRefreshing paths and saving to configuration...\n`);
        await refreshAfterInstall();
      } else {
        setOutput(prev => prev + cleanedOutput + cleanOutput(result.stderr) + `\n\n✗ Installation failed. Exit code: ${result.exitCode}\n`);
        await refreshAfterInstall();
      }
      
      setInstalling(null);
    } catch (err) {
      console.error('Installation error:', err);
      setInstalling(null);
      setOutput(prev => prev + `\nError: ${err.message}\n`);
    }
  };
  
  // Refresh paths and save to JSON after installation
  const refreshAfterInstall = async () => {
    try {
      // Force re-detection by clearing current settings for installed software
      const freshSettings = { ...settings };
      const freshSources = { ...pathSources };
      
      // Clear software paths to force re-detection
      freshSettings.capframexPath = '';
      freshSettings.autoHotkeyPath = '';
      freshSettings.notepadppPath = '';
      freshSources.capframexPath = '';
      freshSources.autoHotkeyPath = '';
      freshSources.notepadppPath = '';
      
      // Keep DCS paths intact (user-configured)
      // Re-detect installed software and get the updated settings
      const updatedSettings = await checkInstalledSoftware(freshSettings, freshSources, projectRoot);
      
      // Auto-save detected paths to JSON using the updated settings
      await autoSavePathsToJson(updatedSettings);
    } catch (err) {
      console.error('Error refreshing after install:', err);
    }
  };
  
  // Auto-save paths to JSON and configure VR settings
  const autoSavePathsToJson = async (pathSettings = null) => {
    try {
      const jsonResult = await window.dcsMax.readJsonConfig(JSON_CONFIG_PATH);
      if (!jsonResult.success) {
        console.error('Could not read JSON for auto-save:', jsonResult.error);
        return;
      }
      
      const config = jsonResult.data;
      if (!config.configuration) config.configuration = {};
      if (!config.configuration.paths) config.configuration.paths = {};
      
      // Use provided settings or fall back to current state
      const currentSettings = pathSettings || settings;
      
      // Map settings keys to JSON keys
      if (currentSettings.dcsPath) {
        config.configuration.paths.dcsExe = currentSettings.dcsPath;
      }
      if (currentSettings.savedGamesPath) {
        config.configuration.paths.savedGamesPath = currentSettings.savedGamesPath;
      }
      if (currentSettings.capframexPath) {
        config.configuration.paths.capframex = currentSettings.capframexPath;
      }
      if (currentSettings.autoHotkeyPath) {
        config.configuration.paths.autohotkey = currentSettings.autoHotkeyPath;
      }
      if (currentSettings.notepadppPath) {
        config.configuration.paths.notepadpp = currentSettings.notepadppPath;
      }
      if (currentSettings.benchmarkMissionPath) {
        const filename = currentSettings.benchmarkMissionPath.split(/[\\\/]/).pop();
        config.configuration.mission = filename;
      }
      
      // VR config is now saved separately via saveVRConfig
      
      await window.dcsMax.writeJsonConfig(JSON_CONFIG_PATH, config);
      setOutput(prev => prev + `✓ Configuration saved.\n`);
    } catch (err) {
      console.error('Auto-save error:', err);
    }
  };

  // CapFrameX Hotkey Configuration Functions
  const checkCapFrameXHotkey = async (capframexStatus = null) => {
    // Use passed status or fall back to state
    const isInstalled = capframexStatus === 'installed' || installStatus['capframex'] === 'installed';
    
    if (!isInstalled) {
      setCapframexHotkeyConfigured(false);
      return;
    }
    
    setCheckingCapframexHotkey(true);
    try {
      const result = await window.dcsMax.getCapFrameXHotkey();
      if (result.success) {
        // Check if hotkey is set to Scroll (configured) or F12 (default)
        setCapframexHotkeyConfigured(result.hotkey === 'Scroll');
      }
    } catch (err) {
      console.error('Failed to check CapFrameX hotkey:', err);
    }
    setCheckingCapframexHotkey(false);
  };
  
  const configureCapFrameXHotkey = async () => {
    try {
      const result = await window.dcsMax.setCapFrameXHotkey('Scroll');
      if (result.success) {
        setCapframexHotkeyConfigured(true);
        skipHotkeyCheckRef.current = true; // Skip the next hotkey check to avoid state override
        setOutput(prev => prev + `   → Capture hotkey set to Scroll Lock\n`);
        setOutput(prev => prev + `   → Prevents conflicts with DCS F12 view key\n`);
        setOutput(prev => prev + `✓ CapFrameX configured successfully!\n`);
      } else {
        setOutput(prev => prev + `⚠️ Failed to configure CapFrameX hotkey\n`);
      }
    } catch (err) {
      console.error('Failed to configure CapFrameX hotkey:', err);
      setOutput(prev => prev + `⚠️ Error configuring CapFrameX: ${err.message}\n`);
    }
  };
  
  const restoreCapFrameXDefaultHotkey = async () => {
    try {
      const result = await window.dcsMax.setCapFrameXHotkey('F12');
      if (result.success) {
        setCapframexHotkeyConfigured(false);
        setOutput(prev => prev + `⚠️ CapFrameX hotkey restored to F12 (default)\n`);
        
        // Show warning alert
        alert(
          '⚠️ Performance Testing Disabled\n\n' +
          'The default F12 hotkey conflicts with DCS\'s F12 view key.\n\n' +
          'Automated performance testing will NOT work until you reconfigure to use Scroll Lock.'
        );
      }
    } catch (err) {
      console.error('Failed to restore CapFrameX hotkey:', err);
      alert('Error: Failed to restore CapFrameX hotkey');
    }
  };

  const installAll = async () => {
    console.log('installAll called');
    if (!window?.dcsMax?.executeCommand) {
      console.log('Bridge not available');
      alert('DCS-Max host is not available. Please run from the launcher so winget commands can execute.');
      return;
    }
    console.log('Bridge available, checking confirm');
    if (!confirm('Install all required software using winget?\n\nThis will install:\n• CapFrameX\n• AutoHotkey\n• Notepad++')) {
      console.log('User cancelled');
      return;
    }
    
    console.log('Starting installation');
    setInstalling('all');
    setOutput('Installing all required software...\nThis may take a few minutes, please wait...\n\n');

    try {
      // Install each software sequentially using executeCommand
      for (const software of requiredSoftware) {
        console.log(`Installing ${software.name}`);
        if (installStatus[software.id] === 'installed') {
          setOutput(prev => prev + `✓ ${software.name} already installed, skipping...\n`);
          continue;
        }
        
        setOutput(prev => prev + `📦 Installing ${software.name}...\n`);
        
        const command = `winget install --id=${software.wingetId} --exact --scope=user --accept-package-agreements --accept-source-agreements`;
        console.log(`Executing command: ${command}`);
        const result = await window.dcsMax.executeCommand(command);
        console.log(`Command result:`, result);
        
        if (result.success || result.exitCode === 0) {
          setOutput(prev => prev + `✓ ${software.name} installed successfully!\n\n`);
          
          // Auto-configure CapFrameX hotkey after installation
          if (software.id === 'capframex') {
            setOutput(prev => prev + `⚙️ Configuring CapFrameX hotkey...\n`);
            await configureCapFrameXHotkey();
          }
        } else {
          setOutput(prev => prev + `⚠️ ${software.name}: ${result.stderr || 'Installation may have failed'}\n\n`);
        }
      }
      
      setOutput(prev => prev + '\n✓ Installation complete! Refreshing and saving...\n');
      await refreshAfterInstall();
      setInstalling(null);
    } catch (err) {
      console.error('Installation error:', err);
      setOutput(prev => prev + `\nError: ${err.message}\n`);
      setInstalling(null);
    }
  };

  const getStatusIcon = (softwareId) => {
    if (checkingStatus) {
      return <Loader className="w-5 h-5 text-slate-400 animate-spin" />;
    }
    
    const status = installStatus[softwareId];
    switch (status) {
      case 'installed':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'not-installed':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return <AlertCircle className="w-5 h-5 text-yellow-500" />;
    }
  };

  const getStatusText = (softwareId) => {
    if (checkingStatus) return 'Checking...';
    
    const status = installStatus[softwareId];
    switch (status) {
      case 'installed':
        return 'Installed';
      case 'not-installed':
        return 'Not installed';
      default:
        return 'Unknown';
    }
  };

  const allInstalled = requiredSoftware.every(s => installStatus[s.id] === 'installed');

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-6 max-w-4xl mx-auto">
        {/* Header with Save Button */}
        <div className="flex items-start justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-white mb-2">Software & Configuration</h2>
            <p className="text-slate-400">
              Configure paths and install required software for DCS-Max optimization and testing.
            </p>
          </div>
          <button
            onClick={handleSavePaths}
            className="flex items-center space-x-2 px-4 py-2 bg-green-600 hover:bg-green-500 rounded transition-colors font-semibold flex-shrink-0 ml-4"
            title="Save all application and VR paths to configuration"
          >
            <Save className="w-4 h-4" />
            <span>Save All Configuration</span>
          </button>
        </div>

        {/* Output Console - At very top for visibility */}
        {(output || installing) && (
          <div ref={outputRef} className="mb-6">
            <h3 className="text-lg font-semibold text-white mb-3 flex items-center">
              {installing ? (
                <Loader className="w-5 h-5 mr-2 animate-spin text-blue-400" />
              ) : (
                <CheckCircle className="w-5 h-5 mr-2 text-green-400" />
              )}
              Installation {installing ? 'in Progress' : 'Complete'}
            </h3>
            <div className="bg-slate-900 rounded-lg p-4 border border-slate-700 max-h-64 overflow-y-auto">
              <pre className="text-sm text-slate-300 font-mono whitespace-pre-wrap">{output}</pre>
            </div>
          </div>
        )}

        {/* CONSOLIDATED SOFTWARE & PATHS SECTION */}
        <div className="mb-6">
          <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-white flex items-center">
                <Package className="w-5 h-5 mr-2 text-blue-400" />
                Software & Configuration Paths
              </h3>
              <div className="flex items-center space-x-2">
                <button
                  onClick={installAll}
                  disabled={installing !== null || allInstalled || checkingStatus}
                  className={`flex items-center space-x-2 px-3 py-1.5 rounded transition-colors text-sm font-semibold ${
                    allInstalled 
                      ? 'bg-green-600/30 text-green-400 cursor-not-allowed' 
                      : 'bg-green-600 hover:bg-green-700 disabled:bg-slate-700 text-white'
                  }`}
                  title={allInstalled ? 'All software already installed' : 'Install all missing software'}
                >
                  {installing === 'all' ? (
                    <Loader className="w-4 h-4 animate-spin" />
                  ) : allInstalled ? (
                    <CheckCircle className="w-4 h-4" />
                  ) : (
                    <Download className="w-4 h-4" />
                  )}
                  <span>{allInstalled ? 'All Installed' : 'Install All'}</span>
                </button>
                <button
                  onClick={() => verifyAllPaths(projectRoot)}
                  disabled={checkingPaths}
                  className="flex items-center space-x-2 px-3 py-1.5 bg-slate-700 hover:bg-slate-600 disabled:bg-slate-800 rounded transition-colors text-sm"
                >
                  <RefreshCw className={`w-4 h-4 ${checkingPaths ? 'animate-spin' : ''}`} />
                  <span>Verify</span>
                </button>
              </div>
            </div>

            {/* DCS Paths Group */}
            <div className="mb-6">
              <div className="space-y-3">
                {dcsPathFields.map((field) => (
                  <div key={field.key}>
                    <label className="block text-xs font-medium text-slate-400 mb-1 flex items-center space-x-2">
                      <span>{field.label}</span>
                      {field.required && <span className="text-red-400">*</span>}
                      {getPathStatusIcon(field.key)}
                      {pathStatus[field.key] === 'valid' && (
                        <span className="text-xs text-green-400">Configured</span>
                      )}
                      {pathStatus[field.key] === 'invalid' && (
                        <span className="text-xs text-red-400">Not found</span>
                      )}
                      {pathSources[field.key] && (
                        <span className="text-xs text-slate-500">({pathSources[field.key]})</span>
                      )}
                    </label>
                    <div className="flex items-center space-x-2">
                      <input
                        type="text"
                        value={settings[field.key]}
                        onChange={(e) => {
                          setSettings({ ...settings, [field.key]: e.target.value });
                          setPathSources(prev => ({ ...prev, [field.key]: 'manual' }));
                          setPathStatus(prev => ({ ...prev, [field.key]: 'unknown' }));
                        }}
                        onBlur={(e) => verifySinglePath(field.key, e.target.value)}
                        className={`flex-1 px-3 py-1.5 bg-slate-700 text-slate-200 rounded border text-sm focus:outline-none ${
                          pathStatus[field.key] === 'valid' 
                            ? 'border-green-500/50 focus:border-green-500' 
                            : pathStatus[field.key] === 'invalid'
                              ? 'border-red-500/50 focus:border-red-500'
                              : 'border-slate-600 focus:border-blue-500'
                        }`}
                        placeholder={`Path to ${field.label.toLowerCase()}`}
                      />
                      <button
                        onClick={() => browseForPath(field.key)}
                        className="px-3 py-1.5 bg-slate-600 hover:bg-slate-500 rounded transition-colors"
                        title="Browse..."
                      >
                        <FolderOpen className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Required Software Group */}
            <div>
              <div className="space-y-3">
                {softwarePathFields.map((field) => {
                  const status = installStatus[field.statusKey];
                  const isInstalled = status === 'installed';
                  
                  return (
                    <div key={field.key}>
                      <label className="block text-xs font-medium text-slate-400 mb-1 flex items-center space-x-2">
                        <span>{field.label}</span>
                        {getPathStatusIcon(field.key)}
                        {isInstalled && pathStatus[field.key] === 'valid' && (
                          <span className="text-xs text-green-400">Installed</span>
                        )}
                        {!isInstalled && (
                          <span className="text-xs text-red-400">Not installed</span>
                        )}
                        {pathSources[field.key] && isInstalled && (
                          <span className="text-xs text-slate-500">({pathSources[field.key]})</span>
                        )}
                      </label>
                      <div className="flex items-center space-x-2">
                        <input
                          type="text"
                          value={settings[field.key]}
                          onChange={(e) => {
                            setSettings({ ...settings, [field.key]: e.target.value });
                            setPathSources(prev => ({ ...prev, [field.key]: 'manual' }));
                            setPathStatus(prev => ({ ...prev, [field.key]: 'unknown' }));
                          }}
                          onBlur={(e) => verifySinglePath(field.key, e.target.value)}
                          disabled={!isInstalled}
                          className={`flex-1 px-3 py-1.5 bg-slate-700 text-slate-200 rounded border text-sm focus:outline-none disabled:bg-slate-800 disabled:text-slate-500 ${
                            !isInstalled
                              ? 'border-slate-700'
                              : pathStatus[field.key] === 'valid' 
                                ? 'border-green-500/50 focus:border-green-500' 
                                : pathStatus[field.key] === 'invalid'
                                  ? 'border-red-500/50 focus:border-red-500'
                                  : 'border-slate-600 focus:border-blue-500'
                          }`}
                          placeholder={isInstalled ? `Path to ${field.label.toLowerCase()}` : 'Not installed'}
                        />
                        <button
                          onClick={() => browseForPath(field.key)}
                          disabled={!isInstalled}
                          className="px-3 py-1.5 bg-slate-600 hover:bg-slate-500 disabled:bg-slate-800 disabled:text-slate-500 rounded transition-colors"
                          title="Browse..."
                        >
                          <FolderOpen className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => installSoftware(requiredSoftware.find(s => s.id === field.statusKey))}
                          disabled={installing !== null || isInstalled}
                          className={`px-3 py-1.5 rounded transition-colors text-sm font-medium ${
                            isInstalled
                              ? 'bg-green-600/30 text-green-400 cursor-not-allowed'
                              : 'bg-green-600 hover:bg-green-700 disabled:bg-slate-700 text-white'
                          }`}
                          title={isInstalled ? 'Already installed' : 'Install this software'}
                        >
                          {installing === field.statusKey ? (
                            <Loader className="w-4 h-4 animate-spin" />
                          ) : isInstalled ? (
                            <CheckCircle className="w-4 h-4" />
                          ) : (
                            <Download className="w-4 h-4" />
                          )}
                        </button>
                      </div>
                      
                      {/* CapFrameX Hotkey Configuration */}
                      {field.statusKey === 'capframex' && isInstalled && (
                        <div className={`border-l-4 pl-3 mt-2 ${capframexHotkeyConfigured ? 'border-green-500' : 'border-yellow-500'}`}>
                          <div className="flex items-center space-x-2 text-xs">
                            {checkingCapframexHotkey ? (
                              <Loader className="w-3.5 h-3.5 text-slate-400 animate-spin" />
                            ) : capframexHotkeyConfigured ? (
                              <CheckCircle className="w-3.5 h-3.5 text-green-400" />
                            ) : (
                              <AlertCircle className="w-3.5 h-3.5 text-yellow-400" />
                            )}
                            <span className={capframexHotkeyConfigured ? 'text-green-400' : 'text-yellow-400'}>
                              Capture Hotkey: {capframexHotkeyConfigured ? 'Scroll Lock' : 'F12 (Default)'}
                            </span>
                          </div>
                          <div className="flex items-center space-x-2 text-xs text-slate-400 mt-1">
                            {capframexHotkeyConfigured ? (
                              <span>✓ Configured for DCS-Max compatibility</span>
                            ) : (
                              <span>⚠️ Conflicts with DCS F12 view key - testing disabled</span>
                            )}
                          </div>
                          <button
                            onClick={capframexHotkeyConfigured ? restoreCapFrameXDefaultHotkey : configureCapFrameXHotkey}
                            className={`mt-2 px-3 py-1 rounded text-xs transition-colors ${
                              capframexHotkeyConfigured
                                ? 'bg-slate-600 hover:bg-slate-500'
                                : 'bg-blue-600 hover:bg-blue-500'
                            }`}
                          >
                            {capframexHotkeyConfigured ? 'Restore Default (F12)' : 'Configure for DCS-Max'}
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* VR Headset Configuration */}
        <div className="mb-6">
          <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-white flex items-center">
                <Download className="w-5 h-5 mr-2 text-cyan-400" />
                VR Headset Configuration (Optional)
              </h3>
              <button
                onClick={detectVR}
                disabled={vrDetecting}
                className="flex items-center space-x-2 px-3 py-1.5 bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-700 rounded transition-colors text-sm"
                title="Auto-detect VR runtime"
              >
                <Scan className={`w-4 h-4 ${vrDetecting ? 'animate-pulse' : ''}`} />
                <span>{vrDetecting ? 'Detecting...' : 'Detect VR'}</span>
              </button>
            </div>
            
            <div className="mb-4">
              <label className="block text-xs font-medium text-slate-400 mb-2">
                VR Headset Runtime Path
              </label>
              <div className="flex items-center space-x-2">
                <input
                  type="text"
                  value={vrRuntimePath}
                  onChange={(e) => handleVRPathChange(e.target.value)}
                  className="flex-1 px-3 py-2 bg-slate-700 text-slate-200 rounded border border-slate-600 focus:border-cyan-500 focus:outline-none text-sm"
                  placeholder="Path to VR runtime executable (e.g., OculusClient.exe, vrstartup.exe)"
                />
                <button
                  onClick={async () => {
                    try {
                      const filter = 'Executable Files (*.exe)|*.exe|All Files (*.*)|*.*';
                      const result = await window.dcsMax.browseForFile('Select VR Runtime Executable', filter);
                      if (result.success && result.path) {
                        handleVRPathChange(result.path);
                      }
                    } catch (err) {
                      console.error('Browse error:', err);
                    }
                  }}
                  className="px-3 py-2 bg-slate-600 hover:bg-slate-500 rounded transition-colors"
                  title="Browse..."
                >
                  <FolderOpen className="w-4 h-4" />
                </button>
              </div>
              {vrEnabled && vrRuntimePath && (
                <p className="text-xs text-green-400 mt-2">
                  ✓ VR enabled: {vrRuntimePath}
                </p>
              )}
              {!vrEnabled && !vrRuntimePath && (
                <p className="text-xs text-slate-400 mt-2">
                  No VR runtime configured. DCS will run in 2D mode.
                </p>
              )}
            </div>

            <div className="bg-slate-900/50 rounded p-3">
              <p className="text-xs font-medium text-slate-300 mb-2">
                Common VR headset runtime locations:
              </p>
              <div className="space-y-1 text-xs text-slate-400 font-mono">
                <div><span className="text-slate-500">Meta Quest:</span> C:\Program Files\Oculus\Support\oculus-client\OculusClient.exe</div>
                <div><span className="text-slate-500">SteamVR:</span> C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe</div>
                <div><span className="text-slate-500">Pimax:</span> C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe</div>
                <div><span className="text-slate-500">HTC Vive:</span> C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe</div>
                <div><span className="text-slate-500">Varjo:</span> C:\Program Files\Varjo\Varjo Base\VarjoBase.exe</div>
                <div><span className="text-slate-500">WMR/HP Reverb G2:</span> C:\Program Files\WindowsApps\Microsoft.MixedReality.Portal_*\MixedRealityPortal.exe</div>
              </div>
              <p className="text-xs text-slate-500 mt-2 italic">
                Tip: Copy and paste the path above, or use the Browse button to select your VR runtime executable.
              </p>
            </div>
          </div>
        </div>

        {/* Info Box */}
        <div className="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
          <h4 className="font-semibold text-blue-400 mb-2 flex items-center">
            <AlertCircle className="w-4 h-4 mr-2" />
            About Windows Package Manager (winget)
          </h4>
          <p className="text-sm text-slate-300">
            Winget is Microsoft's official package manager for Windows. It allows you to install, 
            update, and manage software from the command line. All installations are performed 
            with user scope for maximum compatibility.
          </p>
        </div>
      </div>
    </div>
  );
}

export default InstallSoftware;
