import React, { useState, useEffect, useRef } from 'react';
import { 
  Download, 
  Upload, 
  FolderOpen, 
  Clock,
  HardDrive,
  AlertCircle,
  Shield,
  Calendar,
  Play,
  Loader2,
  RotateCcw,
  X
} from 'lucide-react';

// Strip ANSI escape codes from PowerShell output
const stripAnsi = (str) => {
  if (!str) return str;
  return str.replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '')
            .replace(/\x1B\]0;[^\x07]*\x07/g, '')
            .replace(/[\x00-\x09\x0B-\x0C\x0E-\x1F]/g, '');
};

function BackupRestore() {
  const [activeTab, setActiveTab] = useState('backup');
  const [backups, setBackups] = useState([]);
  const [loading, setLoading] = useState(false);
  const [executing, setExecuting] = useState(false);
  const [output, setOutput] = useState('');
  const [creatingRestorePoint, setCreatingRestorePoint] = useState(false);
  const outputRef = useRef(null);
  const [showTip, setShowTip] = useState(() => {
    const globalSetting = localStorage.getItem('dcsmax-show-tips');
    if (globalSetting === 'false') return false;
    const localSetting = localStorage.getItem('dcsmax-tip-backup');
    return localSetting === null ? true : localSetting === 'true';
  });
  
  const [selectedDcsBackups, setSelectedDcsBackups] = useState({
    dcs: true,
    services: true,
    tasks: true,
    registry: true,
    scheduleAtLogon: false
  });

  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight;
    }
  }, [output]);

  useEffect(() => {
    loadBackups();
    
    // Listen for storage changes (when tips setting is changed in Settings)
    const handleStorage = (e) => {
      if (e.key === 'dcsmax-show-tips') {
        if (e.newValue === 'true') {
          // When globally enabled, check local setting
          const localSetting = localStorage.getItem('dcsmax-tip-backup');
          setShowTip(localSetting !== 'false');
        } else {
          setShowTip(false);
        }
      }
    };
    window.addEventListener('storage', handleStorage);
    
    return () => {
      window.removeEventListener('storage', handleStorage);
    };
  }, []);

  const createRestorePoint = async () => {
    setCreatingRestorePoint(true);
    setOutput('Creating Windows System Restore Point...\nThis may take a minute...\n');
    
    try {
      const result = await window.dcsMax.createRestorePoint('DCS-Max Pre-Optimization');
      
      if (result.success) {
        setOutput(prev => prev + `\n✓ System Restore Point created successfully!\nName: ${result.name}\n\nYou can now safely proceed with changes.`);
      } else {
        setOutput(prev => prev + `\n✗ Failed to create restore point:\n${result.error}\n\nNote: You may need to enable System Protection in Windows settings.`);
      }
    } catch (error) {
      setOutput(prev => prev + `\n✗ Error: ${error.message}`);
    }
    
    setCreatingRestorePoint(false);
  };

  const loadBackups = async () => {
    setLoading(true);
    const result = await window.dcsMax.listBackups();
    if (result.success) {
      setBackups(result.backups);
    }
    setLoading(false);
  };

  const backupCategories = [
    {
      id: 'dcs',
      name: 'DCS Settings',
      description: 'DCS World, Pimax VR, NVIDIA, CapFrameX, Discord',
      script: '1-Backup-Restore/1.4.1-dcs-backup.ps1',
    },
    {
      id: 'services',
      name: 'Windows Services',
      description: 'Service startup configurations',
      script: '1-Backup-Restore/1.3.1-services-backup.ps1',
    },
    {
      id: 'tasks',
      name: 'Scheduled Tasks',
      description: 'Task Scheduler settings',
      script: '1-Backup-Restore/1.2.1-tasks-backup.ps1',
    },
    {
      id: 'registry',
      name: 'Registry Keys',
      description: 'Performance-related registry values',
      script: '1-Backup-Restore/1.1.1-registry-backup.ps1',
    },
    {
      id: 'scheduleAtLogon',
      name: 'Schedule DCS Backup at Logon',
      description: 'Auto-backup DCS settings when you log in to Windows',
      script: '1-Backup-Restore/1.4.3-schedule-dcs-backup-at-logon.ps1',
      isSchedule: true,
    }
  ];

  const runSelectedBackups = async () => {
    const selectedCategories = backupCategories.filter(cat => selectedDcsBackups[cat.id]);
    if (selectedCategories.length === 0) return;

    setExecuting(true);
    setOutput('Starting selected operations...\n');

    for (const category of selectedCategories) {
      const actionName = category.isSchedule ? 'Scheduling' : 'Backing up';
      const completedName = category.isSchedule ? 'scheduled' : 'backup completed';
      setOutput(prev => prev + `\n=== ${category.name} ===\n`);

      await new Promise((resolve) => {
        window.dcsMax.removeAllListeners('script-output');
        window.dcsMax.removeAllListeners('script-complete');

        window.dcsMax.onScriptOutput((data) => {
          setOutput(prev => prev + stripAnsi(data.data));
        });

        window.dcsMax.onScriptComplete((data) => {
          if (data.code === 0) {
            setOutput(prev => prev + `\n✓ ${category.name} ${completedName}!\n`);
          } else {
            setOutput(prev => prev + `\n✗ ${category.name} failed!\n`);
          }
          resolve();
        });

        window.dcsMax.executeScriptStream(category.script, ['-NoPause']);
      });

      await new Promise(resolve => setTimeout(resolve, 500));
    }

    setOutput(prev => prev + '\n=== All Operations Complete ===\n');
    setExecuting(false);
    loadBackups();
  };

  const restoreBackup = async (backupName) => {
    if (!confirm(`Are you sure you want to restore from backup: ${backupName}?`)) {
      return;
    }

    setExecuting(true);
    setOutput('Starting restore...\n');

    window.dcsMax.removeAllListeners('script-output');
    window.dcsMax.removeAllListeners('script-complete');

    let script = '';
    let args = ['-NoPause'];
    
    if (backupName.includes('dcs-settings-backup')) {
      script = '1-Backup-Restore/1.4.2-dcs-restore.ps1';
      args = ['-BackupFolder', `Backups\\${backupName}`, '-NoPause'];
    } else if (backupName.includes('services-backup')) {
      script = '1-Backup-Restore/1.3.3-services-restore-from-backup.ps1';
      args = ['-BackupFile', backupName, '-NoPause'];
    } else if (backupName.includes('tasks-backup')) {
      script = '1-Backup-Restore/1.2.3-tasks-restore.ps1';
      args = ['-XmlFile', `Backups\\${backupName}`, '-NoPause'];
    } else if (backupName.includes('registry-backup')) {
      script = '1-Backup-Restore/1.1.3-registry-restore.ps1';
      args = ['-RegFile', `Backups\\${backupName}`, '-NoPause'];
    } else {
      setOutput(prev => prev + '✗ Unknown backup type\n');
      setExecuting(false);
      return;
    }

    window.dcsMax.onScriptOutput((data) => {
      setOutput(prev => prev + stripAnsi(data.data));
    });

    window.dcsMax.onScriptComplete((data) => {
      setExecuting(false);
      if (data.code === 0) {
        setOutput(prev => prev + '\n✓ Restore completed successfully!\n');
      } else {
        setOutput(prev => prev + '\n✗ Restore failed!\n' + (data.stderr || ''));
      }
    });

    window.dcsMax.executeScriptStream(script, args);
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleString();
  };

  const formatSize = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const getBackupTypeColor = (type) => {
    if (type.includes('DCS')) return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
    if (type.includes('Services')) return 'bg-green-500/20 text-green-400 border-green-500/30';
    if (type.includes('Tasks')) return 'bg-purple-500/20 text-purple-400 border-purple-500/30';
    if (type.includes('Registry')) return 'bg-orange-500/20 text-orange-400 border-orange-500/30';
    return 'bg-slate-500/20 text-slate-400 border-slate-500/30';
  };

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Left Panel */}
      <div className="w-1/3 border-r border-slate-700 overflow-y-auto">
        <div className="p-6">
          {/* Tab Buttons */}
          <div className="flex space-x-2 mb-6">
            <button
              onClick={() => setActiveTab('backup')}
              className={`flex-1 flex items-center justify-center space-x-2 px-4 py-3 rounded-lg font-semibold transition-colors ${
                activeTab === 'backup'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
              }`}
            >
              <Download className="w-5 h-5" />
              <span>Backup</span>
            </button>
            <button
              onClick={() => setActiveTab('restore')}
              className={`flex-1 flex items-center justify-center space-x-2 px-4 py-3 rounded-lg font-semibold transition-colors ${
                activeTab === 'restore'
                  ? 'bg-green-600 text-white'
                  : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
              }`}
            >
              <RotateCcw className="w-5 h-5" />
              <span>Restore</span>
            </button>
          </div>

          {/* Backup Tab Content */}
          {activeTab === 'backup' && (
            <>
              <h2 className="text-2xl font-bold text-white mb-6">Create Backup</h2>

              {/* Warning Banner */}
              {showTip && (
                <div className="bg-warning-500/20 border border-warning-500/50 rounded-lg p-4 mb-6">
                  <div className="flex items-start space-x-3">
                    <AlertCircle className="w-5 h-5 text-warning-500 flex-shrink-0 mt-0.5" />
                    <div className="flex-1 text-sm text-warning-200">
                      <strong>Tip:</strong> Create a Windows restore point before making system changes.
                    </div>
                    <button
                      onClick={() => {
                        setShowTip(false);
                        localStorage.setItem('dcsmax-tip-backup', 'false');
                      }}
                      className="text-warning-500/60 hover:text-warning-500 transition-colors"
                      title="Dismiss tip"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              )}

              {/* Create Restore Point Button */}
              <button
                onClick={createRestorePoint}
                disabled={creatingRestorePoint || executing}
                className="w-full flex items-center justify-center space-x-3 px-4 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 disabled:from-slate-700 disabled:to-slate-700 disabled:cursor-not-allowed rounded-lg transition-all mb-6 shadow-lg"
              >
                <Shield className="w-5 h-5" />
                <span className="font-semibold">
                  {creatingRestorePoint ? 'Creating Restore Point...' : 'Create Windows Restore Point'}
                </span>
              </button>

              {/* Backup Selection */}
              <h3 className="text-lg font-semibold text-white mb-4">Select Items to Backup</h3>
              <div className="space-y-3 mb-4">
                {backupCategories.map((cat) => (
                  <div
                    key={cat.id}
                    className="bg-slate-800 rounded-lg p-3 border border-slate-700"
                  >
                    <label className="flex items-start space-x-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={selectedDcsBackups[cat.id]}
                        onChange={(e) => setSelectedDcsBackups({
                          ...selectedDcsBackups,
                          [cat.id]: e.target.checked
                        })}
                        disabled={executing}
                        className="mt-1 w-5 h-5 text-blue-600 bg-slate-700 border-slate-600 rounded focus:ring-blue-500"
                      />
                      <div className="flex-1">
                        <div className="font-semibold text-white">{cat.name}</div>
                        <div className="text-xs text-slate-400">{cat.description}</div>
                      </div>
                    </label>
                  </div>
                ))}
              </div>

              {/* Run Button */}
              <button
                onClick={runSelectedBackups}
                disabled={executing || !Object.values(selectedDcsBackups).some(v => v)}
                className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 disabled:cursor-not-allowed rounded-lg transition-colors font-semibold"
              >
                {executing ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    <span>Running...</span>
                  </>
                ) : (
                  <>
                    <Play className="w-5 h-5" />
                    <span>Run Selected</span>
                  </>
                )}
              </button>
            </>
          )}

          {/* Restore Tab Content */}
          {activeTab === 'restore' && (
            <>
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-white">Restore from Backup</h2>
                <button
                  onClick={loadBackups}
                  disabled={loading}
                  className="text-blue-400 hover:text-blue-300 text-sm flex items-center space-x-1"
                >
                  <RotateCcw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                  <span>{loading ? 'Loading...' : 'Refresh'}</span>
                </button>
              </div>

              {/* Warning */}
              <div className="bg-warning-500/20 border border-warning-500/50 rounded-lg p-4 mb-6">
                <div className="flex items-start space-x-3">
                  <AlertCircle className="w-5 h-5 text-warning-500 flex-shrink-0 mt-0.5" />
                  <div className="text-sm text-warning-200">
                    <strong>Warning:</strong> Restoring will overwrite current settings with backed up values.
                  </div>
                </div>
              </div>

              {backups.length === 0 ? (
                <div className="text-center py-12 text-slate-400">
                  <FolderOpen className="w-16 h-16 mx-auto mb-4 opacity-50" />
                  <p className="text-lg mb-2">No backups found</p>
                  <p className="text-sm">Create your first backup in the Backup tab</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {backups.map((backup) => (
                    <div
                      key={backup.name}
                      className="bg-slate-800 rounded-lg p-4 border border-slate-700 hover:border-slate-600 transition-colors"
                    >
                      <div className="flex items-center justify-between mb-3">
                        <span className={`px-2 py-1 rounded text-xs font-medium border ${getBackupTypeColor(backup.type)}`}>
                          {backup.type}
                        </span>
                        <button
                          onClick={() => restoreBackup(backup.name)}
                          disabled={executing}
                          className="flex items-center space-x-2 px-3 py-1.5 bg-green-600 hover:bg-green-700 disabled:bg-slate-700 rounded text-sm transition-colors font-medium"
                        >
                          <Upload className="w-4 h-4" />
                          <span>Restore</span>
                        </button>
                      </div>
                      <div className="text-xs text-slate-400 space-y-1">
                        <div className="flex items-center space-x-2">
                          <Clock className="w-3 h-3" />
                          <span>{formatDate(backup.date)}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <HardDrive className="w-3 h-3" />
                          <span>{formatSize(backup.size)}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* Right Panel - Output */}
      <div className="flex-1 flex flex-col overflow-hidden bg-slate-950">
        <div className="p-4 border-b border-slate-700 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-white">Output</h3>
          {executing && (
            <div className="flex items-center space-x-2 text-blue-400">
              <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
              <span className="text-sm">Running...</span>
            </div>
          )}
        </div>
        <div ref={outputRef} className="flex-1 overflow-y-auto p-4">
          <pre className="log-output text-slate-300">
            {output || 'No output yet. Select an action to begin.'}
          </pre>
        </div>
      </div>
    </div>
  );
}

export default BackupRestore;
