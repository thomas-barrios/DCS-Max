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
  Scan,
  Save
} from 'lucide-react';

// Path configuration fields
const pathFields = [
  { key: 'dcsPath', label: 'DCS World Executable', required: true },
  { key: 'savedGamesPath', label: 'DCS Saved Games Folder', required: true, isFolder: true },
  { key: 'capframexPath', label: 'CapFrameX Executable', required: false },
  { key: 'autoHotkeyPath', label: 'AutoHotkey v2 Executable', required: false },
  { key: 'notepadppPath', label: 'Notepad++', required: false },
  { key: 'benchmarkMissionPath', label: 'Benchmark Mission File', required: false, isRelative: true }
];

const requiredSoftware = [
  {
    id: 'capframex',
    name: 'CapFrameX',
    description: 'Performance benchmarking and analysis tool',
    wingetId: 'CXWorld.CapFrameX',
    website: 'https://www.capframex.com/',
    required: true
  },
  {
    id: 'autohotkey',
    name: 'AutoHotkey v2',
    description: 'Automation scripting for benchmark workflows',
    wingetId: 'AutoHotkey.AutoHotkey',
    website: 'https://www.autohotkey.com/',
    required: true
  },
  {
    id: 'notepadpp',
    name: 'Notepad++',
    description: 'Log viewer and configuration editor',
    wingetId: 'Notepad++.Notepad++',
    website: 'https://notepad-plus-plus.org/',
    required: true
  }
];

