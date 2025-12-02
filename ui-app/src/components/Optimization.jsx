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
  Trash2,
  Check,
  X
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
  const [showTip, setShowTip] = useState(() => {
    const globalSetting = localStorage.getItem('dcsmax-show-tips');
    if (globalSetting === 'false') return false;
    const localSetting = localStorage.getItem('dcsmax-tip-optimization');
    return localSetting === null ? true : localSetting === 'true';
  });
  
  // Individual optimization settings (loaded from config)
  const [optimizationSettings, setOptimizationSettings] = useState({});
  const [configLoaded, setConfigLoaded] = useState(false);
  const [configExists, setConfigExists] = useState(false);
  const [savingConfig, setSavingConfig] = useState(false);

  // Load optimization config on mount
  useEffect(() => {
    loadOptimizationConfig();
    
    // Listen for storage changes (when tips setting is changed in Settings)
    const handleStorage = (e) => {
      if (e.key === 'dcsmax-show-tips') {
        if (e.newValue === 'true') {
          const localSetting = localStorage.getItem('dcsmax-tip-optimization');
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

  const loadOptimizationConfig = async () => {
    try {
      const result = await window.dcsMax.readOptimizationConfig();
      if (result.success) {
        const config = result.config || {};
        setOptimizationSettings(config);
        setConfigExists(result.exists);
        
        // Load category states from config (default to true if not set)
        setSelectedOptimizations({
          registry: config['CAT_REGISTRY'] !== false,
          services: config['CAT_SERVICES'] !== false,
          tasks: config['CAT_TASKS'] !== false,
          cache: config['CAT_CACHE'] !== false
        });
        
        setConfigLoaded(true);
      }
    } catch (error) {
      console.error('Failed to load optimization config:', error);
      setConfigLoaded(true);
    }
  };

  const saveOptimizationConfig = async (newSettings) => {
    setSavingConfig(true);
    try {
      const result = await window.dcsMax.writeOptimizationConfig(newSettings);
      if (!result.success) {
        console.error('Failed to save config:', result.error);
      }
    } catch (error) {
      console.error('Failed to save optimization config:', error);
    }
    setSavingConfig(false);
  };

  // Helper to find category by item ID prefix
  const getCategoryIdByItemId = (itemId) => {
    if (itemId.startsWith('R')) return 'registry';
    if (itemId.startsWith('S')) return 'services';
    if (itemId.startsWith('T')) return 'tasks';
    if (itemId.startsWith('C')) return 'cache';
    return null;
  };

  // Check if any item in a category is enabled
  const hasAnyEnabledInCategory = (categoryId, settings) => {
    const category = optimizationCategories.find(c => c.id === categoryId);
    if (!category) return false;
    const items = getCategoryItemsWithIds(category);
    return items.some(item => settings[item.id] !== false);
  };

  const toggleOptimization = (id) => {
    const currentValue = optimizationSettings[id] !== false; // Default to true
    const newSettings = {
      ...optimizationSettings,
      [id]: !currentValue
    };
    
    // If enabling an item, also enable the parent category
    const categoryId = getCategoryIdByItemId(id);
    if (categoryId && !currentValue) {
      // Enabling this item - enable parent category too
      const catKey = `CAT_${categoryId.toUpperCase()}`;
      newSettings[catKey] = true;
      setSelectedOptimizations(prev => ({
        ...prev,
        [categoryId]: true
      }));
    } else if (categoryId && currentValue) {
      // Disabling this item - check if any others are still enabled
      if (!hasAnyEnabledInCategory(categoryId, newSettings)) {
        const catKey = `CAT_${categoryId.toUpperCase()}`;
        newSettings[catKey] = false;
        setSelectedOptimizations(prev => ({
          ...prev,
          [categoryId]: false
        }));
      }
    }
    
    setOptimizationSettings(newSettings);
    saveOptimizationConfig(newSettings);
  };

  const isOptimizationEnabled = (id) => {
    // If not in settings or settings is empty, default to true
    if (!optimizationSettings || Object.keys(optimizationSettings).length === 0) {
      return true;
    }
    return optimizationSettings[id] !== false;
  };

  const toggleAllInCategory = (categoryId, categoryItems, enable) => {
    const newSettings = { ...optimizationSettings };
    categoryItems.forEach(item => {
      if (item.id) {
        newSettings[item.id] = enable;
      }
    });
    
    // Also save parent category state
    const catKey = `CAT_${categoryId.toUpperCase()}`;
    newSettings[catKey] = enable;
    
    // Update parent category checkbox
    setSelectedOptimizations(prev => ({
      ...prev,
      [categoryId]: enable
    }));
    
    setOptimizationSettings(newSettings);
    saveOptimizationConfig(newSettings);
  };

  const getCategoryItemsWithIds = (category) => {
    const items = [];
    if (category.details && category.details.categories) {
      category.details.categories.forEach(subCat => {
        if (subCat.items) {
          subCat.items.forEach(item => {
            if (item.id) items.push(item);
          });
        }
      });
    }
    return items;
  };

  const getCategoryEnabledCount = (category) => {
    const items = getCategoryItemsWithIds(category);
    if (items.length === 0) return { enabled: 0, total: 0 };
    const enabled = items.filter(item => isOptimizationEnabled(item.id)).length;
    return { enabled, total: items.length };
  };

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
              { id: 'R001', setting: 'CPU Core Parking', value: 'Disabled', desc: 'Keeps all cores active and ready, reducing latency spikes' },
              { id: 'R002', setting: 'DCS CPU Priority', value: 'High (3)', desc: 'DCS.exe gets preferential CPU time over background processes' },
              { id: 'R003', setting: 'Power Throttling', value: 'Disabled', desc: 'Maintains consistent clock speeds during gameplay' },
              { id: 'R014', setting: 'Priority Separation', value: '26 (Long Fixed)', desc: 'More CPU time to foreground applications' }
            ]
          },
          {
            name: 'GPU & Rendering (2)',
            items: [
              { id: 'R005', setting: 'Max Pre-Rendered Frames', value: '1', desc: 'Reduces input lag (critical for VR)' },
              { id: 'R010', setting: 'GPU Priority', value: '14 (High)', desc: 'High GPU scheduling priority for games' }
            ]
          },
          {
            name: 'MMCSS Game Profile (6)',
            items: [
              { id: 'R008', setting: 'Game CPU Affinity', value: '0x0F (4 cores)', desc: 'Pins games to first 4 cores for cache efficiency' },
              { id: 'R009', setting: 'Background Only', value: 'Disabled', desc: 'Games run as foreground priority' },
              { id: 'R011', setting: 'CPU Priority', value: '6 (Highest)', desc: 'Maximum CPU scheduling priority' },
              { id: 'R012', setting: 'Scheduling Category', value: 'High', desc: 'High priority thread scheduling' },
              { id: 'R013', setting: 'SFIO Priority', value: 'High', desc: 'High priority I/O operations' }
            ]
          },
          {
            name: 'System Settings (3)',
            items: [
              { id: 'R004', setting: 'GameDVR Recording', value: 'Disabled', desc: 'Frees GPU encoder, reduces frame time spikes' },
              { id: 'R006', setting: 'Network Throttling', value: 'Disabled', desc: 'Network packets aren\'t delayed during gameplay' },
              { id: 'R007', setting: 'System Responsiveness', value: '10%', desc: '90% of CPU available for games' }
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
        summary: 'Disables 50+ non-essential Windows services that run continuously in the background. Frees up RAM, reduces CPU overhead, and eliminates sources of stutters.',
        categories: [
          {
            name: 'Telemetry & Diagnostics (4)',
            items: [
              { id: 'S001', setting: 'DiagTrack', value: 'Disabled', desc: 'Telemetry uses CPU and network constantly' },
              { id: 'S002', setting: 'DPS', value: 'Disabled', desc: 'Diagnostic scans are resource-intensive' },
              { id: 'S003', setting: 'WdiServiceHost', value: 'Disabled', desc: 'Background diagnostics cause micro-stutters' },
              { id: 'S004', setting: 'WdiSystemHost', value: 'Disabled', desc: 'Unnecessary CPU overhead' }
            ]
          },
          {
            name: 'Windows Update (3)',
            items: [
              { id: 'S005', setting: 'UsoSvc', value: 'Disabled', desc: 'Prevents background updates during gameplay' },
              { id: 'S006', setting: 'TrustedInstaller', value: 'Disabled', desc: 'Avoids update-triggered disk activity' },
              { id: 'S007', setting: 'WaaSMedicSvc', value: 'Disabled', desc: 'Redundant repair service' }
            ]
          },
          {
            name: 'Xbox & Gaming (5)',
            items: [
              { id: 'S035', setting: 'XblAuthManager', value: 'Disabled', desc: 'DCS doesn\'t use Xbox Live' },
              { id: 'S036', setting: 'XblGameSave', value: 'Disabled', desc: 'Cloud saves not used by DCS' },
              { id: 'S037', setting: 'XboxNetApiSvc', value: 'Disabled', desc: 'Reduces network overhead' },
              { id: 'S038', setting: 'XboxGipSvc', value: 'Disabled', desc: 'No Xbox accessories used' },
              { id: 'S019', setting: 'BcastDVRUserService', value: 'Disabled', desc: 'GameDVR causes frame drops in VR' }
            ]
          },
          {
            name: 'Cloud & Microsoft (4)',
            items: [
              { id: 'S008', setting: 'wlidsvc', value: 'Disabled', desc: 'MS Account: No cloud sync needed' },
              { id: 'S009', setting: 'WalletService', value: 'Disabled', desc: 'Irrelevant for gaming' },
              { id: 'S050', setting: 'ClipSVC', value: 'Disabled', desc: 'No Store apps, saves 50-100MB RAM' },
              { id: 'S011', setting: 'BackgroundApps', value: 'Disabled', desc: 'Globally disables background apps' }
            ]
          },
          {
            name: 'Search & Indexing (2)',
            items: [
              { id: 'S016', setting: 'WSearch', value: 'Disabled', desc: 'Heavy disk I/O competes with DCS loading' },
              { id: 'S017', setting: 'Indexing', value: 'Disabled', desc: 'Minimizes disk I/O on game drives' }
            ]
          },
          {
            name: 'Printer & Fax (4)',
            items: [
              { id: 'S012', setting: 'Spooler', value: 'Disabled', desc: 'No printing needed during gaming' },
              { id: 'S013', setting: 'PrintNotify', value: 'Disabled', desc: 'Unnecessary notifications' },
              { id: 'S014', setting: 'PrintWorkflowUserSvc', value: 'Disabled', desc: 'Workflow not needed' },
              { id: 'S015', setting: 'Fax', value: 'Disabled', desc: 'Obsolete service' }
            ]
          },
          {
            name: 'Network Discovery (3)',
            items: [
              { id: 'S028', setting: 'SSDPSRV', value: 'Disabled', desc: 'Cuts broadcast traffic' },
              { id: 'S029', setting: 'UPnPHost', value: 'Disabled', desc: 'No UPnP hosting needed' },
              { id: 'S030', setting: 'FDResPub', value: 'Disabled', desc: 'No device discovery needed' }
            ]
          },
          {
            name: 'Location & Sensors (4)',
            items: [
              { id: 'S031', setting: 'lfsvc', value: 'Disabled', desc: 'Geolocation not used' },
              { id: 'S032', setting: 'SensorService', value: 'Disabled', desc: 'No sensors in desktop' },
              { id: 'S033', setting: 'SensrSvc', value: 'Disabled', desc: 'No sensor monitoring needed' },
              { id: 'S034', setting: 'SensorDataService', value: 'Disabled', desc: 'No sensor data needed' }
            ]
          },
          {
            name: 'Hardware & Drivers (5)',
            items: [
              { id: 'S020', setting: 'RtkUWPService', value: 'Disabled', desc: 'Realtek: Conflicts with gaming audio' },
              { id: 'S021', setting: 'AmdPmuService', value: 'Disabled', desc: 'AMD: DCS uses own optimization' },
              { id: 'S022', setting: 'AmdAcpSvc', value: 'Disabled', desc: 'AMD: Compatibility DB not needed' },
              { id: 'S023', setting: 'AmdPPService', value: 'Disabled', desc: 'AMD: Manual power settings better' },
              { id: 'S051', setting: 'Power', value: 'Disabled', desc: 'Causes VR stutters from power state changes' }
            ]
          },
          {
            name: 'Remote & Backup (4)',
            items: [
              { id: 'S024', setting: 'RemoteRegistry', value: 'Disabled', desc: 'Security risk, not needed' },
              { id: 'S025', setting: 'TermService', value: 'Disabled', desc: 'RDP unneeded for local gaming' },
              { id: 'S026', setting: 'fhsvc', value: 'Disabled', desc: 'File History: Heavy disk I/O' },
              { id: 'S027', setting: 'WorkFolders', value: 'Disabled', desc: 'Enterprise sync not needed' }
            ]
          },
          {
            name: 'Other Services (12)',
            items: [
              { id: 'S010', setting: 'XboxGameBar', value: 'Disabled', desc: 'Xbox Game Bar overhead' },
              { id: 'S018', setting: 'MapsBroker', value: 'Disabled', desc: 'Maps irrelevant for gaming' },
              { id: 'S039', setting: 'WPCSvc', value: 'Disabled', desc: 'Parental controls not needed' },
              { id: 'S040', setting: 'PhoneSvc', value: 'Disabled', desc: 'No telephony on desktop' },
              { id: 'S041', setting: 'MessagingService', value: 'Disabled', desc: 'Not used in gaming' },
              { id: 'S042', setting: 'wisvc', value: 'Disabled', desc: 'Insider Program not needed' },
              { id: 'S043', setting: 'WebClient', value: 'Disabled', desc: 'WebDAV avoids reconnects' },
              { id: 'S044', setting: 'stisvc', value: 'Disabled', desc: 'No scanning needed' },
              { id: 'S045', setting: 'GoogleUpdaterService', value: 'Disabled', desc: 'Google updates not needed' },
              { id: 'S047', setting: 'AsusUpdateCheck', value: 'Disabled', desc: 'Manual updates sufficient' },
              { id: 'S048', setting: 'TrkWks', value: 'Disabled', desc: 'File Tracking not needed' },
              { id: 'S049', setting: 'RetailDemo', value: 'Disabled', desc: 'Consumer feature not needed' }
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
        summary: 'Disables 59 Windows scheduled tasks that run at various intervals, consuming CPU, disk, and network resources. These tasks can cause micro-stutters and frame drops during gameplay.',
        categories: [
          {
            name: 'Application Experience (6)',
            items: [
              { id: 'T014', setting: 'Microsoft Compatibility Appraiser', value: 'Disabled', desc: 'Heavy disk I/O scanning applications' },
              { id: 'T015', setting: 'Compatibility Appraiser Exp', value: 'Disabled', desc: 'Experimental telemetry scanning' },
              { id: 'T016', setting: 'StartupAppTask', value: 'Disabled', desc: 'Application startup analysis' },
              { id: 'T013', setting: 'MareBackup', value: 'Disabled', desc: 'Background backup task' },
              { id: 'T017', setting: 'PcaPatchDbTask', value: 'Disabled', desc: 'Compatibility database patching' },
              { id: 'T018', setting: 'SdbinstMergeDbTask', value: 'Disabled', desc: 'Database merge operations' }
            ]
          },
          {
            name: 'Windows Defender (4)',
            items: [
              { id: 'T043', setting: 'Defender Cache Maintenance', value: 'Disabled', desc: 'Cache operations cause disk I/O' },
              { id: 'T044', setting: 'Defender Cleanup', value: 'Disabled', desc: 'Cleanup operations during gameplay' },
              { id: 'T045', setting: 'Defender Scheduled Scan', value: 'Disabled', desc: 'Scans consume significant resources' },
              { id: 'T046', setting: 'Defender Verification', value: 'Disabled', desc: 'Definition verification overhead' }
            ]
          },
          {
            name: '.NET Framework (4)',
            items: [
              { id: 'T006', setting: 'NGEN v4.0.30319', value: 'Disabled', desc: 'Native image generation - heavy CPU' },
              { id: 'T007', setting: 'NGEN v4.0.30319 64', value: 'Disabled', desc: '64-bit native image generation' },
              { id: 'T004', setting: 'NGEN Critical', value: 'Disabled', desc: 'Critical priority can interrupt gameplay' },
              { id: 'T005', setting: 'NGEN 64 Critical', value: 'Disabled', desc: '64-bit critical priority tasks' }
            ]
          },
          {
            name: 'Browser Updates (3)',
            items: [
              { id: 'T001', setting: 'Edge Update Core', value: 'Disabled', desc: 'Edge browser update service' },
              { id: 'T002', setting: 'Edge Update UA', value: 'Disabled', desc: 'Edge user agent updates' },
              { id: 'T003', setting: 'Google Updater', value: 'Disabled', desc: 'Chrome update background activity' }
            ]
          },
          {
            name: 'Windows Update (4)',
            items: [
              { id: 'T036', setting: 'Scheduled Start', value: 'Disabled', desc: 'Prevents scheduled update starts' },
              { id: 'T035', setting: 'Refresh Group Policy Cache', value: 'Disabled', desc: 'Policy refresh overhead' },
              { id: 'T034', setting: 'WaaSMedic PerformRemediation', value: 'Disabled', desc: 'Update remediation service' },
              { id: 'T037', setting: 'PauseWindowsUpdate', value: 'Disabled', desc: 'Update pause management' }
            ]
          },
          {
            name: 'App & Data Management (8)',
            items: [
              { id: 'T023', setting: 'AppListBackup', value: 'Disabled', desc: 'App list backup operations' },
              { id: 'T024', setting: 'BackupNonMaintenance', value: 'Disabled', desc: 'Non-maintenance backups' },
              { id: 'T025', setting: 'Pre-staged app cleanup', value: 'Disabled', desc: 'UWP app cleanup tasks' },
              { id: 'T026', setting: 'UCPD velocity', value: 'Disabled', desc: 'App deployment velocity checks' },
              { id: 'T019', setting: 'appuriverifierdaily', value: 'Disabled', desc: 'Daily app verification' },
              { id: 'T020', setting: 'appuriverifierinstall', value: 'Disabled', desc: 'Install-time app verification' },
              { id: 'T021', setting: 'CleanupTemporaryState', value: 'Disabled', desc: 'Temp state cleanup' },
              { id: 'T022', setting: 'DsSvcCleanup', value: 'Disabled', desc: 'Data sharing service cleanup' }
            ]
          },
          {
            name: 'Windows AI & Recall (2)',
            items: [
              { id: 'T049', setting: 'Recall InitialConfiguration', value: 'Disabled', desc: 'AI Recall initial setup' },
              { id: 'T050', setting: 'Recall PolicyConfiguration', value: 'Disabled', desc: 'AI Recall policy checks' }
            ]
          },
          {
            name: 'Work & Enterprise (8)',
            items: [
              { id: 'T053', setting: 'Work Folders Logon Sync', value: 'Disabled', desc: 'Enterprise folder sync at logon' },
              { id: 'T054', setting: 'Work Folders Maintenance', value: 'Disabled', desc: 'Enterprise folder maintenance' },
              { id: 'T056', setting: 'Workplace Join Device-Sync', value: 'Disabled', desc: 'Device sync for workplace' },
              { id: 'T057', setting: 'Workplace Join Recovery', value: 'Disabled', desc: 'Workplace recovery checks' },
              { id: 'T055', setting: 'Automatic-Device-Join', value: 'Disabled', desc: 'Auto device domain join' },
              { id: 'T009', setting: 'AD RMS Rights Policy Auto', value: 'Disabled', desc: 'Rights management auto' },
              { id: 'T010', setting: 'AD RMS Rights Policy Manual', value: 'Disabled', desc: 'Rights management manual' },
              { id: 'T008', setting: 'RecoverabilityToastTask', value: 'Disabled', desc: 'Account recovery toast' }
            ]
          },
          {
            name: 'Network & Wireless (5)',
            items: [
              { id: 'T038', setting: 'WiFiTask', value: 'Disabled', desc: 'WiFi background tasks' },
              { id: 'T039', setting: 'CDSSync', value: 'Disabled', desc: 'Connected devices sync' },
              { id: 'T040', setting: 'MoProfileManagement', value: 'Disabled', desc: 'Mobile profile management' },
              { id: 'T041', setting: 'WwanSvc NotificationTask', value: 'Disabled', desc: 'Mobile broadband notifications' },
              { id: 'T042', setting: 'WwanSvc OobeDiscovery', value: 'Disabled', desc: 'Mobile network discovery' }
            ]
          },
          {
            name: 'System Maintenance (11)',
            items: [
              { id: 'T027', setting: 'Autochk Proxy', value: 'Disabled', desc: 'Auto disk check proxy' },
              { id: 'T031', setting: 'BgTaskRegistration', value: 'Disabled', desc: 'Background task registration' },
              { id: 'T032', setting: 'capabilityaccessmanager', value: 'Disabled', desc: 'Capability access maintenance' },
              { id: 'T033', setting: 'HiveUploadTask', value: 'Disabled', desc: 'User profile hive uploads' },
              { id: 'T051', setting: 'WIM-Hash-Management', value: 'Disabled', desc: 'WIM hash management' },
              { id: 'T052', setting: 'WIM-Hash-Validation', value: 'Disabled', desc: 'WIM hash validation' },
              { id: 'T048', setting: 'BfeOnServiceStartTypeChange', value: 'Disabled', desc: 'Firewall service changes' },
              { id: 'T059', setting: 'Calibration Loader', value: 'Disabled', desc: 'Color calibration loading' },
              { id: 'T028', setting: 'BitLocker Encrypt All', value: 'Disabled', desc: 'BitLocker encryption tasks' },
              { id: 'T029', setting: 'BitLocker MDM Refresh', value: 'Disabled', desc: 'BitLocker policy refresh' },
              { id: 'T030', setting: 'Bluetooth UninstallDevice', value: 'Disabled', desc: 'Bluetooth device cleanup' }
            ]
          },
          {
            name: 'Other Tasks (4)',
            items: [
              { id: 'T058', setting: 'XblGameSaveTask', value: 'Disabled', desc: 'Xbox cloud save sync' },
              { id: 'T011', setting: 'EDP Policy Manager', value: 'Disabled', desc: 'Enterprise data protection' },
              { id: 'T012', setting: 'PolicyConverter', value: 'Disabled', desc: 'App ID policy conversion' },
              { id: 'T047', setting: 'QueueReporting', value: 'Disabled', desc: 'Error reporting queue' }
            ]
          }
        ]
      }
    },
    {
      id: 'cache',
      name: 'Cache Cleaning',
      description: 'Clean shader and graphics caches',
      script: '5-Optimization/5.4.1-clean-caches.ps1',
      impact: 'Medium',
      requiresRestart: 'No',
      icon: Trash2,
      details: {
        summary: 'Shader and graphics caches can become corrupted or bloated over time, causing stutters and long loading times. Cleaning forces fresh shader compilation.',
        categories: [
          {
            name: 'NVIDIA Caches',
            items: [
              { id: 'C001', setting: 'DXCache', value: 'Cleaned', desc: 'DirectX shader cache - corruption causes stutters' },
              { id: 'C002', setting: 'GLCache', value: 'Cleaned', desc: 'OpenGL shader cache' },
              { id: 'C003', setting: 'OptixCache', value: 'Cleaned', desc: 'Ray tracing cache' }
            ]
          },
          {
            name: 'System Caches',
            items: [
              { id: 'C004', setting: 'Windows Temp', value: 'Cleaned', desc: 'Temporary files from all applications' },
              { id: 'C005', setting: 'DCS Temp', value: 'Cleaned', desc: 'DCS temporary files and crash dumps' }
            ]
          },
          {
            name: 'DCS Shader Caches',
            items: [
              { id: 'C006', setting: 'DCS fxo', value: 'Cleaned', desc: 'Compiled shader effects - rebuild fixes graphical glitches' },
              { id: 'C007', setting: 'DCS metashaders2', value: 'Cleaned', desc: 'Metashader cache - rebuild after driver updates' }
            ]
          }
        ],
        warning: '⚠️ First launch after cleaning: Longer initial loading (1-3 min), brief stutters as shaders recompile. This is normal.'
      }
    }
  ];

  // Sync parent category checkboxes based on sub-item states (only on initial load)
  useEffect(() => {
    if (!configLoaded) return;
    
    // Only sync on initial load - check if CAT_ values are already in config
    const hasCatValues = Object.keys(optimizationSettings).some(k => k.startsWith('CAT_'));
    if (hasCatValues) {
      // CAT_ values exist, use them directly (already loaded in loadOptimizationConfig)
      return;
    }
    
    // No CAT_ values in config - calculate initial state from sub-items
    const newSelectedOptimizations = {};
    optimizationCategories.forEach(cat => {
      const items = getCategoryItemsWithIds(cat);
      if (items.length === 0) {
        newSelectedOptimizations[cat.id] = selectedOptimizations[cat.id];
      } else {
        const hasAnyEnabled = items.some(item => optimizationSettings[item.id] !== false);
        newSelectedOptimizations[cat.id] = hasAnyEnabled;
      }
    });
    
    setSelectedOptimizations(prev => ({
      ...prev,
      ...newSelectedOptimizations
    }));
  }, [configLoaded]); // Only run when config is first loaded

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
          {showTip && (
            <div className="bg-warning-500/20 border border-warning-500/50 rounded-lg p-4 mb-4">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="w-5 h-5 text-warning-500 flex-shrink-0 mt-0.5" />
                <div className="flex-1 text-sm text-warning-200">
                  <strong>Important:</strong> Create a system restore point and backup before applying optimizations.
                </div>
                <button
                  onClick={() => {
                    setShowTip(false);
                    localStorage.setItem('dcsmax-tip-optimization', 'false');
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
                        onChange={(e) => {
                          const newValue = e.target.checked;
                          setSelectedOptimizations({
                            ...selectedOptimizations,
                            [cat.id]: newValue
                          });
                          // Save category state to config
                          const catKey = `CAT_${cat.id.toUpperCase()}`;
                          const newSettings = {
                            ...optimizationSettings,
                            [catKey]: newValue
                          };
                          setOptimizationSettings(newSettings);
                          saveOptimizationConfig(newSettings);
                        }}
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

                      {/* Select All / Deselect All buttons */}
                      {(() => {
                        const categoryItems = getCategoryItemsWithIds(cat);
                        const { enabled, total } = getCategoryEnabledCount(cat);
                        if (total === 0) return null;
                        return (
                          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-700">
                            <div className="text-xs text-slate-400">
                              {enabled} of {total} optimizations enabled
                              {savingConfig && <span className="ml-2 text-blue-400">(saving...)</span>}
                            </div>
                            <div className="flex space-x-2">
                              <button
                                onClick={() => toggleAllInCategory(cat.id, categoryItems, true)}
                                disabled={!isAdmin || executing}
                                className="px-2 py-1 text-xs bg-green-600/20 hover:bg-green-600/30 text-green-400 rounded transition-colors disabled:opacity-50"
                              >
                                <Check className="w-3 h-3 inline mr-1" />
                                Enable All
                              </button>
                              <button
                                onClick={() => toggleAllInCategory(cat.id, categoryItems, false)}
                                disabled={!isAdmin || executing}
                                className="px-2 py-1 text-xs bg-red-600/20 hover:bg-red-600/30 text-red-400 rounded transition-colors disabled:opacity-50"
                              >
                                <X className="w-3 h-3 inline mr-1" />
                                Disable All
                              </button>
                            </div>
                          </div>
                        );
                      })()}
                      
                      <div className="space-y-4">
                        {cat.details.categories.map((subCat, idx) => (
                          <div key={idx}>
                            <h5 className="text-sm font-semibold text-blue-400 mb-2">{subCat.name}</h5>
                            <div className="space-y-1">
                              {subCat.items.map((item, itemIdx) => (
                                <div 
                                  key={itemIdx} 
                                  className={`flex items-center text-xs rounded p-2 transition-colors ${
                                    item.id && isOptimizationEnabled(item.id) 
                                      ? 'bg-slate-800/50' 
                                      : 'bg-slate-900/50 opacity-60'
                                  }`}
                                >
                                  {item.id && (
                                    <input
                                      type="checkbox"
                                      checked={isOptimizationEnabled(item.id)}
                                      onChange={() => toggleOptimization(item.id)}
                                      disabled={!isAdmin || executing}
                                      className="mr-3 w-4 h-4 text-blue-600 bg-slate-700 border-slate-600 rounded focus:ring-blue-500 cursor-pointer"
                                    />
                                  )}
                                  <div className={`${item.id ? 'w-1/4' : 'w-1/3'} font-medium text-slate-200`}>
                                    {item.setting}
                                    {item.id && (
                                      <span className="ml-1 text-slate-500 font-normal">({item.id})</span>
                                    )}
                                  </div>
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
