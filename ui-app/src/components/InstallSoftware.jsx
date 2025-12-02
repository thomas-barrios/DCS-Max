import React, { useState, useEffect } from 'react';
import { 
  Download,
  CheckCircle,
  XCircle,
  AlertCircle,
  Package,
  ExternalLink,
  Loader
} from 'lucide-react';

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

  useEffect(() => {
    checkInstalledSoftware();
  }, []);

  const checkInstalledSoftware = async () => {
    setCheckingStatus(true);
    const status = {};
    
    for (const software of requiredSoftware) {
      try {
        const result = await window.dcsMax.executeCommand(`winget list --id=${software.wingetId} --exact`);
        // winget returns the package info in stdout if installed
        status[software.id] = result.stdout && result.stdout.includes(software.wingetId) ? 'installed' : 'not-installed';
      } catch (err) {
        console.error('Check error for', software.id, err);
        status[software.id] = 'unknown';
      }
    }
    
    setInstallStatus(status);
    setCheckingStatus(false);
  };

  const installSoftware = async (software) => {
    if (!confirm(`Install ${software.name} using winget?`)) {
      return;
    }
    
    setInstalling(software.id);
    setOutput(`Installing ${software.name}...\n`);

    try {
      // Set up streaming output handler
      window.dcsMax.onScriptOutput((data) => {
        setOutput(prev => prev + data.output);
      });

      window.dcsMax.onScriptComplete((data) => {
        setInstalling(null);
        if (data.exitCode === 0) {
          setInstallStatus(prev => ({ ...prev, [software.id]: 'installed' }));
          setOutput(prev => prev + `\n✓ ${software.name} installed successfully!\n`);
        } else {
          setOutput(prev => prev + `\n✗ Installation may have failed. Check if already installed.\n`);
        }
      });

      // Create a temp PowerShell script to run winget
      window.dcsMax.executeScriptStream(`powershell -Command "winget install --id=${software.wingetId} --exact --scope=user --accept-package-agreements --accept-source-agreements"`, []);
    } catch (err) {
      console.error('Installation error:', err);
      setInstalling(null);
      setOutput(prev => prev + `\nError: ${err.message}\n`);
    }
  };

  const installAll = async () => {
    if (!confirm('Install all required software using winget?\n\nThis will install:\n• CapFrameX\n• AutoHotkey\n• Notepad++')) {
      return;
    }
    
    setInstalling('all');
    setOutput('Installing all required software...\n');

    try {
      window.dcsMax.onScriptOutput((data) => {
        setOutput(prev => prev + data.output);
      });

      window.dcsMax.onScriptComplete((data) => {
        setInstalling(null);
        setOutput(prev => prev + '\n✓ Installation complete! Rechecking...\n');
        // Recheck installed status
        setTimeout(() => checkInstalledSoftware(), 1000);
      });

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

        {/* Status Summary */}
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
