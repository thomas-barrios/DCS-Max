import React, { useState, useEffect } from 'react';
import { 
  FolderOpen, 
  Save,
  ExternalLink,
  CheckCircle,
  XCircle,
  Loader,
  RefreshCw,
  Lightbulb,
  Scan
} from 'lucide-react';

function SettingsPanel() {
  const [settings, setSettings] = useState({
    dcsPath: '',
    savedGamesPath: '',
    capframexPath: '',
    autoHotkeyPath: '',
    pimaxPath: '',
    notepadppPath: '',
    benchmarkMissionPath: '',
    createRestorePoint: true,
    autoBackup: true,
    logLevel: 'info'
  });

  const [pathStatus, setPathStatus] = useState({});
  const [checking, setChecking] = useState(true);
  const [loading, setLoading] = useState(true);
  const [projectRoot, setProjectRoot] = useState('');
  const [showTips, setShowTips] = useState(() => {
    const saved = localStorage.getItem('dcsmax-show-tips');
    return saved === null ? true : saved === 'true';
  });
  const [pathSources, setPathSources] = useState({});

  const pathFields = [
    { key: 'dcsPath', label: 'DCS World Executable', required: true },
    { key: 'savedGamesPath', label: 'DCS Saved Games Folder', required: true, isFolder: true },
    { key: 'capframexPath', label: 'CapFrameX Executable', required: false },
    { key: 'autoHotkeyPath', label: 'AutoHotkey v2 Executable', required: false },
    { key: 'pimaxPath', label: 'Pimax Client (VR only)', required: false },
    { key: 'notepadppPath', label: 'Notepad++', required: false },
    { key: 'benchmarkMissionPath', label: 'Benchmark Mission File', required: false, isRelative: true }
  ];

  useEffect(() => {
    // Initialize: get project root, load paths from INI, detect as fallback
    const init = async () => {
      setLoading(true);
      let root = '';
      
      try {
        // Get project root
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

      try {
        // Try to load paths from INI first
        const iniResult = await window.dcsMax.readSettingsPaths();
        if (iniResult.success && iniResult.paths) {
          for (const [key, value] of Object.entries(iniResult.paths)) {
            if (value) {
              newSettings[key] = value;
              sources[key] = 'ini';
            }
          }
        }
      } catch (err) {
        console.error('Failed to read settings from INI:', err);
      }

      try {
        // Detect paths for any that weren't in INI
        const detectResult = await window.dcsMax.detectPaths();
        if (detectResult.success && detectResult.paths) {
          for (const [key, pathInfo] of Object.entries(detectResult.paths)) {
            // Only use detected path if we don't have one from INI
            if (!newSettings[key] && pathInfo.path) {
              newSettings[key] = pathInfo.path;
              sources[key] = pathInfo.found ? `detected (${pathInfo.source})` : 'default';
            }
          }
        }
      } catch (err) {
        console.error('Failed to detect paths:', err);
      }

      setSettings(newSettings);
      setPathSources(sources);
      setLoading(false);
      
      // Verify all paths
      verifyAllPaths(root, newSettings);
    };
    
    init();
  }, []);

  const verifyAllPaths = async (root = projectRoot, currentSettings = settings) => {
    setChecking(true);
    const status = {};
    
    for (const field of pathFields) {
      const path = currentSettings[field.key];
      if (path) {
        status[field.key] = await verifyPath(path, field.isFolder, field.isRelative, root);
      } else {
        status[field.key] = 'empty';
      }
    }
    
    setPathStatus(status);
    setChecking(false);
  };

  const verifyPath = async (path, isFolder = false, isRelative = false, root = projectRoot) => {
    try {
      let fullPath = path;
      
      // For relative paths (like benchmark missions), resolve from project root
      if (isRelative && !path.includes(':') && root) {
        // The benchmark mission path is relative to 4-Performance-Testing folder
        fullPath = `${root}\\4-Performance-Testing\\${path}`;
      }
      
      const testCommand = isFolder 
        ? `Test-Path -Path '${fullPath}' -PathType Container`
        : `Test-Path -Path '${fullPath}' -PathType Leaf`;
      
      const result = await window.dcsMax.executeCommand(testCommand);
      return result.stdout && result.stdout.trim().toLowerCase() === 'true' ? 'valid' : 'invalid';
    } catch (err) {
      console.error('Path verification error:', err);
      return 'error';
    }
  };

  const verifySinglePath = async (key) => {
    const field = pathFields.find(f => f.key === key);
    const path = settings[key];
    if (path) {
      setPathStatus(prev => ({ ...prev, [key]: 'checking' }));
      const status = await verifyPath(path, field?.isFolder, field?.isRelative, projectRoot);
      setPathStatus(prev => ({ ...prev, [key]: status }));
    }
  };

  const getStatusIcon = (key) => {
    const status = pathStatus[key];
    if (checking || status === 'checking') {
      return <Loader className="w-5 h-5 text-slate-400 animate-spin" />;
    }
    switch (status) {
      case 'valid':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'invalid':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'empty':
        return <XCircle className="w-5 h-5 text-slate-500" />;
      default:
        return <XCircle className="w-5 h-5 text-yellow-500" />;
    }
  };

  const handleSave = async () => {
    try {
      // Save path settings to INI file
      const pathsToSave = {};
      for (const field of pathFields) {
        if (settings[field.key]) {
          pathsToSave[field.key] = settings[field.key];
        }
      }
      
      const result = await window.dcsMax.writeSettingsPaths(pathsToSave);
      if (result.success) {
        alert('Settings saved to configuration file!');
      } else {
        alert('Error saving settings: ' + (result.error || 'Unknown error'));
      }
    } catch (err) {
      console.error('Save error:', err);
      alert('Error saving settings: ' + err.message);
    }
  };

  const detectAllPaths = async () => {
    try {
      setLoading(true);
      const result = await window.dcsMax.detectPaths();
      if (result.success && result.paths) {
        const newSettings = { ...settings };
        const sources = { ...pathSources };
        
        for (const [key, pathInfo] of Object.entries(result.paths)) {
          // Only update if the current setting is empty or uses a default/detected path
          // Preserve user-set paths (from INI, manual entry, or browse)
          const currentSource = pathSources[key] || '';
          const isUserSet = currentSource === 'ini' || currentSource === 'manual' || currentSource === 'user selected';
          
          if (!isUserSet && pathInfo.path) {
            newSettings[key] = pathInfo.path;
            sources[key] = pathInfo.found ? `detected (${pathInfo.source})` : 'default';
          }
        }
        
        setSettings(newSettings);
        setPathSources(sources);
        verifyAllPaths(projectRoot, newSettings);
      }
    } catch (err) {
      console.error('Detection error:', err);
    } finally {
      setLoading(false);
    }
  };
  const browseForPath = async (settingKey) => {
    try {
      // Check if bridge is available
      if (!window.dcsMax) {
        console.error('Bridge check failed: window.dcsMax is', window.dcsMax);
        alert('Bridge not available. Please enter the path manually.');
        return;
      }

      // Determine if this is a folder or file picker based on the setting
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
        const newSettings = { ...settings, [settingKey]: result.path };
        setSettings(newSettings);
        setPathSources(prev => ({ ...prev, [settingKey]: 'user selected' }));
        
        // Verify the newly selected path
        setTimeout(() => verifySinglePath(settingKey), 100);
        
        // Auto-save the path to INI
        try {
          const pathsToSave = { [settingKey]: result.path };
          await window.dcsMax.writeSettingsPaths(pathsToSave);
        } catch (saveErr) {
          console.error('Failed to auto-save path:', saveErr);
        }
      }
    } catch (error) {
      console.error('Browse error:', error);
      alert('Error opening file browser: ' + error.message);
    }
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          <Loader className="w-8 h-8 text-blue-500 animate-spin mx-auto mb-4" />
          <p className="text-slate-400">Loading settings...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="max-w-4xl mx-auto p-8">
        <h2 className="text-3xl font-bold text-white mb-6">Settings</h2>

        {/* Display Options */}
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700 mb-6">
          <h3 className="text-xl font-semibold text-white flex items-center mb-4">
            <Lightbulb className="w-5 h-5 mr-2 text-yellow-400" />
            Display Options
          </h3>
          <div className="flex items-center justify-between">
            <div>
              <label className="text-slate-200 font-medium">Show Tips</label>
              <p className="text-sm text-slate-400">Display helpful tips throughout the application</p>
            </div>
            <button
              onClick={() => {
                const newValue = !showTips;
                setShowTips(newValue);
                localStorage.setItem('dcsmax-show-tips', String(newValue));
                // When enabling tips globally, reset all individual tip settings
                if (newValue) {
                  localStorage.removeItem('dcsmax-tip-benchmarking');
                  localStorage.removeItem('dcsmax-tip-backup');
                  localStorage.removeItem('dcsmax-tip-optimization');
                }
                // Dispatch storage event for same-window updates
                window.dispatchEvent(new StorageEvent('storage', {
                  key: 'dcsmax-show-tips',
                  newValue: String(newValue)
                }));
              }}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                showTips ? 'bg-green-600' : 'bg-slate-600'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  showTips ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>

        {/* Paths Configuration */}
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-semibold text-white flex items-center">
              <FolderOpen className="w-5 h-5 mr-2 text-yellow-400" />
              Application Paths
            </h3>
            <div className="flex items-center space-x-2">
              <button
                onClick={detectAllPaths}
                disabled={loading}
                className="flex items-center space-x-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-500 disabled:bg-slate-800 rounded transition-colors text-sm"
                title="Auto-detect all application paths"
              >
                <Scan className={`w-4 h-4 ${loading ? 'animate-pulse' : ''}`} />
                <span>Detect All</span>
              </button>
              <button
                onClick={() => verifyAllPaths(projectRoot, settings)}
                disabled={checking}
                className="flex items-center space-x-2 px-3 py-1.5 bg-slate-700 hover:bg-slate-600 disabled:bg-slate-800 rounded transition-colors text-sm"
              >
                <RefreshCw className={`w-4 h-4 ${checking ? 'animate-spin' : ''}`} />
                <span>Verify All</span>
              </button>
            </div>
          </div>
          <div className="space-y-4">
            {pathFields.map((field) => (
              <div key={field.key}>
                <label className="block text-sm font-medium text-slate-300 mb-2 flex items-center space-x-2">
                  <span>{field.label}</span>
                  {field.required && <span className="text-red-400">*</span>}
                  {getStatusIcon(field.key)}
                  {pathStatus[field.key] === 'valid' && (
                    <span className="text-xs text-green-400">Found</span>
                  )}
                  {pathStatus[field.key] === 'invalid' && (
                    <span className="text-xs text-red-400">Not found</span>
                  )}
                  {pathSources[field.key] && (
                    <span className="text-xs text-slate-500 ml-2">({pathSources[field.key]})</span>
                  )}
                </label>
                <div className="flex items-center space-x-2">
                  <input
                    type="text"
                    value={settings[field.key]}
                    onChange={(e) => {
                      setSettings({ ...settings, [field.key]: e.target.value });
                      setPathSources(prev => ({ ...prev, [field.key]: 'manual' }));
                      // Clear status when user types
                      setPathStatus(prev => ({ ...prev, [field.key]: 'unknown' }));
                    }}
                    onBlur={() => verifySinglePath(field.key)}
                    className={`flex-1 px-4 py-2 bg-slate-700 text-slate-200 rounded border focus:outline-none ${
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
                    className="px-4 py-2 bg-slate-600 hover:bg-slate-500 rounded transition-colors"
                    title="Browse..."
                  >
                    <FolderOpen className="w-5 h-5" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Links */}
        <div className="bg-gradient-to-r from-blue-900/50 to-purple-900/50 rounded-lg p-6 border border-blue-700/50 mb-6">
          <h3 className="text-xl font-semibold text-white mb-4">Helpful Links</h3>
          <div className="space-y-2">
            {[
              { label: 'GitHub Repository', url: 'https://github.com/thomas-barrios/DCS-Max' },
              { label: 'Documentation', url: 'https://github.com/thomas-barrios/DCS-Max/wiki' },
              { label: 'Report Issues', url: 'https://github.com/thomas-barrios/DCS-Max/issues' },
              { label: 'DCS Forums Thread', url: 'https://forum.dcs.world' }
            ].map((link) => (
              <a
                key={link.label}
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-between p-3 bg-slate-800/50 hover:bg-slate-700/50 rounded transition-colors"
              >
                <span className="text-slate-200">{link.label}</span>
                <ExternalLink className="w-4 h-4 text-blue-400" />
              </a>
            ))}
          </div>
        </div>

        {/* Save Button */}
        <div className="flex justify-end">
          <button
            onClick={handleSave}
            className="flex items-center space-x-2 px-6 py-3 bg-green-600 hover:bg-green-700 rounded-lg transition-colors font-semibold"
          >
            <Save className="w-5 h-5" />
            <span>Save Settings</span>
          </button>
        </div>
      </div>
    </div>
  );
}

export default SettingsPanel;
