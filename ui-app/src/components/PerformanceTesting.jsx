import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  Search,
  ChevronDown,
  ChevronRight,
  Settings,
  Zap,
  Monitor,
  Sun,
  Box,
  Sparkles,
  Trees,
  Tv,
  Glasses,
  Maximize,
  Check,
  Trash2,
  Play,
  StopCircle,
  RefreshCw,
  Activity,
  Lightbulb,
  X,
  Clock,
  AlertTriangle,
  CheckCircle,
  FileText,
  Eye,
  Info
} from 'lucide-react';

// Icon mapping for categories
const categoryIcons = {
  rendering: Monitor,
  textures: Box,
  lighting: Sun,
  geometry: Box,
  effects: Sparkles,
  environment: Trees,
  display: Tv,
  vr: Eye,
  upscaling: Maximize
};

// Performance impact colors
const impactColors = {
  HIGH: 'bg-red-500/20 text-red-400 border-red-500/30',
  MEDIUM: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  LOW: 'bg-green-500/20 text-green-400 border-green-500/30',
  NONE: 'bg-slate-500/20 text-slate-400 border-slate-500/30'
};

// Format seconds as MM:SS
const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

// Calibration Wizard Component
function CalibrationWizard({ 
  step, setStep, 
  timing, setTiming, 
  timer, setTimer, 
  startTime, setStartTime,
  vrEnabled,
  config,
  onClose, onApply 
}) {
  const [intervalId, setIntervalId] = useState(null);
  const [isRunning, setIsRunning] = useState(false);
  const [actionStatus, setActionStatus] = useState(null); // { success, message }

  const startTimer = () => {
    setIsRunning(true);
    setStartTime(Date.now());
    setTimer(0);
    setActionStatus(null);
    const id = setInterval(() => {
      setTimer(prev => prev + 1);
    }, 1000);
    setIntervalId(id);
  };

  const stopTimer = (timingKey) => {
    if (intervalId) {
      clearInterval(intervalId);
      setIntervalId(null);
    }
    setIsRunning(false);
    const elapsed = timer;
    setTiming(prev => ({ ...prev, [timingKey]: elapsed }));
    return elapsed;
  };

  const handleReady = (timingKey) => {
    stopTimer(timingKey);
    // Move to next step
    if (timingKey === 'vr') {
      setStep(2);
    } else if (timingKey === 'coldStart') {
      setStep(3);
    } else {
      setStep(4); // Results
    }
  };

  const skipVR = () => {
    setStep(2);
  };

  // Get paths from config
  const getPath = (key) => {
    return config?.configuration?.paths?.[key] || '';
  };

  const getVRHardware = () => {
    return config?.configuration?.vr?.hardware || 'Pimax';
  };

  const getMissionPath = () => {
    // Build full mission path from mission name
    const missionName = config?.configuration?.mission || '';
    if (!missionName) return '';
    // Missions are in 4-Performance-Testing/benchmark-missions folder
    return `4-Performance-Testing/benchmark-missions/${missionName}`;
  };

  const handleStartVR = async () => {
    setStep(1);
    startTimer();
    
    try {
      const hardware = getVRHardware();
      const exePath = getPath('pimax');
      
      const result = await window.dcsMax.launchVRSoftware(hardware, exePath);
      
      if (result.success) {
        if (result.alreadyRunning) {
          setActionStatus({ success: true, message: `${hardware} already running` });
        } else {
          setActionStatus({ success: true, message: `${hardware} launched` });
        }
      } else {
        setActionStatus({ success: false, message: result.error });
      }
    } catch (err) {
      setActionStatus({ success: false, message: err.message || 'Failed to launch VR' });
    }
  };

  const handleStartDCS = async () => {
    setStep(2);
    startTimer();
    
    try {
      const dcsPath = getPath('dcsExe');
      const missionPath = getMissionPath();
      
      // Get project root to build full mission path
      const projectRoot = await window.dcsMax.getProjectRoot();
      const fullMissionPath = projectRoot.path ? `${projectRoot.path}/${missionPath}` : missionPath;
      
      const result = await window.dcsMax.launchDCSWithMission(dcsPath, fullMissionPath);
      
      if (result.success) {
        if (result.alreadyRunning) {
          setActionStatus({ success: true, message: 'DCS already running' });
        } else {
          setActionStatus({ success: true, message: 'DCS launched with mission' });
        }
      } else {
        setActionStatus({ success: false, message: result.error });
      }
    } catch (err) {
      setActionStatus({ success: false, message: err.message || 'Failed to launch DCS' });
    }
  };

  const handleMissionRestart = async () => {
    setStep(3);
    startTimer();
    
    try {
      const result = await window.dcsMax.sendMissionRestart();
      
      if (result.success) {
        setActionStatus({ success: true, message: 'Shift+R sent to DCS' });
      } else {
        setActionStatus({ success: false, message: result.error });
      }
    } catch (err) {
      setActionStatus({ success: false, message: err.message || 'Failed to send restart command' });
    }
  };

  // Cleanup interval on unmount
  useEffect(() => {
    return () => {
      if (intervalId) clearInterval(intervalId);
    };
  }, [intervalId]);

  const steps = [
    { id: 'intro', title: 'Introduction' },
    { id: 'vr', title: 'VR Init', skip: !vrEnabled },
    { id: 'coldStart', title: 'Cold Start' },
    { id: 'missionRestart', title: 'Mission Restart' },
    { id: 'results', title: 'Results' }
  ];

  const activeSteps = steps.filter(s => !s.skip);

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50">
      <div className="bg-slate-800 rounded-xl border border-slate-700 shadow-2xl w-full max-w-lg mx-4">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-700 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white flex items-center space-x-2">
            <Settings className="w-5 h-5 text-blue-400" />
            <span>Timing Calibration</span>
          </h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-700 rounded transition-colors">
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        {/* Progress indicator */}
        <div className="px-6 py-3 border-b border-slate-700/50">
          <div className="flex items-center justify-between">
            {activeSteps.map((s, i) => (
              <React.Fragment key={s.id}>
                <div className={`flex items-center space-x-2 ${
                  step === (vrEnabled ? steps.indexOf(s) : i === 0 ? 0 : steps.indexOf(s)) 
                    ? 'text-blue-400' 
                    : step > steps.indexOf(s) ? 'text-green-400' : 'text-slate-500'
                }`}>
                  <span className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-medium ${
                    step > steps.indexOf(s) 
                      ? 'bg-green-500/20' 
                      : step === steps.indexOf(s) ? 'bg-blue-500/20' : 'bg-slate-700'
                  }`}>
                    {step > steps.indexOf(s) ? <Check className="w-3.5 h-3.5" /> : i + 1}
                  </span>
                  <span className="text-xs hidden sm:inline">{s.title}</span>
                </div>
                {i < activeSteps.length - 1 && (
                  <div className={`flex-1 h-0.5 mx-2 ${
                    step > steps.indexOf(s) ? 'bg-green-500/50' : 'bg-slate-700'
                  }`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          {/* Step 0: Introduction */}
          {step === 0 && (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto bg-blue-500/20 rounded-full flex items-center justify-center">
                <Clock className="w-8 h-8 text-blue-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Calibrate Your Timings</h3>
              <p className="text-slate-400 text-sm">
                This wizard helps you measure exactly how long your system takes to complete each phase of the benchmark. 
                We'll guide you through {vrEnabled ? '3' : '2'} simple timing steps.
              </p>
              <div className="text-left bg-slate-700/50 rounded-lg p-4 space-y-2 text-sm">
                {vrEnabled && (
                  <div className="flex items-start space-x-2">
                    <span className="text-blue-400">1.</span>
                    <span className="text-slate-300">VR Init - Time to initialize your VR headset</span>
                  </div>
                )}
                <div className="flex items-start space-x-2">
                  <span className="text-blue-400">{vrEnabled ? '2' : '1'}.</span>
                  <span className="text-slate-300">Cold Start - Time to launch DCS and load mission</span>
                </div>
                <div className="flex items-start space-x-2">
                  <span className="text-blue-400">{vrEnabled ? '3' : '2'}.</span>
                  <span className="text-slate-300">Mission Restart - Time to restart mission (Shift+R)</span>
                </div>
              </div>
              <button
                onClick={() => setStep(vrEnabled ? 1 : 2)}
                className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 rounded-lg text-white font-medium transition-colors"
              >
                Start Calibration
              </button>
            </div>
          )}

          {/* Step 1: VR Init (only if VR enabled) */}
          {step === 1 && vrEnabled && (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto bg-purple-500/20 rounded-full flex items-center justify-center">
                <Glasses className="w-8 h-8 text-purple-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Step 1: VR Initialization</h3>
              <p className="text-slate-400 text-sm">
                Starts your VR software. Click <strong>Ready</strong> when headset is on and tracking.
              </p>
              
              {!isRunning ? (
                <button
                  onClick={handleStartVR}
                  className="px-6 py-2.5 bg-purple-600 hover:bg-purple-700 rounded-lg text-white font-medium transition-colors"
                >
                  Start VR Software
                </button>
              ) : (
                <div className="space-y-4">
                  <div className="text-4xl font-mono text-purple-400">{formatTime(timer)}</div>
                  {actionStatus && (
                    <p className={`text-sm ${actionStatus.success ? 'text-green-400' : 'text-red-400'}`}>
                      {actionStatus.message}
                    </p>
                  )}
                  <p className="text-sm text-slate-300">Timing... click Ready when VR is fully initialized</p>
                  <button
                    onClick={() => handleReady('vr')}
                    className="px-6 py-2.5 bg-green-600 hover:bg-green-700 rounded-lg text-white font-medium transition-colors"
                  >
                    <Check className="w-4 h-4 inline mr-2" />
                    Ready
                  </button>
                </div>
              )}
              
              <button onClick={skipVR} className="text-xs text-slate-500 hover:text-slate-400">
                Skip this step
              </button>
            </div>
          )}

          {/* Step 2: Cold Start */}
          {step === 2 && (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto bg-orange-500/20 rounded-full flex items-center justify-center">
                <Play className="w-8 h-8 text-orange-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Step {vrEnabled ? '2' : '1'}: Cold Start</h3>
              <p className="text-slate-400 text-sm">
                Launches DCS and loads your benchmark mission from scratch. 
                Click <strong>Ready</strong> when cockpit is fully loaded.
              </p>
              
              {!isRunning ? (
                <button
                  onClick={handleStartDCS}
                  className="px-6 py-2.5 bg-orange-600 hover:bg-orange-700 rounded-lg text-white font-medium transition-colors"
                >
                  Launch DCS
                </button>
              ) : (
                <div className="space-y-4">
                  <div className="text-4xl font-mono text-orange-400">{formatTime(timer)}</div>
                  {actionStatus && (
                    <p className={`text-sm ${actionStatus.success ? 'text-green-400' : 'text-red-400'}`}>
                      {actionStatus.message}
                    </p>
                  )}
                  <p className="text-sm text-slate-300">Timing... click Ready when the cockpit is fully loaded</p>
                  <button
                    onClick={() => handleReady('coldStart')}
                    className="px-6 py-2.5 bg-green-600 hover:bg-green-700 rounded-lg text-white font-medium transition-colors"
                  >
                    <Check className="w-4 h-4 inline mr-2" />
                    Ready
                  </button>
                </div>
              )}
              
              <button onClick={() => setStep(3)} className="text-xs text-slate-500 hover:text-slate-400">
                Skip this step
              </button>
            </div>
          )}

          {/* Step 3: Mission Restart */}
          {step === 3 && (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto bg-cyan-500/20 rounded-full flex items-center justify-center">
                <RefreshCw className="w-8 h-8 text-cyan-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Step {vrEnabled ? '3' : '2'}: Mission Restart</h3>
              <p className="text-slate-400 text-sm">
                Restarts the mission while DCS is running (Shift+R). 
                Click <strong>Ready</strong> when cockpit is fully loaded again.
              </p>
              
              {!isRunning ? (
                <button
                  onClick={handleMissionRestart}
                  className="px-6 py-2.5 bg-cyan-600 hover:bg-cyan-700 rounded-lg text-white font-medium transition-colors"
                >
                  Restart Mission (Shift+R)
                </button>
              ) : (
                <div className="space-y-4">
                  <div className="text-4xl font-mono text-cyan-400">{formatTime(timer)}</div>
                  {actionStatus && (
                    <p className={`text-sm ${actionStatus.success ? 'text-green-400' : 'text-red-400'}`}>
                      {actionStatus.message}
                    </p>
                  )}
                  <p className="text-sm text-slate-300">Timing... click Ready when mission has reloaded</p>
                  <button
                    onClick={() => handleReady('missionRestart')}
                    className="px-6 py-2.5 bg-green-600 hover:bg-green-700 rounded-lg text-white font-medium transition-colors"
                  >
                    <Check className="w-4 h-4 inline mr-2" />
                    Ready
                  </button>
                </div>
              )}
              
              <button onClick={() => setStep(4)} className="text-xs text-slate-500 hover:text-slate-400">
                Skip this step
              </button>
            </div>
          )}

          {/* Step 4: Results */}
          {step === 4 && (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto bg-green-500/20 rounded-full flex items-center justify-center">
                <CheckCircle className="w-8 h-8 text-green-400" />
              </div>
              <h3 className="text-xl font-semibold text-white">Calibration Complete!</h3>
              <p className="text-slate-400 text-sm">
                Here are your measured timings. A 5-second buffer will be added for safety. You can adjust the timings if needed.
              </p>
              
              <div className="bg-slate-700/50 rounded-lg p-4 space-y-3 text-left">
                {vrEnabled && timing.vr !== null && (
                  <div className="flex items-center justify-between">
                    <span className="text-slate-300">VR Init</span>
                    <span className="font-mono text-purple-400">{timing.vr}s → {timing.vr + 5}s</span>
                  </div>
                )}
                {timing.coldStart !== null && (
                  <div className="flex items-center justify-between">
                    <span className="text-slate-300">Mission Load (Cold Start)</span>
                    <span className="font-mono text-orange-400">{timing.coldStart}s → {timing.coldStart + 5}s</span>
                  </div>
                )}
                {timing.missionRestart !== null && (
                  <div className="flex items-center justify-between">
                    <span className="text-slate-300">Mission Restart</span>
                    <span className="font-mono text-cyan-400">{timing.missionRestart}s → {timing.missionRestart + 5}s</span>
                  </div>
                )}
              </div>
              
              <div className="flex space-x-3 justify-center">
                <button
                  onClick={onClose}
                  className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-slate-300 font-medium transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={onApply}
                  className="px-6 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-white font-medium transition-colors"
                >
                  Apply Timings
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function PerformanceTesting() {
  const [activeTab, setActiveTab] = useState('run');
  const [config, setConfig] = useState(null);
  const [schema, setSchema] = useState(null);
  const [configError, setConfigError] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedCategories, setExpandedCategories] = useState({});
  const [impactFilter, setImpactFilter] = useState('all');
  const [restartFilter, setRestartFilter] = useState('all');
  const [hasChanges, setHasChanges] = useState(false);
  const [saving, setSaving] = useState(false);
  const [configLoaded, setConfigLoaded] = useState(false);  // Track if initial load is done
  
  // Run Tests state
  const [running, setRunning] = useState(false);
  const [projectRoot, setProjectRoot] = useState('');
  const [closeAppsAfterTests, setCloseAppsAfterTests] = useState(false);
  const [availableMissions, setAvailableMissions] = useState([]);
  const [selectedMission, setSelectedMission] = useState('');
  const [progress, setProgress] = useState(null);
  const [logOutput, setLogOutput] = useState([]);
  const logOutputRef = useRef(null);
  
  // Calibration wizard state
  const [calibrationOpen, setCalibrationOpen] = useState(false);
  const [calibrationStep, setCalibrationStep] = useState(0); // 0=intro, 1=VR, 2=ColdStart, 3=MissionRestart
  const [calibrationTiming, setCalibrationTiming] = useState({ vr: null, coldStart: null, missionRestart: null });
  const [calibrationTimer, setCalibrationTimer] = useState(null);
  const [calibrationStartTime, setCalibrationStartTime] = useState(null);
  
  const [showTip, setShowTip] = useState(() => {
    const globalSetting = localStorage.getItem('dcsmax-show-tips');
    if (globalSetting === 'false') return false;
    const localSetting = localStorage.getItem('dcsmax-tip-performance');
    return localSetting === null ? true : localSetting === 'true';
  });

  // Convert legacy INI format (defined before loadConfig which uses it)
  const convertIniToJsonFormat = (iniParsed) => {
    const jsonConfig = {
      configuration: {
        dryRun: iniParsed?.Configuration?.DryRun === 'true',
        vr: {
          enabled: iniParsed?.Configuration?.EnableVR === 'true',
          hardware: iniParsed?.Configuration?.VRhardware || 'Pimax'
        },
        waitTimes: {
          vr: parseInt(iniParsed?.Configuration?.WaitVR) || 15000,
          missionReady: parseInt(iniParsed?.Configuration?.WaitMissionReady) || 30000,
          beforeRecord: parseInt(iniParsed?.Configuration?.WaitBeforeRecord) || 3000,
          recordLength: parseInt(iniParsed?.Configuration?.WaitRecordLength) || 60000,
          capFrameXWrite: parseInt(iniParsed?.Configuration?.WaitCapFrameXWrite) || 5000,
          missionRestart: parseInt(iniParsed?.Configuration?.WaitMissionRestart) || 15000
        },
        mission: iniParsed?.Configuration?.mission || '',
        numberOfRuns: parseInt(iniParsed?.Configuration?.NumberOfRuns) || 1
      },
      testsToRun: []
    };

    if (iniParsed?.DCSOptionsTests) {
      Object.entries(iniParsed.DCSOptionsTests).forEach(([key, value]) => {
        if (key.startsWith('#')) return;
        const [values] = value.split('|');
        const valueList = values.split(',').map(v => v.trim());
        jsonConfig.testsToRun.push({
          setting: key,
          values: valueList,
          enabled: true
        });
      });
    }

    return jsonConfig;
  };

  // Load configuration
  const loadConfig = useCallback(async () => {
    try {
      setConfigError(null);
      setConfigLoaded(false);
      setHasChanges(false);
      const result = await window.dcsMax.readJsonConfig('4-Performance-Testing/testing-configuration.json');
      if (result.success) {
        setConfig(result.data);
        setConfigLoaded(true);
      } else {
        setConfigError(result.error || 'Failed to load config');
        setConfigLoaded(true);  // Set true so error UI shows
      }
      
      const schemaResult = await window.dcsMax.readJsonConfig('lib/dcs-settings-schema.json');
      if (schemaResult.success) {
        setSchema(schemaResult.data);
      }
    } catch (err) {
      console.error('Error loading config:', err);
      setConfigError(err.message || 'Unknown error');
      setConfigLoaded(true);  // Set true so error UI shows
    }
  }, []);

  useEffect(() => {
    loadConfig();
    
    window.dcsMax.getProjectRoot().then(result => {
      if (result.success) {
        setProjectRoot(result.path);
      }
    });

    window.dcsMax.listDirectory('4-Performance-Testing/benchmark-missions').then(result => {
      if (result.success && result.files) {
        const missions = result.files.filter(f => f.endsWith('.miz')).sort();
        setAvailableMissions(missions);
      }
    }).catch(err => {
      console.error('Error loading missions:', err);
    });

    const handleStorage = (e) => {
      if (e.key === 'dcsmax-show-tips') {
        if (e.newValue === 'true') {
          const localSetting = localStorage.getItem('dcsmax-tip-performance');
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
  }, [loadConfig]);

  // Group settings by category
  const settingsByCategory = useMemo(() => {
    if (!schema?.settings) return {};
    
    const grouped = {};
    Object.entries(schema.settings).forEach(([key, setting]) => {
      const category = setting.category || 'other';
      if (!grouped[category]) {
        grouped[category] = [];
      }
      grouped[category].push({ key, ...setting });
    });
    
    return grouped;
  }, [schema]);

  const categories = useMemo(() => {
    if (!schema?.categories) return [];
    return schema.categories;
  }, [schema]);

  // Filter settings
  const filteredSettingsByCategory = useMemo(() => {
    const filtered = {};
    
    Object.entries(settingsByCategory).forEach(([category, settings]) => {
      const filteredSettings = settings.filter(setting => {
        const matchesSearch = !searchQuery || 
          setting.displayName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          setting.key?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          setting.description?.toLowerCase().includes(searchQuery.toLowerCase());
        
        const matchesImpact = impactFilter === 'all' || 
          setting.performanceImpact === impactFilter;
        
        const matchesRestart = restartFilter === 'all' ||
          (restartFilter === 'none' && (!setting.restartRequired || setting.restartRequired === 'None')) ||
          (restartFilter === 'DCS' && setting.restartRequired === 'DCS');
        
        return matchesSearch && matchesImpact && matchesRestart;
      });
      
      if (filteredSettings.length > 0) {
        filtered[category] = filteredSettings;
      }
    });
    
    return filtered;
  }, [settingsByCategory, searchQuery, impactFilter, restartFilter]);

  // Check if a setting is enabled
  const isSettingEnabled = (settingKey) => {
    if (!config?.testsToRun) return false;
    return config.testsToRun.some(t => t.setting === settingKey && t.enabled !== false);
  };

  // Get test values for a setting
  const getTestValues = (settingKey) => {
    if (!config?.testsToRun) return [];
    const test = config.testsToRun.find(t => t.setting === settingKey);
    return test?.values || [];
  };

  // Toggle a setting
  const toggleSetting = (settingKey, settingMeta) => {
    setConfig(prev => {
      const newConfig = { ...prev };
      if (!newConfig.testsToRun) newConfig.testsToRun = [];
      
      const existingIndex = newConfig.testsToRun.findIndex(t => t.setting === settingKey);
      
      if (existingIndex >= 0) {
        newConfig.testsToRun = [...newConfig.testsToRun];
        newConfig.testsToRun[existingIndex] = {
          ...newConfig.testsToRun[existingIndex],
          enabled: !newConfig.testsToRun[existingIndex].enabled
        };
      } else {
        const defaultValues = settingMeta.range?.slice(0, 2) || [0, 1];
        newConfig.testsToRun = [...newConfig.testsToRun, {
          setting: settingKey,
          values: defaultValues,
          enabled: true
        }];
      }
      
      return newConfig;
    });
    setHasChanges(true);
  };

  // Toggle a value in a test
  const toggleValue = (settingKey, value) => {
    setConfig(prev => {
      const newConfig = { ...prev };
      const testIndex = newConfig.testsToRun?.findIndex(t => t.setting === settingKey);
      
      if (testIndex >= 0) {
        const currentValues = newConfig.testsToRun[testIndex].values || [];
        let newValues;
        
        if (currentValues.includes(value)) {
          newValues = currentValues.filter(v => v !== value);
        } else {
          newValues = [...currentValues, value].sort((a, b) => {
            if (typeof a === 'number' && typeof b === 'number') return a - b;
            return String(a).localeCompare(String(b));
          });
        }
        
        newConfig.testsToRun = [...newConfig.testsToRun];
        newConfig.testsToRun[testIndex] = {
          ...newConfig.testsToRun[testIndex],
          values: newValues
        };
      }
      
      return newConfig;
    });
    setHasChanges(true);
  };

  // Update configuration value
  const updateConfigValue = (path, value) => {
    setConfig(prev => {
      const newConfig = JSON.parse(JSON.stringify(prev));
      const parts = path.split('.');
      let current = newConfig;
      
      for (let i = 0; i < parts.length - 1; i++) {
        if (!current[parts[i]]) current[parts[i]] = {};
        current = current[parts[i]];
      }
      
      current[parts[parts.length - 1]] = value;
      return newConfig;
    });
    setHasChanges(true);
  };

  // Calibration wizard functions
  const startCalibration = () => {
    setCalibrationOpen(true);
    setCalibrationStep(0);
    setCalibrationTiming({ vr: null, coldStart: null, missionRestart: null });
    setCalibrationTimer(null);
    setCalibrationStartTime(null);
  };

  const closeCalibration = () => {
    setCalibrationOpen(false);
    setCalibrationStep(0);
    setCalibrationTimer(null);
    setCalibrationStartTime(null);
  };

  const startCalibrationTimer = () => {
    setCalibrationStartTime(Date.now());
    setCalibrationTimer(0);
    const interval = setInterval(() => {
      setCalibrationTimer(prev => prev + 1);
    }, 1000);
    return interval;
  };

  const stopCalibrationTimer = (intervalId) => {
    clearInterval(intervalId);
    const elapsed = Math.round((Date.now() - calibrationStartTime) / 1000);
    return elapsed;
  };

  const applyCalibration = () => {
    // Apply calibrated timings to config with 5 second buffer for safety
    const buffer = 5000;
    if (calibrationTiming.vr !== null) {
      updateConfigValue('configuration.waitTimes.vr', (calibrationTiming.vr * 1000) + buffer);
    }
    if (calibrationTiming.coldStart !== null) {
      updateConfigValue('configuration.waitTimes.missionReady', (calibrationTiming.coldStart * 1000) + buffer);
    }
    if (calibrationTiming.missionRestart !== null) {
      updateConfigValue('configuration.waitTimes.missionRestart', (calibrationTiming.missionRestart * 1000) + buffer);
    }
    closeCalibration();
  };

  // Toggle category expansion
  const toggleCategory = (categoryId) => {
    setExpandedCategories(prev => ({
      ...prev,
      [categoryId]: !prev[categoryId]
    }));
  };

  // Save configuration (internal, used by auto-save)
  const saveConfig = useCallback(async () => {
    if (!config || saving) return;
    
    setSaving(true);
    try {
      const result = await window.dcsMax.writeJsonConfig(
        '4-Performance-Testing/testing-configuration.json',
        config
      );
      if (result.success) {
        setHasChanges(false);
      } else {
        console.error('Failed to save configuration:', result.error);
      }
    } catch (err) {
      console.error('Error saving config:', err);
    } finally {
      setSaving(false);
    }
  }, [config, saving]);

  // Store saveConfig in a ref to avoid dependency issues in useEffect
  const saveConfigRef = useRef(saveConfig);
  useEffect(() => {
    saveConfigRef.current = saveConfig;
  }, [saveConfig]);

  // Auto-save when config changes (debounced)
  useEffect(() => {
    // Only auto-save after initial load and when there are actual changes
    if (!configLoaded || !hasChanges || !config) return;
    
    const timeoutId = setTimeout(() => {
      saveConfigRef.current();
    }, 500); // 500ms debounce
    
    return () => clearTimeout(timeoutId);
  }, [config, configLoaded, hasChanges]);

  // Get enabled tests count per category
  const getEnabledCount = (categorySettings) => {
    return categorySettings.filter(s => isSettingEnabled(s.key)).length;
  };

  // Get active tests for display
  const getActiveTests = () => {
    if (!config || !config.testsToRun) return [];
    
    return config.testsToRun
      .filter(test => test.enabled !== false)
      .map(test => {
        const settingMeta = schema?.settings?.[test.setting] || {};
        return {
          setting: test.setting,
          displayName: settingMeta.displayName || test.setting,
          values: test.values,
          count: test.values.length,
          performanceImpact: settingMeta.performanceImpact || 'UNKNOWN'
        };
      });
  };

  const activeTests = getActiveTests();
  const totalCombinations = activeTests.length === 0 
    ? 0
    : activeTests.reduce((total, test) => {
        return total === 0 ? test.count : total * test.count;
      }, 0) * (config?.configuration?.numberOfRuns || 1);

  // Run benchmark
  const runBenchmark = async () => {
    if (!confirm('This will start CapFrameX (benchmark tool), VR application, DCS, and Notepad++ (for log and progress displaying) and run automated benchmarks. This may take a while. Continue?')) {
      return;
    }

    // Auto-save settings before running (force immediate save)
    await saveConfig();

    setRunning(true);
    setProgress({ status: 'starting', message: 'Starting benchmark...' });
    setLogOutput([]);

    // Subscribe to script output for real-time updates
    window.dcsMax.onScriptOutput((data) => {
      if (data.data) {
        const lines = data.data.split('\n').filter(l => l.trim());
        setLogOutput(prev => {
          const newOutput = [...prev, ...lines].slice(-50); // Keep last 50 lines
          return newOutput;
        });
        
        // Parse progress from log output
        lines.forEach(line => {
          if (line.includes('CONFIGURING TEST')) {
            const match = line.match(/TEST (\d+)\/(\d+)/);
            if (match) {
              setProgress({
                status: 'running',
                currentTest: parseInt(match[1]),
                totalTests: parseInt(match[2]),
                message: line
              });
            }
          } else if (line.includes('COMPLETED test')) {
            const match = line.match(/test (\d+)\/(\d+)/);
            if (match) {
              setProgress(prev => ({
                ...prev,
                status: 'running',
                completedTest: parseInt(match[1]),
                message: line
              }));
            }
          } else if (line.includes('Remaining time estimated:')) {
            setProgress(prev => ({
              ...prev,
              eta: line.split('estimated:')[1]?.trim()
            }));
          }
        });
      }
    });

    window.dcsMax.onScriptComplete((data) => {
      setRunning(false);
      setProgress({ status: 'completed', message: 'Benchmark completed!' });
    });

    const args = [];
    if (closeAppsAfterTests) {
      args.push('--close-apps');
    }
    if (selectedMission) {
      args.push(`--mission=benchmark-missions\\${selectedMission}`);
    }

    window.dcsMax.executeScriptStream('4-Performance-Testing/4.1.2-dcs-testing-automation.ahk', args);
  };

  const stopBenchmark = () => {
    if (confirm('Are you sure you want to stop the benchmark?')) {
      window.dcsMax.stopScript();
      setRunning(false);
      setProgress({ status: 'stopped', message: 'Benchmark stopped by user' });
    }
  };

  // Auto-scroll log output
  useEffect(() => {
    if (logOutputRef.current) {
      logOutputRef.current.scrollTop = logOutputRef.current.scrollHeight;
    }
  }, [logOutput]);

  // Config values for display
  const configInfo = config?.configuration || {};
  const enableVR = configInfo.vr?.enabled || false;
  const configMissionPath = configInfo.mission || 'Su25-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz';
  const effectiveMissionPath = selectedMission || configMissionPath;
  const recordLength = configInfo.waitTimes?.recordLength ? (configInfo.waitTimes.recordLength / 1000) : 60;
  const numberOfRuns = configInfo.numberOfRuns || 1;

  if (!config || !schema) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center">
          {configError ? (
            <div className="text-red-400">
              <AlertTriangle className="w-8 h-8 mx-auto mb-2" />
              <p>Error loading configuration</p>
              <p className="text-sm text-slate-400 mt-1">{configError}</p>
            </div>
          ) : (
            <div className="text-slate-400">
              <RefreshCw className="w-8 h-8 animate-spin mx-auto mb-2" />
              <p>Loading configuration...</p>
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-slate-900">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700 bg-slate-800">
        <div className="flex items-center space-x-3">
          <Activity className="w-5 h-5 text-blue-400" />
          <h2 className="text-lg font-semibold text-white">Performance Testing</h2>
          {running && (
            <span className="px-2 py-0.5 text-xs bg-green-500/20 text-green-400 rounded animate-pulse">
              Running...
            </span>
          )}
          {saving && (
            <span className="px-2 py-0.5 text-xs bg-blue-500/20 text-blue-400 rounded">
              Saving...
            </span>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-700 bg-slate-800/50">
        <button
          onClick={() => setActiveTab('run')}
          className={`px-6 py-3 font-medium transition-colors ${
            activeTab === 'run'
              ? 'text-blue-400 border-b-2 border-blue-400'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          Run Benchmark
        </button>
        <button
          onClick={() => setActiveTab('tests')}
          className={`px-6 py-3 font-medium transition-colors flex items-center space-x-2 ${
            activeTab === 'tests'
              ? 'text-blue-400 border-b-2 border-blue-400'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          <span>Test Variations</span>
          {activeTests.length > 0 && (
            <span className="px-1.5 py-0.5 text-xs rounded-full bg-blue-500/20 text-blue-400">
              {activeTests.length}
            </span>
          )}
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden">
        {activeTab === 'tests' && (
          <TestSettingsTab
            categories={categories}
            filteredSettingsByCategory={filteredSettingsByCategory}
            categoryIcons={categoryIcons}
            expandedCategories={expandedCategories}
            toggleCategory={toggleCategory}
            isSettingEnabled={isSettingEnabled}
            getTestValues={getTestValues}
            toggleSetting={toggleSetting}
            toggleValue={toggleValue}
            getEnabledCount={getEnabledCount}
            searchQuery={searchQuery}
            setSearchQuery={setSearchQuery}
            impactFilter={impactFilter}
            setImpactFilter={setImpactFilter}
            restartFilter={restartFilter}
            setRestartFilter={setRestartFilter}
            config={config}
            schema={schema}
            activeTests={activeTests}
            runBenchmark={runBenchmark}
            running={running}
            setActiveTab={setActiveTab}
          />
        )}
        
        {activeTab === 'run' && (
          <RunTestsTab
            config={config}
            updateConfigValue={updateConfigValue}
            running={running}
            runBenchmark={runBenchmark}
            stopBenchmark={stopBenchmark}
            activeTests={activeTests}
            totalCombinations={totalCombinations}
            enableVR={enableVR}
            recordLength={recordLength}
            numberOfRuns={numberOfRuns}
            availableMissions={availableMissions}
            selectedMission={selectedMission}
            setSelectedMission={setSelectedMission}
            configMissionPath={configMissionPath}
            closeAppsAfterTests={closeAppsAfterTests}
            setCloseAppsAfterTests={setCloseAppsAfterTests}
            progress={progress}
            logOutput={logOutput}
            logOutputRef={logOutputRef}
            startCalibration={startCalibration}
          />
        )}
      </div>

      {/* Calibration Wizard Modal */}
      {calibrationOpen && (
        <CalibrationWizard
          step={calibrationStep}
          setStep={setCalibrationStep}
          timing={calibrationTiming}
          setTiming={setCalibrationTiming}
          timer={calibrationTimer}
          setTimer={setCalibrationTimer}
          startTime={calibrationStartTime}
          setStartTime={setCalibrationStartTime}
          vrEnabled={config?.configuration?.vr?.enabled}
          config={config}
          onClose={closeCalibration}
          onApply={applyCalibration}
        />
      )}
    </div>
  );
}

// Test Settings Tab Component
function TestSettingsTab({
  categories,
  filteredSettingsByCategory,
  categoryIcons,
  expandedCategories,
  toggleCategory,
  isSettingEnabled,
  getTestValues,
  toggleSetting,
  toggleValue,
  getEnabledCount,
  searchQuery,
  setSearchQuery,
  impactFilter,
  setImpactFilter,
  restartFilter,
  setRestartFilter,
  config,
  schema,
  activeTests,
  runBenchmark,
  running,
  setActiveTab
}) {
  return (
    <div className="flex h-full">
      {/* Settings List */}
      <div className="flex-1 overflow-y-auto p-4">
        {/* Search and Filter Bar */}
        <div className="flex items-center space-x-4 mb-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search settings..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>
          <select
            value={impactFilter}
            onChange={(e) => setImpactFilter(e.target.value)}
            className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-blue-500"
          >
            <option value="all">All Impact</option>
            <option value="HIGH">High Impact</option>
            <option value="MEDIUM">Medium Impact</option>
            <option value="LOW">Low Impact</option>
            <option value="NONE">No Impact</option>
          </select>
          <select
            value={restartFilter}
            onChange={(e) => setRestartFilter(e.target.value)}
            className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-blue-500"
          >
            <option value="all">All Restart</option>
            <option value="none">No Restart</option>
            <option value="DCS">DCS Restart</option>
          </select>
        </div>

        {/* Categories - Always Expanded */}
        <div className="space-y-4">
          {categories.map(category => {
            const categorySettings = filteredSettingsByCategory[category.id];
            if (!categorySettings || categorySettings.length === 0) return null;
            
            const Icon = categoryIcons[category.id] || Settings;
            const enabledCount = getEnabledCount(categorySettings);
            
            return (
              <div key={category.id}>
                {/* Category Header - Static, non-clickable */}
                <div className="flex items-center justify-between px-1 py-2 mb-1">
                  <div className="flex items-center space-x-2">
                    <Icon className="w-4 h-4 text-blue-400" />
                    <span className="text-sm font-medium text-white">{category.name}</span>
                  </div>
                  <span className="text-xs text-slate-500">
                    {enabledCount > 0 ? (
                      <span className="text-blue-400">{enabledCount}/{categorySettings.length}</span>
                    ) : (
                      categorySettings.length
                    )}
                  </span>
                </div>
                
                {/* Settings Table */}
                <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
                  {categorySettings.map((setting, idx) => (
                    <SettingRow
                      key={setting.key}
                      setting={setting}
                      isEnabled={isSettingEnabled(setting.key)}
                      selectedValues={getTestValues(setting.key)}
                      onToggle={() => toggleSetting(setting.key, setting)}
                      onToggleValue={(value) => toggleValue(setting.key, value)}
                      testsToRun={config?.testsToRun || []}
                      schema={schema}
                      isLast={idx === categorySettings.length - 1}
                    />
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Summary Panel */}
      <div className="w-80 border-l border-slate-700 bg-slate-800/50 p-4 overflow-y-auto flex flex-col">
        <h3 className="text-lg font-semibold text-white mb-4">Test Summary</h3>
        
        <div className="flex-1 overflow-y-auto">
          {activeTests.length > 0 ? (
            <div className="space-y-3">
              {activeTests.map(test => {
                const settingMeta = schema.settings[test.setting] || {};
                return (
                  <div key={test.setting} className="p-3 bg-slate-700/50 rounded-lg">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-medium text-white text-sm">
                        {settingMeta.displayName || test.setting}
                      </span>
                      <button
                        onClick={() => toggleSetting(test.setting, settingMeta)}
                        className="text-slate-400 hover:text-red-400 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                    <div className="flex flex-wrap gap-1">
                      {test.values.map(v => (
                        <span
                          key={v}
                          className="px-2 py-0.5 text-xs bg-blue-500/20 text-blue-400 rounded"
                        >
                          {String(v)}
                        </span>
                      ))}
                    </div>
                  </div>
                );
              })}
              
              <div className="pt-3 border-t border-slate-700">
                <div className="flex justify-between text-sm mb-4">
                  <span className="text-slate-400">Total Tests:</span>
                  <span className="text-white font-medium">
                    {activeTests.reduce((sum, t) => sum + t.values.length, 0)}
                  </span>
                </div>
                
                {/* Start Comparison Button */}
                <button
                  onClick={() => {
                    setActiveTab('run');
                    setTimeout(() => runBenchmark(), 100);
                  }}
                  disabled={running}
                  className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 hover:bg-green-500 disabled:bg-slate-600 disabled:opacity-50 rounded-lg transition-colors font-medium text-sm text-white"
                >
                  <Play className="w-4 h-4" />
                  <span>Start Comparison Benchmark</span>
                </button>
              </div>
            </div>
          ) : (
            <div className="py-4 text-slate-400">
              {/* How it works */}
              <div className="bg-slate-700/30 rounded-lg p-4 mb-4">
                <div className="flex items-start space-x-2 mb-3">
                  <Info className="w-4 h-4 text-blue-400 mt-0.5 flex-shrink-0" />
                  <span className="text-sm font-medium text-blue-400">How it works</span>
                </div>
                <div className="space-y-3 text-xs">
                  <div className="flex items-start space-x-2">
                    <span className="w-5 h-5 rounded-full bg-green-500/20 text-green-400 flex items-center justify-center text-xs font-bold flex-shrink-0">1</span>
                    <div>
                      <p className="text-white font-medium">Run Baseline</p>
                      <p className="text-slate-400">Benchmark your current DCS settings first (no tests selected)</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-2">
                    <span className="w-5 h-5 rounded-full bg-blue-500/20 text-blue-400 flex items-center justify-center text-xs font-bold flex-shrink-0">2</span>
                    <div>
                      <p className="text-white font-medium">Add Test Variations</p>
                      <p className="text-slate-400">Select settings that you want to test, Run a Benchmark, and then compare</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-2">
                    <span className="w-5 h-5 rounded-full bg-purple-500/20 text-purple-400 flex items-center justify-center text-xs font-bold flex-shrink-0">3</span>
                    <div>
                      <p className="text-white font-medium">Compare in CapFrameX</p>
                      <p className="text-slate-400">Analyze results to find optimal settings for your system using CapFrameX</p>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="text-center mb-4">
                <Zap className="w-6 h-6 mx-auto mb-2 opacity-50" />
                <p className="text-sm">No tests configured</p>
                <p className="text-xs mt-1 text-slate-500">First, run a Baseline Benchmark to evaluate your current DCS settings performance. Then, select settings in Test Variations tab, run a Comparison Benchmark, and compare the results in CapFrameX.</p>
              </div>
              
              {/* Start Baseline Button */}
              <div className="pt-3 border-t border-slate-700">
                <button
                  onClick={() => {
                    setActiveTab('run');
                    setTimeout(() => runBenchmark(), 100);
                  }}
                  disabled={running}
                  className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 hover:bg-green-500 disabled:bg-slate-600 disabled:opacity-50 rounded-lg transition-colors font-medium text-sm text-white"
                >
                  <Play className="w-4 h-4" />
                  <span>Start Baseline Benchmark</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Setting Row Component - Compact table-like design
function SettingRow({ setting, isEnabled, selectedValues, onToggle, onToggleValue, testsToRun, schema, isLast }) {
  const [isExpanded, setIsExpanded] = useState(isEnabled);
  
  // Auto-expand when enabled, auto-collapse when disabled
  useEffect(() => {
    setIsExpanded(isEnabled);
  }, [isEnabled]);
  
  // Check if this setting has a dependency that's not met
  const checkDependency = () => {
    if (!setting.dependsOn || !testsToRun || !schema) return { met: true, message: '' };
    
    const { setting: depSetting, values: requiredValues, disabledMessage } = setting.dependsOn;
    const depTest = testsToRun.find(t => t.setting === depSetting && t.enabled !== false);
    
    if (!depTest) {
      return { met: false, message: disabledMessage || `Requires ${depSetting} to be configured` };
    }
    
    const hasMatchingValue = depTest.values?.some(v => requiredValues.includes(v));
    if (!hasMatchingValue) {
      return { met: false, message: disabledMessage || `Requires ${depSetting} set to: ${requiredValues.join(' or ')}` };
    }
    
    return { met: true, message: '' };
  };
  
  const dependency = checkDependency();
  const isDisabled = !dependency.met;
  const showExpanded = isEnabled && isExpanded && setting.range;
  
  // Impact color - discrete text only
  const impactTextColor = {
    HIGH: 'text-red-400/80',
    MEDIUM: 'text-yellow-400/80',
    LOW: 'text-green-400/80',
    NONE: 'text-slate-500'
  };
  
  return (
    <div className={`${isDisabled ? 'opacity-50' : ''} ${!isLast ? 'border-b border-slate-700/50' : ''}`}>
      {/* Compact Row */}
      <div 
        className={`flex items-center px-3 py-2 gap-3 cursor-pointer hover:bg-slate-700/30 transition-colors ${
          isEnabled ? 'bg-slate-700/20' : ''
        }`}
        onClick={() => !isDisabled && setting.range && setIsExpanded(!isExpanded)}
      >
        {/* Checkbox */}
        <button
          onClick={(e) => { e.stopPropagation(); if (!isDisabled) onToggle(); }}
          disabled={isDisabled}
          title={isDisabled ? dependency.message : ''}
          className={`w-4 h-4 rounded flex items-center justify-center transition-colors flex-shrink-0 ${
            isDisabled
              ? 'bg-slate-700 cursor-not-allowed'
              : isEnabled
                ? 'bg-blue-600'
                : 'border border-slate-500 hover:border-slate-400'
          }`}
        >
          {isEnabled && !isDisabled && <Check className="w-2.5 h-2.5 text-white" />}
        </button>

        {/* Setting Name */}
        <span className={`text-sm w-40 flex-shrink-0 truncate ${isEnabled ? 'text-white font-medium' : 'text-slate-300'}`}>
          {setting.displayName}
        </span>
        
        {/* Impact - Discrete text with tooltip */}
        <span 
          className={`text-xs w-14 flex-shrink-0 cursor-help ${impactTextColor[setting.performanceImpact] || impactTextColor.NONE}`}
          title={{
            HIGH: 'High performance impact - significant FPS difference',
            MEDIUM: 'Medium performance impact - moderate FPS difference',
            LOW: 'Low performance impact - minimal FPS difference',
            NONE: 'No performance impact'
          }[setting.performanceImpact] || 'Unknown impact'}
        >
          {setting.performanceImpact}
        </span>
        
        {/* Restart indicator with tooltip */}
        <div className="w-5 flex-shrink-0" title={setting.restartRequired === 'DCS' ? 'Requires DCS restart - Changes only take effect after restarting DCS' : ''}>
          {setting.restartRequired === 'DCS' && (
            <RefreshCw className="w-3.5 h-3.5 text-orange-400/70 cursor-help" />
          )}
        </div>
        
        {/* Description - Truncated */}
        <span className="flex-1 text-xs text-slate-500 truncate min-w-0">
          {isDisabled ? (
            <span className="text-yellow-500/70 flex items-center gap-1">
              <AlertTriangle className="w-3 h-3 inline flex-shrink-0" />
              {dependency.message}
            </span>
          ) : (
            setting.description
          )}
        </span>
        
        {/* Selected count (when enabled) */}
        <div className="w-8 flex-shrink-0 text-right">
          {isEnabled && selectedValues.length > 0 && (
            <span className="text-xs text-blue-400">[{selectedValues.length}]</span>
          )}
        </div>
      </div>
      
      {/* Expanded Content - Value Selection */}
      {showExpanded && (
        <div className="px-3 pb-2 pt-1 pl-10 bg-slate-800/50">
          <div className="flex flex-wrap gap-1.5">
            {setting.range.map(value => {
              const isSelected = selectedValues.includes(value);
              const idx = setting.range.indexOf(value);
              const label = setting.rangeLabels?.[idx] || String(value);
              
              return (
                <button
                  key={value}
                  onClick={(e) => { e.stopPropagation(); onToggleValue(value); }}
                  className={`px-2 py-0.5 text-xs rounded transition-colors ${
                    isSelected
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-700 text-slate-400 hover:bg-slate-600 hover:text-slate-300'
                  }`}
                >
                  {label}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

// Run Tests Tab Component (merged with Configuration)
function RunTestsTab({
  config,
  updateConfigValue,
  running,
  runBenchmark,
  stopBenchmark,
  activeTests,
  totalCombinations,
  enableVR,
  recordLength,
  numberOfRuns,
  availableMissions,
  selectedMission,
  setSelectedMission,
  configMissionPath,
  closeAppsAfterTests,
  setCloseAppsAfterTests,
  progress,
  logOutput,
  logOutputRef,
  startCalibration
}) {
  const configInfo = config?.configuration || {};
  const [showHowItWorks, setShowHowItWorks] = useState(true);
  
  // Determine mode
  const isBaselineMode = activeTests.length === 0;
  
  return (
    <div className="flex h-full">
      {/* Main Content */}
      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl space-y-6">
          {/* Quick Start Panel */}
          <div className="bg-gradient-to-br from-slate-800 to-slate-800/50 rounded-xl border border-slate-700 overflow-hidden">
            <div className="p-6">
              {/* Mode Indicator */}
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                    isBaselineMode ? 'bg-green-500/20' : 'bg-blue-500/20'
                  }`}>
                    {isBaselineMode ? (
                      <Zap className="w-5 h-5 text-green-400" />
                    ) : (
                      <Activity className="w-5 h-5 text-blue-400" />
                    )}
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-white">
                      {isBaselineMode ? 'Baseline Benchmark' : 'Comparison Benchmark'}
                    </h3>
                    <p className="text-sm text-slate-400">
                      {isBaselineMode 
                        ? 'Test your current DCS settings performance'
                        : `Testing ${totalCombinations} variations across ${activeTests.length} settings`
                      }
                    </p>
                  </div>
                </div>
                <span className={`px-3 py-1 text-xs font-medium rounded-full ${
                  isBaselineMode 
                    ? 'bg-green-500/20 text-green-400 border border-green-500/30'
                    : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                }`}>
                  {isBaselineMode ? 'Baseline Mode' : 'Comparison Mode'}
                </span>
              </div>
              
              {/* Progress Status (when running) */}
              {progress && (
                <div className={`mt-4 rounded-lg p-3 ${
                  progress.status === 'running' ? 'bg-blue-500/10 border border-blue-500/20' :
                  progress.status === 'completed' ? 'bg-green-500/10 border border-green-500/20' :
                  progress.status === 'stopped' ? 'bg-red-500/10 border border-red-500/20' :
                  'bg-slate-700/50'
                }`}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-2">
                      {progress.status === 'running' && <Activity className="w-4 h-4 text-blue-400 animate-pulse" />}
                      {progress.status === 'completed' && <CheckCircle className="w-4 h-4 text-green-400" />}
                      {progress.status === 'stopped' && <StopCircle className="w-4 h-4 text-red-400" />}
                      <span className="text-sm font-medium text-white">
                        {progress.status === 'completed' || progress.status === 'stopped' 
                          ? progress.message 
                          : progress.currentTest && `Test ${progress.currentTest} / ${progress.totalTests}`}
                      </span>
                    </div>
                    {progress.eta && (
                      <span className="text-xs text-slate-400">ETA: {progress.eta}</span>
                    )}
                  </div>
                </div>
              )}
            </div>
            
            {/* How it works - Collapsible */}
            {!running && (
              <div className="border-t border-slate-700">
                <button
                  onClick={() => setShowHowItWorks(!showHowItWorks)}
                  className="w-full px-6 py-3 flex items-center justify-between text-slate-400 hover:text-white hover:bg-slate-700/30 transition-colors"
                >
                  <div className="flex items-center space-x-2">
                    <Info className="w-4 h-4" />
                    <span className="text-sm">How it works</span>
                  </div>
                  <ChevronDown className={`w-4 h-4 transition-transform ${showHowItWorks ? 'rotate-180' : ''}`} />
                </button>
                {showHowItWorks && (
                  <div className="px-6 pb-4 space-y-3">
                    <div className="flex items-start space-x-3">
                      <span className="w-6 h-6 rounded-full bg-green-500/20 text-green-400 flex items-center justify-center text-xs font-bold">1</span>
                      <div>
                        <p className="text-sm text-white font-medium">Run Baseline</p>
                        <p className="text-xs text-slate-400">Benchmark your current DCS settings first (no tests selected)</p>
                      </div>
                    </div>
                    <div className="flex items-start space-x-3">
                      <span className="w-6 h-6 rounded-full bg-blue-500/20 text-blue-400 flex items-center justify-center text-xs font-bold">2</span>
                      <div>
                        <p className="text-sm text-white font-medium">Add Test Variations</p>
                        <p className="text-xs text-slate-400">Go to "Test Variations" tab to select settings that you want to test, Run a Benchmark, and then compare</p>
                      </div>
                    </div>
                    <div className="flex items-start space-x-3">
                      <span className="w-6 h-6 rounded-full bg-purple-500/20 text-purple-400 flex items-center justify-center text-xs font-bold">3</span>
                      <div>
                        <p className="text-sm text-white font-medium">Compare in CapFrameX</p>
                        <p className="text-xs text-slate-400">Analyze results to find optimal settings for your system using CapFrameX</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Display Mode & Mission */}
          <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
            <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
              <h3 className="font-semibold text-white flex items-center space-x-2">
                <Monitor className="w-4 h-4 text-blue-400" />
                <span>Display Mode & Mission</span>
              </h3>
            </div>
            <div className="p-4 space-y-4">
              {/* Display Mode Row */}
              <div className="flex items-center justify-between">
                <span className="text-sm text-slate-300">Display Mode</span>
                <div className="flex items-center space-x-3">
                  {/* 2D / VR Toggle */}
                  <div className="flex bg-slate-700 rounded-lg p-1">
                    <button
                      onClick={() => updateConfigValue('configuration.vr.enabled', false)}
                      disabled={running}
                      className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                        !configInfo.vr?.enabled
                          ? 'bg-blue-600 text-white'
                          : 'text-slate-400 hover:text-white'
                      } disabled:opacity-50`}
                    >
                      <div className="flex items-center space-x-1">
                        <Monitor className="w-3.5 h-3.5" />
                        <span>2D</span>
                      </div>
                    </button>
                    <button
                      onClick={() => updateConfigValue('configuration.vr.enabled', true)}
                      disabled={running}
                      className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                        configInfo.vr?.enabled
                          ? 'bg-blue-600 text-white'
                          : 'text-slate-400 hover:text-white'
                      } disabled:opacity-50`}
                    >
                      <div className="flex items-center space-x-1">
                        <Eye className="w-3.5 h-3.5" />
                        <span>VR</span>
                      </div>
                    </button>
                  </div>
                  
                  {/* VR Hardware (only shown when VR is enabled) */}
                  {configInfo.vr?.enabled && (
                    <select
                      value={configInfo.vr?.hardware || 'Pimax'}
                      onChange={(e) => updateConfigValue('configuration.vr.hardware', e.target.value)}
                      disabled={running}
                      className="px-2 py-1.5 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:border-blue-500 disabled:opacity-50"
                    >
                      <option value="Pimax">Pimax</option>
                      <option value="MetaQuest (future)">Meta Quest</option>
                      <option value="HPReverbG2 (future)">HP Reverb G2</option>
                      <option value="ValveIndex (future)">Valve Index</option>
                      <option value="VarjoAero (future)">Varjo Aero</option>
                      <option value="Other">Other</option>
                    </select>
                  )}
                </div>
              </div>
              
              {/* Mission Row */}
              <div className="flex items-center justify-between pt-3 border-t border-slate-700">
                <span className="text-sm text-slate-300">Mission</span>
                <select
                  value={selectedMission || configMissionPath}
                  onChange={(e) => setSelectedMission(e.target.value === configMissionPath ? '' : e.target.value)}
                  disabled={running}
                  className="flex-1 ml-4 bg-slate-700 border border-slate-600 rounded-lg px-3 py-1.5 text-white text-sm focus:outline-none focus:border-blue-500 disabled:opacity-50"
                >
                  {availableMissions.map((m) => (
                    <option key={m} value={m}>{m}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Timing Settings - Linear flow */}
          <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
            <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700 flex items-center justify-between">
              <h3 className="font-semibold text-white flex items-center space-x-2">
                <Clock className="w-4 h-4 text-blue-400" />
                <span>Timing (in order of execution)</span>
              </h3>
              <button
                onClick={startCalibration}
                disabled={running}
                className="flex items-center space-x-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-600 disabled:opacity-50 rounded text-xs text-white font-medium transition-colors"
              >
                <Settings className="w-3.5 h-3.5" />
                <span>Run Calibration</span>
              </button>
            </div>
            <div className="p-4 space-y-3">
              {/* Visual timeline hint */}
              <p className="text-xs text-slate-500 mb-2">Configure wait times for each phase of the benchmark cycle:</p>
              
              {/* Phase 1: VR startup (only if VR enabled) */}
              {configInfo.vr?.enabled && (
                <div className="flex items-center space-x-3">
                  <span className="w-6 h-6 rounded-full bg-slate-700 text-xs flex items-center justify-center text-slate-400">1</span>
                  <div className="flex-1">
                    <label className="block text-sm text-slate-300">VR Client Startup</label>
                    <p className="text-xs text-slate-500">Wait for VR hardware to initialize</p>
                  </div>
                  <div className="w-24">
                    <input
                      type="number"
                      value={(configInfo.waitTimes?.vr || 15000) / 1000}
                      onChange={(e) => updateConfigValue('configuration.waitTimes.vr', parseInt(e.target.value) * 1000)}
                      disabled={running}
                      className="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                    />
                  </div>
                  <span className="text-xs text-slate-500 w-8">sec</span>
                </div>
              )}
              
              {/* Phase 2: Mission load */}
              <div className="flex items-center space-x-3">
                <span className="w-6 h-6 rounded-full bg-slate-700 text-xs flex items-center justify-center text-slate-400">{configInfo.vr?.enabled ? '2' : '1'}</span>
                <div className="flex-1">
                  <label className="block text-sm text-slate-300">Mission Load</label>
                  <p className="text-xs text-slate-500">Wait for DCS mission to fully load</p>
                </div>
                <div className="w-24">
                  <input
                    type="number"
                    value={(configInfo.waitTimes?.missionReady || 75000) / 1000}
                    onChange={(e) => updateConfigValue('configuration.waitTimes.missionReady', parseInt(e.target.value) * 1000)}
                    disabled={running}
                    className="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                  />
                </div>
                <span className="text-xs text-slate-500 w-8">sec</span>
              </div>
              
              {/* Phase 3: Before record */}
              <div className="flex items-center space-x-3">
                <span className="w-6 h-6 rounded-full bg-slate-700 text-xs flex items-center justify-center text-slate-400">{configInfo.vr?.enabled ? '3' : '2'}</span>
                <div className="flex-1">
                  <label className="block text-sm text-slate-300">Pre-Record Delay</label>
                  <p className="text-xs text-slate-500">Stabilize before recording starts</p>
                </div>
                <div className="w-24">
                  <input
                    type="number"
                    value={(configInfo.waitTimes?.beforeRecord || 3000) / 1000}
                    onChange={(e) => updateConfigValue('configuration.waitTimes.beforeRecord', parseInt(e.target.value) * 1000)}
                    disabled={running}
                    className="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                  />
                </div>
                <span className="text-xs text-slate-500 w-8">sec</span>
              </div>
              
              {/* Phase 4: Record length (highlighted as main setting) */}
              <div className="flex items-center space-x-3 bg-blue-500/10 -mx-4 px-4 py-2 border-l-2 border-blue-500">
                <span className="w-6 h-6 rounded-full bg-blue-600 text-xs flex items-center justify-center text-white">{configInfo.vr?.enabled ? '4' : '3'}</span>
                <div className="flex-1">
                  <label className="block text-sm text-white font-medium">Recording Duration</label>
                  <p className="text-xs text-slate-400">CapFrameX capture length per test</p>
                </div>
                <div className="w-24">
                  <input
                    type="number"
                    value={(configInfo.waitTimes?.recordLength || 60000) / 1000}
                    onChange={(e) => updateConfigValue('configuration.waitTimes.recordLength', parseInt(e.target.value) * 1000)}
                    disabled={running}
                    className="w-full px-2 py-1 bg-slate-700 border border-blue-500 rounded text-white text-sm text-center focus:outline-none focus:border-blue-400 disabled:opacity-50"
                  />
                </div>
                <span className="text-xs text-slate-400 w-8">sec</span>
              </div>
              
              {/* Phase 5: CapFrameX write */}
              <div className="flex items-center space-x-3">
                <span className="w-6 h-6 rounded-full bg-slate-700 text-xs flex items-center justify-center text-slate-400">{configInfo.vr?.enabled ? '5' : '4'}</span>
                <div className="flex-1">
                  <label className="block text-sm text-slate-300">Save Results</label>
                  <p className="text-xs text-slate-500">Wait for CapFrameX to write data</p>
                </div>
                <div className="w-24">
                  <input
                    type="number"
                    value={(configInfo.waitTimes?.capFrameXWrite || 5000) / 1000}
                    onChange={(e) => updateConfigValue('configuration.waitTimes.capFrameXWrite', parseInt(e.target.value) * 1000)}
                    disabled={running}
                    className="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                  />
                </div>
                <span className="text-xs text-slate-500 w-8">sec</span>
              </div>
              
              {/* Phase 6: Mission restart */}
              <div className="flex items-center space-x-3">
                <span className="w-6 h-6 rounded-full bg-slate-700 text-xs flex items-center justify-center text-slate-400">{configInfo.vr?.enabled ? '6' : '5'}</span>
                <div className="flex-1">
                  <label className="block text-sm text-slate-300">Mission Restart</label>
                  <p className="text-xs text-slate-500">Wait after mission restart command</p>
                </div>
                <div className="w-24">
                  <input
                    type="number"
                    value={(configInfo.waitTimes?.missionRestart || 15000) / 1000}
                    onChange={(e) => updateConfigValue('configuration.waitTimes.missionRestart', parseInt(e.target.value) * 1000)}
                    disabled={running}
                    className="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                  />
                </div>
                <span className="text-xs text-slate-500 w-8">sec</span>
              </div>
            </div>
          </div>

          {/* Options */}
          <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
            <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
              <h3 className="font-semibold text-white">Options</h3>
            </div>
            <div className="p-4 space-y-4">
              {/* Runs per Test */}
              <div className="flex items-center justify-between">
                <div>
                  <label className="block text-sm text-slate-300">Runs per Test</label>
                  <p className="text-xs text-slate-500">Repeat each test for averaging results</p>
                </div>
                <input
                  type="number"
                  value={configInfo.numberOfRuns || 1}
                  onChange={(e) => updateConfigValue('configuration.numberOfRuns', parseInt(e.target.value))}
                  min="1"
                  max="10"
                  disabled={running}
                  className="w-20 px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                />
              </div>
              
              {/* Max Retries */}
              <div className="flex items-center justify-between">
                <div>
                  <label className="block text-sm text-slate-300">Max Retries</label>
                  <p className="text-xs text-slate-500">Retry failed tests before skipping</p>
                </div>
                <input
                  type="number"
                  value={configInfo.maxRetries || 1}
                  onChange={(e) => updateConfigValue('configuration.maxRetries', parseInt(e.target.value))}
                  min="0"
                  max="5"
                  disabled={running}
                  className="w-20 px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-sm text-center focus:outline-none focus:border-blue-500 disabled:opacity-50"
                />
              </div>
              
              {/* Close apps checkbox */}
              <div className="pt-2 border-t border-slate-700">
                <label className="flex items-center justify-between cursor-pointer">
                  <span className="text-slate-300">Close all programs after finishing tests</span>
                  <input
                    type="checkbox"
                    checked={closeAppsAfterTests}
                    onChange={(e) => setCloseAppsAfterTests(e.target.checked)}
                    disabled={running}
                    className="w-4 h-4 rounded border-slate-600 bg-slate-700 text-blue-600 focus:ring-blue-500 focus:ring-offset-slate-800 disabled:opacity-50"
                  />
                </label>
              </div>
            </div>
          </div>

          {/* Requirements */}
          <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
            <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
              <h3 className="font-semibold text-white flex items-center space-x-2">
                <Activity className="w-4 h-4 text-purple-400" />
                <span>Requirements</span>
              </h3>
            </div>
            <div className="p-4">
              <ul className="text-sm text-slate-300 space-y-2">
                <li className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>DCS must be installed</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>DCS Saved Games folder must be configured</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>AutoHotkey v2.0 must be installed</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>CapFrameX must be installed</span>
                </li>
                <li className="flex items-center space-x-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  <span>Notepad++ must be installed</span>
                </li>
              </ul>
            </div>
          </div>

          {/* Progress / Log Output (when running) */}
          {running && logOutput.length > 0 && (
            <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
              <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700 flex items-center justify-between">
                <h3 className="font-semibold text-white flex items-center space-x-2">
                  <FileText className="w-4 h-4 text-blue-400" />
                  <span>Live Output</span>
                </h3>
                <span className="text-xs text-slate-400">{logOutput.length} lines</span>
              </div>
              <div 
                ref={logOutputRef}
                className="p-4 max-h-64 overflow-y-auto font-mono text-xs text-slate-300 bg-slate-900"
              >
                {logOutput.map((line, i) => (
                  <div key={i} className={`${line.includes('ERROR') ? 'text-red-400' : line.includes('COMPLETED') ? 'text-green-400' : ''}`}>
                    {line}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Summary Panel */}
      <div className="w-80 border-l border-slate-700 bg-slate-800/50 p-4 overflow-y-auto">
        <h3 className="text-lg font-semibold text-white mb-4">Run Summary</h3>
        
        <div className="space-y-4">
          {/* Stats */}
          <div className="bg-slate-700/50 rounded-lg p-3">
            <div className="text-slate-400 text-xs mb-1">Settings to Test</div>
            <div className="text-2xl font-bold text-white">{activeTests.length}</div>
          </div>
          
          <div className="bg-slate-700/50 rounded-lg p-3">
            <div className="text-slate-400 text-xs mb-1">Values to Test</div>
            <div className="text-2xl font-bold text-white">{totalCombinations}</div>
          </div>
          
          <div className="bg-slate-700/50 rounded-lg p-3">
            <div className="text-slate-400 text-xs mb-1">Display Mode</div>
            <div className={`text-lg font-semibold ${enableVR ? 'text-purple-400' : 'text-blue-400'}`}>
              {enableVR ? 'VR' : '2D'}
            </div>
            {enableVR && configInfo.vr?.hardware && (
              <div className="text-xs text-slate-400 mt-1">{configInfo.vr.hardware}</div>
            )}
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-slate-700/50 rounded-lg p-3">
              <div className="text-slate-400 text-xs mb-1">Record</div>
              <div className="text-lg font-semibold text-white">{recordLength}s</div>
            </div>
            <div className="bg-slate-700/50 rounded-lg p-3">
              <div className="text-slate-400 text-xs mb-1">Runs/Test</div>
              <div className="text-lg font-semibold text-white">{numberOfRuns}</div>
            </div>
          </div>

          {/* Test Variations Preview */}
          {activeTests.length > 0 && (
            <div className="bg-slate-700/50 rounded-lg p-3">
              <div className="text-slate-400 text-xs mb-2">Test Variations</div>
              <div className="space-y-1 max-h-32 overflow-y-auto">
                {activeTests.map((test) => (
                  <div key={test.setting} className="flex items-center justify-between text-xs">
                    <span className="text-slate-300 truncate mr-2">{test.displayName}</span>
                    <span className="text-blue-400">{test.count}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Benchmark Buttons */}
          {activeTests.length === 0 && (
            <div className="text-center mb-4">
              <Zap className="w-6 h-6 mx-auto mb-2 opacity-50" />
              <p className="text-sm">No tests configured</p>
              <p className="text-xs mt-1 text-slate-500">First, run a Baseline Benchmark to evaluate your current DCS settings performance. Then, select settings in Test Variations tab, run a Comparison Benchmark, and compare the results in CapFrameX.</p>
            </div>
          )}
          
          <div className="pt-3 border-t border-slate-700 space-y-3">
            {activeTests.length > 0 && (
              <p className="text-xs text-slate-400 text-center">
                First, run a Baseline Benchmark to evaluate your current DCS settings performance. Then, select settings in Test Variations tab, run a Comparison Benchmark, and compare the results in CapFrameX.
              </p>
            )}
            {activeTests.length > 0 ? (
              <button
                onClick={() => runBenchmark()}
                disabled={running}
                className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 hover:bg-green-500 disabled:bg-slate-600 disabled:opacity-50 rounded-lg transition-colors font-medium text-sm text-white"
              >
                <Play className="w-4 h-4" />
                <span>Start Comparison Benchmark</span>
              </button>
            ) : (
              <button
                onClick={() => runBenchmark()}
                disabled={running}
                className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 hover:bg-green-500 disabled:bg-slate-600 disabled:opacity-50 rounded-lg transition-colors font-medium text-sm text-white"
              >
                <Play className="w-4 h-4" />
                <span>Start Baseline Benchmark</span>
              </button>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}

export default PerformanceTesting;