function InstallSoftware() {
  const [installing, setInstalling] = useState(null);
  const [installStatus, setInstallStatus] = useState({});
  const [checkingStatus, setCheckingStatus] = useState(true);
  const [output, setOutput] = useState('');
  
  // VR Detection state
  const [detectedVRHeadsets, setDetectedVRHeadsets] = useState([]);
  const [selectedVRHeadset, setSelectedVRHeadset] = useState('none');
  const [vrPaths, setVrPaths] = useState({});
  const [vrDetecting, setVrDetecting] = useState(false);
  
  // Path configuration state
  const [settings, setSettings] = useState({
    dcsPath: '',
    savedGamesPath: '',
    capframexPath: '',
    autoHotkeyPath: '',
    pimaxPath: '',
    notepadppPath: '',
    benchmarkMissionPath: ''
  });
  const [pathStatus, setPathStatus] = useState({});
  const [pathSources, setPathSources] = useState({});
  const [projectRoot, setProjectRoot] = useState('');
  const [checkingPaths, setCheckingPaths] = useState(false);

  useEffect(() => {
    initializeAll();
  }, []);

  const JSON_CONFIG_PATH = '4-Performance-Testing/testing-configuration.json';

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

    // Load paths from JSON config
    try {
      const jsonResult = await window.dcsMax.readJsonConfig(JSON_CONFIG_PATH);
      if (jsonResult.success && jsonResult.data?.configuration?.paths) {
        const paths = jsonResult.data.configuration.paths;
        
        // Helper to check if a path value is a placeholder (not a real path)
        const isPlaceholder = (value) => !value || value === 'auto' || value === '' || value.toLowerCase() === 'auto';
        
        // Map JSON keys to settings keys (ignore placeholder values)
        if (paths.dcsExe && !isPlaceholder(paths.dcsExe)) {
          newSettings.dcsPath = paths.dcsExe;
          sources.dcsPath = 'config';
        }
        if (paths.savedGamesPath && !isPlaceholder(paths.savedGamesPath)) {
          newSettings.savedGamesPath = paths.savedGamesPath;
          sources.savedGamesPath = 'config';
        }
        if (paths.capframex && !isPlaceholder(paths.capframex)) {
          newSettings.capframexPath = paths.capframex;
          sources.capframexPath = 'config';
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
        
        // Benchmark mission (stored as filename only, relative to benchmark-missions folder)
        if (jsonResult.data.configuration?.mission && !isPlaceholder(jsonResult.data.configuration.mission)) {
          newSettings.benchmarkMissionPath = jsonResult.data.configuration.mission;
          sources.benchmarkMissionPath = 'config';
        }
      }
    } catch (err) {
      console.error('Failed to read settings from JSON:', err);
    }

    // Detect paths and check software status
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
        
        // Check required software
        const capframex = pathsResult.paths.capframexPath;
        status['capframex'] = capframex?.found ? 'installed' : 'not-installed';
        if (!newSettings.capframexPath && capframex?.path) {
          newSettings.capframexPath = capframex.path;
          sources.capframexPath = capframex.found ? `detected (${capframex.source})` : 'default';
        }
        
        const autohotkey = pathsResult.paths.autoHotkeyPath;
        status['autohotkey'] = autohotkey?.found ? 'installed' : 'not-installed';
        if (!newSettings.autoHotkeyPath && autohotkey?.path) {
          newSettings.autoHotkeyPath = autohotkey.path;
          sources.autoHotkeyPath = autohotkey.found ? `detected (${autohotkey.source})` : 'default';
        }
        
        const notepadpp = pathsResult.paths.notepadppPath;
        status['notepadpp'] = notepadpp?.found ? 'installed' : 'not-installed';
        if (!newSettings.notepadppPath && notepadpp?.path) {
          newSettings.notepadppPath = notepadpp.path;
          sources.notepadppPath = notepadpp.found ? `detected (${notepadpp.source})` : 'default';
        }

        // Pimax (optional)
        const pimax = pathsResult.paths.pimaxPath;
        if (!newSettings.pimaxPath && pimax?.path) {
          newSettings.pimaxPath = pimax.path;
          sources.pimaxPath = pimax.found ? `detected (${pimax.source})` : 'default';
        }

        // Auto-detect VR headsets on initialization
        if (pathsResult.paths.vrHeadsets && pathsResult.paths.vrPaths) {
          const headsets = pathsResult.paths.vrHeadsets;
          const paths = pathsResult.paths.vrPaths;
          setDetectedVRHeadsets(headsets);
          setVrPaths(paths);
          
          // Auto-select first detected headset and populate path
          if (headsets.length > 0) {
            setSelectedVRHeadset(headsets[0]);
            if (paths[headsets[0]]) {
              newSettings.pimaxPath = paths[headsets[0]];
              sources.pimaxPath = 'auto-detected';
            }
          }
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
    const path = pathToVerify || settings[key];
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

  const detectAllPaths = async () => {
    setCheckingStatus(true);
    await checkInstalledSoftware({}, {}, projectRoot);
  };

  const detectVRHeadset = async () => {
    setVrDetecting(true);
    try {
      const result = await window.dcsMax.detectPaths();
      console.log('VR Detection Result:', result);
      if (result.success && result.paths) {
        const headsets = result.paths.vrHeadsets || [];
        const paths = result.paths.vrPaths || {};
        
        console.log('Detected Headsets:', headsets);
        console.log('VR Paths:', paths);
        
        setDetectedVRHeadsets(headsets);
        setVrPaths(paths);
        
        // Auto-select first detected headset
        if (headsets.length > 0) {
          setSelectedVRHeadset(headsets[0]);
          // Auto-populate VR Client path if detected
          if (paths[headsets[0]]) {
            const newSettings = { ...settings, pimaxPath: paths[headsets[0]] };
            setSettings(newSettings);
            setPathSources(prev => ({ ...prev, pimaxPath: 'auto-detected' }));
            setTimeout(() => verifySinglePath('pimaxPath', paths[headsets[0]]), 100);
            
            // Auto-save with VR enabled
            setTimeout(() => autoSavePathsToJson(newSettings), 500);
          }
        } else {
          setSelectedVRHeadset('none');
        }
      }
    } catch (error) {
      console.error('VR detection error:', error);
      setDetectedVRHeadsets([]);
      setSelectedVRHeadset('none');
    }
    setVrDetecting(false);
  };

  const handleVRHeadsetChange = (headset) => {
    setSelectedVRHeadset(headset);
    
    // Auto-populate path for known headsets
    if (headset !== 'none' && vrPaths[headset]) {
      const newSettings = { ...settings, pimaxPath: vrPaths[headset] };
      setSettings(newSettings);
      setPathSources(prev => ({ ...prev, pimaxPath: 'auto-populated' }));
      setTimeout(() => verifySinglePath('pimaxPath', vrPaths[headset]), 100);
      // Auto-save with VR enabled for this headset
      setTimeout(() => autoSavePathsToJson(newSettings), 500);
    } else if (headset === 'none') {
      // Clear VR client path and disable VR if "None" is selected
      const newSettings = { ...settings, pimaxPath: '' };
      setSettings(newSettings);
      setPathStatus(prev => ({ ...prev, pimaxPath: 'empty' }));
      // Auto-save with VR disabled
      setTimeout(() => autoSavePathsToJson(newSettings), 500);
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
      // Read current JSON config
      const jsonResult = await window.dcsMax.readJsonConfig(JSON_CONFIG_PATH);
      if (!jsonResult.success) {
        alert('Error reading configuration: ' + (jsonResult.error || 'Unknown error'));
        return;
      }
      
      const config = jsonResult.data;
      if (!config.configuration) config.configuration = {};
      if (!config.configuration.paths) config.configuration.paths = {};
      
      // Map settings keys to JSON keys
      if (settings.dcsPath) {
        config.configuration.paths.dcsExe = settings.dcsPath;
      }
      if (settings.savedGamesPath) {
        config.configuration.paths.savedGamesPath = settings.savedGamesPath;
        // Note: optionsLua is derived from savedGamesPath when needed, not stored separately
      }
      if (settings.capframexPath) {
        config.configuration.paths.capframex = settings.capframexPath;
      }
      if (settings.autoHotkeyPath) {
        config.configuration.paths.autohotkey = settings.autoHotkeyPath;
      }
      if (settings.notepadppPath) {
        config.configuration.paths.notepadpp = settings.notepadppPath;
      }
      if (settings.pimaxPath) {
        config.configuration.paths.pimax = settings.pimaxPath;
        config.configuration.paths.vrClient = settings.pimaxPath;
      }
      if (settings.benchmarkMissionPath) {
        // Store only the filename - mission is relative to benchmark-missions folder
        const filename = settings.benchmarkMissionPath.split(/[\\\/]/).pop();
        config.configuration.mission = filename;
      }
      
      // Save VR configuration based on selected headset
      if (!config.configuration.vr) config.configuration.vr = {};
      
      if (selectedVRHeadset === 'none' || !selectedVRHeadset) {
        // No VR selected - disable VR
        config.configuration.vr.enabled = false;
        config.configuration.vr.hardware = 'none';
      } else {
        // VR headset selected - enable and set hardware
        config.configuration.vr.enabled = true;
        config.configuration.vr.hardware = selectedVRHeadset;
      }
      
      // Write updated config
      const writeResult = await window.dcsMax.writeJsonConfig(JSON_CONFIG_PATH, config);
      if (writeResult.success) {
        alert('Paths saved to configuration file!');
      } else {
        alert('Error saving paths: ' + (writeResult.error || 'Unknown error'));
      }
    } catch (err) {
      console.error('Save error:', err);
      alert('Error saving paths: ' + err.message);
    }
  };

  const installSoftware = async (software) => {
    if (!confirm(`Install ${software.name} using winget?`)) {
      return;
    }
    
    setInstalling(software.id);
    setOutput(`Installing ${software.name}...\n`);

    try {
      // Set up streaming output handler
      const outputHandler = (data) => {
        setOutput(prev => prev + data.output);
      };
      
      const completeHandler = async (data) => {
        setInstalling(null);
        if (data.exitCode === 0) {
          setOutput(prev => prev + `\n✓ ${software.name} installed successfully!\n`);
          setOutput(prev => prev + `\nRefreshing paths and saving to configuration...\n`);
          // Re-detect all paths and update JSON after successful installation
          await refreshAfterInstall();
        } else {
          setOutput(prev => prev + `\n✗ Installation may have failed. Check if already installed.\n`);
          // Still try to recheck - software might already be installed
          await refreshAfterInstall();
        }
      };
      
      window.dcsMax.onScriptOutput(outputHandler);
      window.dcsMax.onScriptComplete(completeHandler);

      // Create a temp PowerShell script to run winget
      window.dcsMax.executeScriptStream(`powershell -Command "winget install --id=${software.wingetId} --exact --scope=user --accept-package-agreements --accept-source-agreements"`, []);
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
      if (currentSettings.pimaxPath) {
        config.configuration.paths.pimax = currentSettings.pimaxPath;
        config.configuration.paths.vrClient = currentSettings.pimaxPath;
      }
      if (currentSettings.benchmarkMissionPath) {
        const filename = currentSettings.benchmarkMissionPath.split(/[\\\/]/).pop();
        config.configuration.mission = filename;
      }
      
      // AUTO-CONFIGURE VR BASED ON SELECTED HEADSET
      // Use the currently selected VR headset from state
      if (!config.configuration.vr) config.configuration.vr = {};
      
      if (selectedVRHeadset === 'none' || !selectedVRHeadset) {
        // No VR selected - disable VR
        config.configuration.vr.enabled = false;
        config.configuration.vr.hardware = 'none';
      } else {
        // VR headset selected - enable and set hardware
        config.configuration.vr.enabled = true;
        config.configuration.vr.hardware = selectedVRHeadset;
      }
      
      await window.dcsMax.writeJsonConfig(JSON_CONFIG_PATH, config);
      setOutput(prev => prev + `✓ Configuration saved.\n`);
    } catch (err) {
      console.error('Auto-save error:', err);
    }
  };

  const installAll = async () => {
    if (!confirm('Install all required software using winget?\n\nThis will install:\n• CapFrameX\n• AutoHotkey\n• Notepad++')) {
      return;
    }
    
    setInstalling('all');
    setOutput('Installing all required software...\n');

    try {
      const outputHandler = (data) => {
        setOutput(prev => prev + data.output);
      };
      
      const completeHandler = async (data) => {
        setInstalling(null);
        setOutput(prev => prev + '\n✓ Installation complete! Refreshing and saving...\n');
        // Re-detect and save after installation
        await refreshAfterInstall();
      };
      
      window.dcsMax.onScriptOutput(outputHandler);
      window.dcsMax.onScriptComplete(completeHandler);

      // Run the install script
      window.dcsMax.executeScriptStream('0-Install-Required-Software/0.0.1-Install-Required-Software.ps1', []);
    } catch (err) {
      console.error('Installation error:', err);
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
        <h2 className="text-2xl font-bold text-white mb-2">Install Required Software</h2>
        <p className="text-slate-400 mb-6">
          DCS-Max requires the following software to be installed for full functionality. 
          All software is installed via Windows Package Manager (winget).
        </p>

        {/* Save All Button - Visible at Top */}
        <div className="mb-6 flex justify-end">
          <button
            onClick={handleSavePaths}
            className="flex items-center space-x-2 px-4 py-2 bg-green-600 hover:bg-green-500 rounded transition-colors font-semibold"
            title="Save all application and VR paths to configuration"
          >
            <Save className="w-4 h-4" />
            <span>Save All Configuration</span>
          </button>
        </div>

        {/* VR Headset Detection - MOVED BELOW APPLICATION PATHS */}
        
        {/* Application Paths Configuration */}
        <div className="mb-6">
          <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-white flex items-center">
                <FolderOpen className="w-5 h-5 mr-2 text-yellow-400" />
                Application Paths
              </h3>
              <div className="flex items-center space-x-2">
                <button
                  onClick={detectAllPaths}
                  disabled={checkingStatus}
                  className="flex items-center space-x-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-500 disabled:bg-slate-700 rounded transition-colors text-sm"
                  title="Auto-detect all application paths"
                >
                  <Scan className={`w-4 h-4 ${checkingStatus ? 'animate-pulse' : ''}`} />
                  <span>Detect All</span>
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
            <div className="space-y-3">
              {pathFields.map((field) => (
                <div key={field.key}>
                  <label className="block text-xs font-medium text-slate-400 mb-1 flex items-center space-x-2">
                    <span>{field.label}</span>
                    {field.required && <span className="text-red-400">*</span>}
                    {getPathStatusIcon(field.key)}
                    {pathStatus[field.key] === 'valid' && (
                      <span className="text-xs text-green-400">Found</span>
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
        </div>

        {/* VR Headset Detection */}
        <div className="mb-6">
          <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-white flex items-center">
                <Download className="w-5 h-5 mr-2 text-cyan-400" />
                VR Headset Detection (Optional)
              </h3>
              <button
                onClick={detectVRHeadset}
                disabled={vrDetecting}
                className="flex items-center space-x-2 px-3 py-1.5 bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-700 rounded transition-colors text-sm"
                title="Scan for installed VR headsets"
              >
                <Scan className={`w-4 h-4 ${vrDetecting ? 'animate-pulse' : ''}`} />
                <span>{vrDetecting ? 'Detecting...' : 'Detect VR'}</span>
              </button>
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-slate-400 mb-2">
                  VR Headset
                </label>
                <select
                  value={selectedVRHeadset}
                  onChange={(e) => handleVRHeadsetChange(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-700 text-slate-200 rounded border border-slate-600 focus:border-cyan-500 focus:outline-none text-sm"
                >
                  <option value="none">None (2D mode)</option>
                  {detectedVRHeadsets.map((headset) => (
                    <option key={headset} value={headset}>{headset}</option>
                  ))}
                  <option value="other">Other VR Client (Custom)</option>
                </select>
                {detectedVRHeadsets.length > 0 && (
                  <p className="text-xs text-green-400 mt-2">
                    ✓ Found {detectedVRHeadsets.length} VR client{detectedVRHeadsets.length !== 1 ? 's' : ''}
                  </p>
                )}
                {detectedVRHeadsets.length === 0 && selectedVRHeadset === 'none' && (
                  <p className="text-xs text-slate-400 mt-2">
                    No VR headsets detected. DCS will run in 2D mode.
                  </p>
                )}
              </div>
              
              <div>
                <label className="block text-xs font-medium text-slate-400 mb-2">
                  VR Client Path
                </label>
                <div className="flex items-center space-x-2">
                  <input
                    type="text"
                    value={settings.pimaxPath}
                    onChange={(e) => {
                      setSettings({ ...settings, pimaxPath: e.target.value });
                      setPathSources(prev => ({ ...prev, pimaxPath: 'manual' }));
                      setPathStatus(prev => ({ ...prev, pimaxPath: 'unknown' }));
                    }}
                    onBlur={(e) => verifySinglePath('pimaxPath', e.target.value)}
                    disabled={selectedVRHeadset === 'none'}
                    className={`flex-1 px-3 py-2 bg-slate-700 text-slate-200 rounded border text-sm focus:outline-none disabled:bg-slate-800 disabled:text-slate-500 ${
                      selectedVRHeadset === 'none'
                        ? 'border-slate-700'
                        : pathStatus.pimaxPath === 'valid' 
                          ? 'border-green-500/50 focus:border-green-500' 
                          : pathStatus.pimaxPath === 'invalid'
                            ? 'border-red-500/50 focus:border-red-500'
                            : 'border-slate-600 focus:border-cyan-500'
                    }`}
                    placeholder="VR Client executable path"
                  />
                  <button
                    onClick={() => browseForPath('pimaxPath')}
                    disabled={selectedVRHeadset === 'none'}
                    className="px-3 py-2 bg-slate-600 hover:bg-slate-500 disabled:bg-slate-800 disabled:text-slate-500 rounded transition-colors"
                    title="Browse..."
                  >
                    <FolderOpen className="w-4 h-4" />
                  </button>
                  {getPathStatusIcon('pimaxPath')}
                </div>
                {pathSources.pimaxPath && (
                  <p className="text-xs text-slate-400 mt-2">
                    Source: {pathSources.pimaxPath}
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Software Installation */}
        <div className="mb-6 p-4 rounded-lg border bg-slate-800 border-slate-700">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Package className="w-6 h-6 text-blue-400" />
              <div>
                <div className="font-semibold text-white">
                  {checkingStatus 
                    ? 'Checking installed software...' 
                    : allInstalled 
                      ? 'All required software is installed' 
                      : 'Some software needs to be installed'}
                </div>
                <div className="text-sm text-slate-400">
                  {checkingStatus 
                    ? 'Please wait...'
                    : `${Object.values(installStatus).filter(s => s === 'installed').length} of ${requiredSoftware.length} installed`}
                </div>
              </div>
            </div>
            {!installing && !checkingStatus && (
              <button
                onClick={installAll}
                disabled={installing !== null || allInstalled}
                className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
                  allInstalled 
                    ? 'bg-green-600/50 cursor-not-allowed' 
                    : 'bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700'
                }`}
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
            )}
          </div>
        </div>

        {/* Software List */}
        <div className="space-y-4 mb-6">
          {requiredSoftware.map((software) => (
            <div 
              key={software.id}
              className={`p-4 bg-slate-800 rounded-lg border ${
                installStatus[software.id] === 'installed' 
                  ? 'border-green-500/50' 
                  : installStatus[software.id] === 'not-installed'
                    ? 'border-red-500/50'
                    : 'border-slate-700'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-3">
                  {getStatusIcon(software.id)}
                  <div className="flex-1">
                    <div className="font-semibold text-white flex items-center space-x-2">
                      <span>{software.name}</span>
                      {software.required && (
                        <span className="text-xs bg-blue-500/20 text-blue-400 px-2 py-0.5 rounded">Required</span>
                      )}
                    </div>
                    <p className="text-sm text-slate-400 mt-1">{software.description}</p>
                    <div className="flex items-center space-x-4 mt-2">
                      <span className={`text-xs font-medium ${
                        installStatus[software.id] === 'installed' 
                          ? 'text-green-400' 
                          : installStatus[software.id] === 'not-installed'
                            ? 'text-red-400'
                            : 'text-slate-400'
                      }`}>
                        {getStatusText(software.id)}
                      </span>
                      <a 
                        href={software.website}
                        onClick={(e) => {
                          e.preventDefault();
                          window.dcsMax.openExternal(software.website);
                        }}
                        className="text-xs text-blue-400 hover:text-blue-300 flex items-center space-x-1"
                      >
                        <ExternalLink className="w-3 h-3" />
                        <span>Website</span>
                      </a>
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => installSoftware(software)}
                  disabled={installing !== null || installStatus[software.id] === 'installed'}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ml-4 ${
                    installStatus[software.id] === 'installed'
                      ? 'bg-green-600/30 text-green-400 cursor-not-allowed'
                      : 'bg-green-600 hover:bg-green-700 disabled:bg-slate-700'
                  }`}
                >
                  {installing === software.id ? (
                    <Loader className="w-4 h-4 animate-spin" />
                  ) : installStatus[software.id] === 'installed' ? (
                    <CheckCircle className="w-4 h-4" />
                  ) : (
                    <Download className="w-4 h-4" />
                  )}
                  <span>{
                    installing === software.id 
                      ? 'Installing...' 
                      : installStatus[software.id] === 'installed' 
                        ? 'Installed' 
                        : 'Install'
                  }</span>
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Output Console */}
        {output && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-white mb-3">Installation Output</h3>
            <div className="bg-slate-900 rounded-lg p-4 border border-slate-700 max-h-64 overflow-y-auto">
              <pre className="text-sm text-slate-300 font-mono whitespace-pre-wrap">{output}</pre>
            </div>
          </div>
        )}

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
