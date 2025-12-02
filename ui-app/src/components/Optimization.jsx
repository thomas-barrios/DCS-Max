import React, { useState, useEffect, useRef } from 'react';
import { 
  Play, 
  Settings, 
  AlertTriangle,
  CheckCircle2,
  Loader2,
  Shield,
  ChevronDown,
  ChevronUp,
  Cpu,
  HardDrive,
  Clock,
  Trash2
} from 'lucide-react';

// Strip ANSI escape codes from PowerShell output
const stripAnsi = (str) => {
  if (!str) return str;
  return str.replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '')
            .replace(/\x1B\]0;[^\x07]*\x07/g, '')
            .replace(/[\x00-\x09\x0B-\x0C\x0E-\x1F]/g, '');
};

function Optimization({ isAdmin }) {
  const [services, setServices] = useState([]);
  const [selectedOptimizations, setSelectedOptimizations] = useState({
    services: true,
    tasks: true,
    registry: true,
    cache: false
  });
  const [expandedCategory, setExpandedCategory] = useState(null);
  const [executing, setExecuting] = useState(false);
  const [output, setOutput] = useState('');
  const [creatingRestorePoint, setCreatingRestorePoint] = useState(false);
  const outputRef = useRef(null);

  // Auto-scroll output to bottom when content changes
  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight;
    }
  }, [output]);

  const createRestorePoint = async () => {
    setCreatingRestorePoint(true);
    setOutput('Creating Windows System Restore Point...\nThis may take a minute...\n');
    
    try {
      const result = await window.dcsMax.createRestorePoint('DCS-Max Pre-Optimization');
      
      if (result.success) {
        setOutput(prev => prev + `\n✓ System Restore Point created successfully!\nName: ${result.name}\n\nYou can now safely proceed with optimizations.`);
      } else {
        setOutput(prev => prev + `\n✗ Failed to create restore point:\n${result.error}\n\nNote: You may need to enable System Protection in Windows settings.`);
      }
    } catch (error) {
      setOutput(prev => prev + `\n✗ Error: ${error.message}`);
    }
    
    setCreatingRestorePoint(false);
  };

  const optimizationCategories = [
    {
      id: 'registry',
      name: 'Registry Optimization',
      description: 'Optimize Windows registry for gaming performance',
      script: '5-Optimization/5.1.2-registry-optimize.ps1',
      impact: 'High',
      requiresRestart: 'Recommended',
      icon: Cpu,
      details: {
        summary: 'Applies 14 registry optimizations to prioritize gaming performance. Changes affect CPU scheduling, GPU rendering, MMCSS settings, and system responsiveness.',
        categories: [
          {
            name: 'CPU & Power Management (4)',
            items: [
              { setting: 'CPU Core Parking', value: 'Disabled', desc: 'Keeps all cores active and ready, reducing latency spikes' },
              { setting: 'DCS CPU Priority', value: 'High (3)', desc: 'DCS.exe gets preferential CPU time over background processes' },
              { setting: 'Power Throttling', value: 'Disabled', desc: 'Maintains consistent clock speeds during gameplay' },
              { setting: 'Priority Separation', value: '26 (Long Fixed)', desc: 'More CPU time to foreground applications' }
            ]
          },
          {
            name: 'GPU & Rendering (2)',
            items: [
              { setting: 'Max Pre-Rendered Frames', value: '1', desc: 'Reduces input lag (critical for VR)' },
              { setting: 'GPU Priority', value: '14 (High)', desc: 'High GPU scheduling priority for games' }
            ]
          },
          {
            name: 'MMCSS Game Profile (6)',
            items: [
              { setting: 'Game CPU Affinity', value: '0x0F (4 cores)', desc: 'Pins games to first 4 cores for cache efficiency' },
              { setting: 'Background Only', value: 'Disabled', desc: 'Games run as foreground priority' },
              { setting: 'CPU Priority', value: '6 (Highest)', desc: 'Maximum CPU scheduling priority' },
              { setting: 'Scheduling Category', value: 'High', desc: 'High priority thread scheduling' },
              { setting: 'SFIO Priority', value: 'High', desc: 'High priority I/O operations' },
              { setting: 'GPU Priority', value: '14 (High)', desc: 'GPU scheduling priority for games' }
            ]
          },
          {
            name: 'System Settings (2)',
            items: [
              { setting: 'GameDVR Recording', value: 'Disabled', desc: 'Frees GPU encoder, reduces frame time spikes' },
              { setting: 'Network Throttling', value: 'Disabled', desc: 'Network packets aren\'t delayed during gameplay' },
              { setting: 'System Responsiveness', value: '10%', desc: '90% of CPU available for games' }
            ]
          }
        ]
      }
    },
    {
      id: 'services',
      name: 'Windows Services',
      description: 'Disable unnecessary background services',
      script: '5-Optimization/5.3.2-services-optimize.ps1',
      impact: 'High',
      requiresRestart: 'No',
      icon: HardDrive,
      details: {
        summary: 'Disables 40+ non-essential Windows services that run continuously in the background. Frees up RAM, reduces CPU overhead, and eliminates sources of stutters.',
        categories: [
          {
            name: 'Telemetry & Diagnostics (4)',
            items: [
              { setting: 'DiagTrack', value: 'Disabled', desc: 'Telemetry uses CPU and network constantly' },
              { setting: 'DPS', value: 'Disabled', desc: 'Diagnostic scans are resource-intensive' },
              { setting: 'WdiServiceHost', value: 'Disabled', desc: 'Background diagnostics cause micro-stutters' },
              { setting: 'WdiSystemHost', value: 'Disabled', desc: 'Unnecessary CPU overhead' }
            ]
          },
          {
            name: 'Windows Update (3)',
            items: [
              { setting: 'UsoSvc', value: 'Disabled', desc: 'Prevents background updates during gameplay' },
              { setting: 'TrustedInstaller', value: 'Disabled', desc: 'Avoids update-triggered disk activity' },
              { setting: 'WaaSMedicSvc', value: 'Disabled', desc: 'Redundant repair service' }
            ]
          },
          {
            name: 'Xbox & Gaming (5)',
            items: [
              { setting: 'XblAuthManager', value: 'Disabled', desc: 'DCS doesn\'t use Xbox Live' },
              { setting: 'XblGameSave', value: 'Disabled', desc: 'Cloud saves not used by DCS' },
              { setting: 'XboxNetApiSvc', value: 'Disabled', desc: 'Reduces network overhead' },
              { setting: 'XboxGipSvc', value: 'Disabled', desc: 'No Xbox accessories used' },
              { setting: 'BcastDVRUserService', value: 'Disabled', desc: 'GameDVR causes frame drops in VR' }
            ]
          },
          {
            name: 'Cloud & Microsoft (4)',
            items: [
              { setting: 'wlidsvc', value: 'Disabled', desc: 'MS Account: No cloud sync needed' },
              { setting: 'WalletService', value: 'Disabled', desc: 'Irrelevant for gaming' },
              { setting: 'ClipSVC', value: 'Disabled', desc: 'No Store apps, saves 50-100MB RAM' },
              { setting: 'BackgroundApps', value: 'Disabled', desc: 'Globally disables background apps' }
            ]
          },
          {
            name: 'Search & Indexing (2)',
            items: [
              { setting: 'WSearch', value: 'Disabled', desc: 'Heavy disk I/O competes with DCS loading' },
              { setting: 'Indexing', value: 'Disabled', desc: 'Minimizes disk I/O on game drives' }
            ]
          },
          {
            name: 'Printer & Fax (4)',
            items: [
              { setting: 'Spooler', value: 'Disabled', desc: 'No printing needed during gaming' },
              { setting: 'PrintNotify', value: 'Disabled', desc: 'Unnecessary notifications' },
              { setting: 'PrintWorkflowUserSvc', value: 'Disabled', desc: 'Workflow not needed' },
              { setting: 'Fax', value: 'Disabled', desc: 'Obsolete service' }
            ]
          },
          {
            name: 'Network Discovery (3)',
            items: [
              { setting: 'SSDPSRV', value: 'Disabled', desc: 'Cuts broadcast traffic' },
              { setting: 'UPnPHost', value: 'Disabled', desc: 'No UPnP hosting needed' },
              { setting: 'FDResPub', value: 'Disabled', desc: 'No device discovery needed' }
            ]
          },
          {
            name: 'Location & Sensors (4)',
            items: [
              { setting: 'lfsvc', value: 'Disabled', desc: 'Geolocation not used' },
              { setting: 'SensorService', value: 'Disabled', desc: 'No sensors in desktop' },
              { setting: 'SensrSvc', value: 'Disabled', desc: 'No sensor monitoring needed' },
              { setting: 'SensorDataService', value: 'Disabled', desc: 'No sensor data needed' }
            ]
          },
          {
            name: 'Hardware & Drivers (4)',
            items: [
              { setting: 'RtkUWPService', value: 'Disabled', desc: 'Realtek: Conflicts with gaming audio' },
              { setting: 'AmdPmuService', value: 'Disabled', desc: 'AMD: DCS uses own optimization' },
              { setting: 'AmdAcpSvc', value: 'Disabled', desc: 'AMD: Compatibility DB not needed' },
              { setting: 'Power', value: 'Disabled', desc: 'Causes VR stutters from power state changes' }
            ]
          },
          {
            name: 'Remote & Backup (4)',
            items: [
              { setting: 'RemoteRegistry', value: 'Disabled', desc: 'Security risk, not needed' },
              { setting: 'TermService', value: 'Disabled', desc: 'RDP unneeded for local gaming' },
              { setting: 'fhsvc', value: 'Disabled', desc: 'File History: Heavy disk I/O' },
              { setting: 'WorkFolders', value: 'Disabled', desc: 'Enterprise sync not needed' }
            ]
          },
          {
            name: 'Other Services (5)',
            items: [
              { setting: 'MapsBroker', value: 'Disabled', desc: 'Maps irrelevant for gaming' },
              { setting: 'PhoneSvc', value: 'Disabled', desc: 'No telephony on desktop' },
              { setting: 'wisvc', value: 'Disabled', desc: 'Insider Program not needed' },
              { setting: 'WebClient', value: 'Disabled', desc: 'WebDAV avoids reconnects' },
              { setting: 'stisvc', value: 'Disabled', desc: 'No scanning needed' }
            ]
          }
        ]
      }
    },
    {
      id: 'tasks',
      name: 'Scheduled Tasks',
      description: 'Optimize Windows scheduled tasks',
      script: '5-Optimization/5.2.2-tasks-optimize.ps1',
      impact: 'Medium',
      requiresRestart: 'No',
      icon: Clock,
      details: {
        summary: 'Disables 60+ Windows scheduled tasks that run at various intervals, consuming CPU, disk, and network resources. These tasks can cause micro-stutters and frame drops during gameplay.',
        categories: [
          {
            name: 'Application Experience (6)',
            items: [
              { setting: 'Microsoft Compatibility Appraiser', value: 'Disabled', desc: 'Heavy disk I/O scanning applications' },
              { setting: 'Compatibility Appraiser Exp', value: 'Disabled', desc: 'Experimental telemetry scanning' },
              { setting: 'StartupAppTask', value: 'Disabled', desc: 'Application startup analysis' },
              { setting: 'MareBackup', value: 'Disabled', desc: 'Background backup task' },
              { setting: 'PcaPatchDbTask', value: 'Disabled', desc: 'Compatibility database patching' },
              { setting: 'SdbinstMergeDbTask', value: 'Disabled', desc: 'Database merge operations' }
            ]
          },
          {
            name: 'Windows Defender (4)',
            items: [
              { setting: 'Defender Cache Maintenance', value: 'Disabled', desc: 'Cache operations cause disk I/O' },
              { setting: 'Defender Cleanup', value: 'Disabled', desc: 'Cleanup operations during gameplay' },
              { setting: 'Defender Scheduled Scan', value: 'Disabled', desc: 'Scans consume significant resources' },
              { setting: 'Defender Verification', value: 'Disabled', desc: 'Definition verification overhead' }
            ]
          },
          {
            name: '.NET Framework (4)',
            items: [
              { setting: 'NGEN v4.0.30319', value: 'Disabled', desc: 'Native image generation - heavy CPU' },
              { setting: 'NGEN v4.0.30319 64', value: 'Disabled', desc: '64-bit native image generation' },
              { setting: 'NGEN Critical', value: 'Disabled', desc: 'Critical priority can interrupt gameplay' },
              { setting: 'NGEN 64 Critical', value: 'Disabled', desc: '64-bit critical priority tasks' }
            ]
          },
          {
            name: 'Browser Updates (3)',
            items: [
              { setting: 'Edge Update Core', value: 'Disabled', desc: 'Edge browser update service' },
              { setting: 'Edge Update UA', value: 'Disabled', desc: 'Edge user agent updates' },
              { setting: 'Google Updater', value: 'Disabled', desc: 'Chrome update background activity' }
            ]
          },
          {
            name: 'Windows Update (4)',
            items: [
              { setting: 'Scheduled Start', value: 'Disabled', desc: 'Prevents scheduled update starts' },
              { setting: 'Refresh Group Policy Cache', value: 'Disabled', desc: 'Policy refresh overhead' },
              { setting: 'WaaSMedic PerformRemediation', value: 'Disabled', desc: 'Update remediation service' },
              { setting: 'PauseWindowsUpdate', value: 'Disabled', desc: 'Update pause management' }
            ]
          },
          {
            name: 'App & Data Management (8)',
            items: [
              { setting: 'AppListBackup', value: 'Disabled', desc: 'App list backup operations' },
              { setting: 'BackupNonMaintenance', value: 'Disabled', desc: 'Non-maintenance backups' },
              { setting: 'Pre-staged app cleanup', value: 'Disabled', desc: 'UWP app cleanup tasks' },
              { setting: 'UCPD velocity', value: 'Disabled', desc: 'App deployment velocity checks' },
              { setting: 'appuriverifierdaily', value: 'Disabled', desc: 'Daily app verification' },
              { setting: 'appuriverifierinstall', value: 'Disabled', desc: 'Install-time app verification' },
              { setting: 'CleanupTemporaryState', value: 'Disabled', desc: 'Temp state cleanup' },
              { setting: 'DsSvcCleanup', value: 'Disabled', desc: 'Data sharing service cleanup' }
            ]
          },
          {
            name: 'Windows AI & Recall (2)',
            items: [
              { setting: 'Recall InitialConfiguration', value: 'Disabled', desc: 'AI Recall initial setup' },
              { setting: 'Recall PolicyConfiguration', value: 'Disabled', desc: 'AI Recall policy checks' }
            ]
          },
          {
            name: 'Work & Enterprise (6)',
            items: [
              { setting: 'Work Folders Logon Sync', value: 'Disabled', desc: 'Enterprise folder sync at logon' },
              { setting: 'Work Folders Maintenance', value: 'Disabled', desc: 'Enterprise folder maintenance' },
              { setting: 'Workplace Join Device-Sync', value: 'Disabled', desc: 'Device sync for workplace' },
              { setting: 'Workplace Join Recovery', value: 'Disabled', desc: 'Workplace recovery checks' },
              { setting: 'Automatic-Device-Join', value: 'Disabled', desc: 'Auto device domain join' },
              { setting: 'AD RMS Rights Policy', value: 'Disabled', desc: 'Rights management policies' }
            ]
          },
          {
            name: 'Network & Wireless (5)',
            items: [
              { setting: 'WiFiTask', value: 'Disabled', desc: 'WiFi background tasks' },
              { setting: 'CDSSync', value: 'Disabled', desc: 'Connected devices sync' },
              { setting: 'MoProfileManagement', value: 'Disabled', desc: 'Mobile profile management' },
              { setting: 'WwanSvc NotificationTask', value: 'Disabled', desc: 'Mobile broadband notifications' },
              { setting: 'WwanSvc OobeDiscovery', value: 'Disabled', desc: 'Mobile network discovery' }
            ]
          },
          {
            name: 'System Maintenance (8)',
            items: [
              { setting: 'Autochk Proxy', value: 'Disabled', desc: 'Auto disk check proxy' },
              { setting: 'BgTaskRegistration', value: 'Disabled', desc: 'Background task registration' },
              { setting: 'capabilityaccessmanager', value: 'Disabled', desc: 'Capability access maintenance' },
              { setting: 'HiveUploadTask', value: 'Disabled', desc: 'User profile hive uploads' },
              { setting: 'WIM-Hash-Management', value: 'Disabled', desc: 'WIM hash management' },
              { setting: 'WIM-Hash-Validation', value: 'Disabled', desc: 'WIM hash validation' },
              { setting: 'BfeOnServiceStartTypeChange', value: 'Disabled', desc: 'Firewall service changes' },
              { setting: 'Calibration Loader', value: 'Disabled', desc: 'Color calibration loading' }
            ]
          },
          {
            name: 'Other Tasks (6)',
            items: [
              { setting: 'XblGameSaveTask', value: 'Disabled', desc: 'Xbox cloud save sync' },
              { setting: 'BitLocker Encrypt All', value: 'Disabled', desc: 'BitLocker encryption tasks' },
              { setting: 'BitLocker MDM Refresh', value: 'Disabled', desc: 'BitLocker policy refresh' },
              { setting: 'Bluetooth UninstallDevice', value: 'Disabled', desc: 'Bluetooth device cleanup' },
              { setting: 'EDP Policy Manager', value: 'Disabled', desc: 'Enterprise data protection' },
              { setting: 'QueueReporting', value: 'Disabled', desc: 'Error reporting queue' }
            ]
          }
        ]
      }
    },
    {
      id: 'cache',
      name: 'Cache Cleaning',
      description: 'Clean shader and graphics caches',
      script: '5-Optimization/5.4.1-clean-caches.bat',
      impact: 'Medium',
      requiresRestart: 'No',
      icon: Trash2,
      details: {
        summary: 'Shader and graphics caches can become corrupted or bloated over time, causing stutters and long loading times. Cleaning forces fresh shader compilation.',
        categories: [
          {
            name: 'NVIDIA Caches',
            items: [
              { setting: 'DXCache', value: 'Cleaned', desc: 'DirectX shader cache - corruption causes stutters' },
              { setting: 'GLCache', value: 'Cleaned', desc: 'OpenGL shader cache' },
              { setting: 'OptixCache', value: 'Cleaned', desc: 'Ray tracing cache' }
            ]
          },
          {
            name: 'System Caches',
            items: [
              { setting: 'Windows Temp', value: 'Cleaned', desc: 'Temporary files from all applications' },
              { setting: 'DCS Temp', value: 'Cleaned', desc: 'DCS temporary files and crash dumps' }
            ]
          }
        ],
        warning: '⚠️ First launch after cleaning: Longer initial loading (1-3 min), brief stutters as shaders recompile. This is normal.'
      }
    }
  ];

  const runOptimization = async () => {
    if (!isAdmin) {
      alert('Administrator privileges required for optimization');
      return;
    }

    if (!confirm('This will modify your system settings. Make sure you have created a backup. Continue?')) {
      return;
    }

    setExecuting(true);
    setOutput('Starting optimization process...\n\n');

    for (const category of optimizationCategories) {
      if (!selectedOptimizations[category.id]) continue;

      setOutput(prev => prev + `\n=== ${category.name} ===\n`);

      try {
        // Wait for script to complete using a promise
        await new Promise((resolve, reject) => {
          const outputHandler = (data) => {
            setOutput(prev => prev + stripAnsi(data.data));
          };

          const completeHandler = (data) => {
            // Remove listeners after completion
            window.dcsMax.onScriptOutput(() => {});
            window.dcsMax.onScriptComplete(() => {});
            
            if (data.code === 0) {
              setOutput(prev => prev + `\n[SUCCESS] ${category.name} completed successfully!\n`);
            } else {
              setOutput(prev => prev + `\n[FAIL] ${category.name} failed!\n${data.stderr}\n`);
            }
            resolve();
          };

          window.dcsMax.onScriptOutput(outputHandler);
          window.dcsMax.onScriptComplete(completeHandler);
          
          // Use /NoPause for batch files, -NoPause for PowerShell
          const noPauseArg = category.script.endsWith('.bat') ? '/NoPause' : '-NoPause';
          window.dcsMax.executeScriptStream(category.script, [noPauseArg]);
        });
        
        // Small delay between optimizations for UI update
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        setOutput(prev => prev + `\n[FAIL] Error: ${error.message}\n`);
      }
    }

    setExecuting(false);
    setOutput(prev => prev + '\n=== Optimization Complete ===\n');
  };

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Left Panel - Options */}
      <div className="w-1/2 border-r border-slate-700 overflow-y-auto">
        <div className="p-6">
          <h2 className="text-2xl font-bold text-white mb-6">System Optimization</h2>

          {/* Admin Check */}
          {!isAdmin && (
            <div className="bg-danger-500/20 border border-danger-500/50 rounded-lg p-4 mb-6">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="w-5 h-5 text-danger-500 flex-shrink-0 mt-0.5" />
                <div className="text-sm text-danger-200">
                  <strong>Administrator Required:</strong> Restart the application as administrator to use optimization features.
                </div>
              </div>
            </div>
          )}



          {/* Warning */}
          <div className="bg-warning-500/20 border border-warning-500/50 rounded-lg p-4 mb-4">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="w-5 h-5 text-warning-500 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-warning-200">
                <strong>Important:</strong> Create a system restore point and backup before applying optimizations.
              </div>
            </div>
          </div>

          {/* Create Restore Point Button */}
          <button
            onClick={createRestorePoint}
            disabled={creatingRestorePoint || executing || !isAdmin}
            className="w-full flex items-center justify-center space-x-3 px-4 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 disabled:from-slate-700 disabled:to-slate-700 disabled:cursor-not-allowed rounded-lg transition-all mb-6 shadow-lg"
          >
            <Shield className="w-5 h-5" />
            <span className="font-semibold">
              {creatingRestorePoint ? 'Creating Restore Point...' : 'Create Windows Restore Point'}
            </span>
          </button>

          {/* Optimization Categories */}
          <div className="space-y-3 mb-6">
            <h3 className="text-lg font-semibold text-white">Select Optimizations</h3>
            
            {optimizationCategories.map((cat) => {
              const IconComponent = cat.icon;
              const isExpanded = expandedCategory === cat.id;
              
              return (
                <div
                  key={cat.id}
                  className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden"
                >
                  {/* Main Category Row */}
                  <div className="p-4">
                    <div className="flex items-start space-x-3">
                      <input
                        type="checkbox"
                        checked={selectedOptimizations[cat.id]}
                        onChange={(e) => setSelectedOptimizations({
                          ...selectedOptimizations,
                          [cat.id]: e.target.checked
                        })}
                        disabled={!isAdmin || executing}
                        className="mt-1 w-5 h-5 text-blue-600 bg-slate-700 border-slate-600 rounded focus:ring-blue-500 cursor-pointer"
                      />
                      <div className="flex-1">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center space-x-2">
                            <IconComponent className="w-5 h-5 text-blue-400" />
                            <span className="font-semibold text-white">{cat.name}</span>
                          </div>
                          <button
                            onClick={() => setExpandedCategory(isExpanded ? null : cat.id)}
                            className="p-1 hover:bg-slate-700 rounded transition-colors"
                            title={isExpanded ? 'Hide details' : 'Show details'}
                          >
                            {isExpanded ? (
                              <ChevronUp className="w-5 h-5 text-slate-400" />
                            ) : (
                              <ChevronDown className="w-5 h-5 text-slate-400" />
                            )}
                          </button>
                        </div>
                        <div className="text-sm text-slate-400 mt-1">{cat.description}</div>
                        <div className="flex items-center space-x-3 text-xs mt-2">
                          <span className={`px-2 py-1 rounded ${
                            cat.impact === 'High' ? 'bg-green-500/20 text-green-400' :
                            cat.impact === 'Medium' ? 'bg-yellow-500/20 text-yellow-400' :
                            'bg-blue-500/20 text-blue-400'
                          }`}>
                            Impact: {cat.impact}
                          </span>
                          <span className="text-slate-500">
                            Restart: {cat.requiresRestart}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  {/* Expanded Details */}
                  {isExpanded && cat.details && (
                    <div className="border-t border-slate-700 bg-slate-850 p-4">
                      <p className="text-sm text-slate-300 mb-4">{cat.details.summary}</p>
                      
                      {cat.details.warning && (
                        <div className="bg-warning-500/20 border border-warning-500/50 rounded-lg p-3 mb-4">
                          <p className="text-sm text-warning-200">{cat.details.warning}</p>
                        </div>
                      )}
                      
                      <div className="space-y-4">
                        {cat.details.categories.map((subCat, idx) => (
                          <div key={idx}>
                            <h5 className="text-sm font-semibold text-blue-400 mb-2">{subCat.name}</h5>
                            <div className="space-y-2">
                              {subCat.items.map((item, itemIdx) => (
                                <div key={itemIdx} className="flex items-start text-xs bg-slate-800/50 rounded p-2">
                                  <div className="w-1/3 font-medium text-slate-200">{item.setting}</div>
                                  <div className="w-1/6 text-green-400">{item.value}</div>
                                  <div className="flex-1 text-slate-400">{item.desc}</div>
                                </div>
                              ))}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Action Button */}
          <button
            onClick={runOptimization}
            disabled={!isAdmin || executing || !Object.values(selectedOptimizations).some(v => v)}
            className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 disabled:cursor-not-allowed rounded-lg transition-colors font-semibold"
          >
            {executing ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                <span>Optimizing...</span>
              </>
            ) : (
              <>
                <Play className="w-5 h-5" />
                <span>Apply Optimizations</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Right Panel - Output */}
      <div className="flex-1 flex flex-col overflow-hidden bg-slate-950">
        <div className="p-4 border-b border-slate-700 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-white">Optimization Output</h3>
          {executing && (
            <div className="flex items-center space-x-2 text-blue-400">
              <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
              <span className="text-sm">Processing...</span>
            </div>
          )}
        </div>
        <div ref={outputRef} className="flex-1 overflow-y-auto p-4">
          <pre className="log-output text-slate-300">
            {output || 'Select optimizations and click "Apply Optimizations" to begin.'}
          </pre>
        </div>
      </div>
    </div>
  );
}

export default Optimization;
