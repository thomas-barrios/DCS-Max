import React, { useState, useEffect, useCallback } from 'react';
import { 
  Play, 
  StopCircle, 
  Settings, 
  Edit3,
  RefreshCw,
  Activity,
  Lightbulb,
  X
} from 'lucide-react';

function Benchmarking() {
  const [config, setConfig] = useState(null);
  const [configError, setConfigError] = useState(null);
  const [running, setRunning] = useState(false);
  const [projectRoot, setProjectRoot] = useState('');
  const [closeAppsAfterTests, setCloseAppsAfterTests] = useState(false);
  const [availableMissions, setAvailableMissions] = useState([]);
  const [selectedMission, setSelectedMission] = useState(''); // Empty means use INI default
  const [showTip, setShowTip] = useState(() => {
    const globalSetting = localStorage.getItem('dcsmax-show-tips');
    if (globalSetting === 'false') return false;
    const localSetting = localStorage.getItem('dcsmax-tip-benchmarking');
    return localSetting === null ? true : localSetting === 'true';
  });

  const loadConfig = useCallback(async () => {
    try {
      setConfigError(null);
      const result = await window.dcsMax.readIniConfig('4-Performance-Testing/4.1.1-dcs-testing-configuration.ini');
      if (result.success) {
        setConfig(result.parsed);
      } else {
        setConfigError(result.error || 'Failed to load config');
      }
    } catch (err) {
      console.error('Error loading config:', err);
      setConfigError(err.message || 'Unknown error');
    }
  }, []);

  useEffect(() => {
    loadConfig();
    
    // Get project root for full path display
    window.dcsMax.getProjectRoot().then(result => {
      if (result.success) {
        setProjectRoot(result.path);
      }
    });

    // Load available benchmark missions
    window.dcsMax.listDirectory('4-Performance-Testing/benchmark-missions').then(result => {
      if (result.success && result.files) {
        const missions = result.files
          .filter(f => f.endsWith('.miz'))
          .sort();
        setAvailableMissions(missions);
      }
    }).catch(err => {
      console.error('Error loading missions:', err);
    });
    
    // Auto-refresh when window regains focus (after editing file externally)
    const handleFocus = () => {
      loadConfig();
    };
    window.addEventListener('focus', handleFocus);
    
    // Listen for storage changes (when tips setting is changed in Settings)
    const handleStorage = (e) => {
      if (e.key === 'dcsmax-show-tips') {
        if (e.newValue === 'true') {
          // When globally enabled, check local setting
          const localSetting = localStorage.getItem('dcsmax-tip-benchmarking');
          setShowTip(localSetting !== 'false');
        } else {
          setShowTip(false);
        }
      }
    };
    window.addEventListener('storage', handleStorage);
    
    return () => {
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('storage', handleStorage);
    };
  }, [loadConfig]);

  const runBenchmark = async () => {
    if (!confirm('This will start CapFrameX (benchmark tool), VR application, DCS, and Notepad++ (for log and progress displaying) and run automated benchmarks. This may take a while. Continue?')) {
      return;
    }

    setRunning(true);

    window.dcsMax.onScriptComplete((data) => {
      setRunning(false);
    });

    // Build arguments array based on options
    const args = [];
    if (closeAppsAfterTests) {
      args.push('--close-apps');
    }
    if (selectedMission) {
      args.push(`--mission=benchmark-missions\\${selectedMission}`);
    }

    // Start the AutoHotkey benchmark script (without --headless, so Notepad++ opens)
    window.dcsMax.executeScriptStream('4-Performance-Testing/4.1.2-dcs-testing-automation.ahk', args);
  };

  const stopBenchmark = () => {
    if (confirm('Are you sure you want to stop the benchmark?')) {
      window.dcsMax.stopScript();
      setRunning(false);
    }
  };

  const getActiveTests = () => {
    if (!config || !config.DCSOptionsTests) return [];
    
    const tests = [];
    Object.entries(config.DCSOptionsTests).forEach(([key, value]) => {
      if (key.startsWith('#')) return; // Skip comments
      
      const [values, metadata] = value.split('|');
      const valueList = values.split(',').map(v => v.trim());
      
      tests.push({
        setting: key,
        values: valueList,
        count: valueList.length,
        metadata: metadata || ''
      });
    });
    
    return tests;
  };

  const activeTests = getActiveTests();
  const totalCombinations = activeTests.length === 0 
    ? (config?.Configuration?.NumberOfRuns ? parseInt(config.Configuration.NumberOfRuns) : 1)
    : activeTests.reduce((total, test) => {
        return total === 0 ? test.count : total * test.count;
      }, 0) * (config?.Configuration?.NumberOfRuns ? parseInt(config.Configuration.NumberOfRuns) : 1);

  // Get config values for display
  const configInfo = config?.Configuration || {};
  const enableVR = configInfo.EnableVR === 'true';
  const iniMissionPath = configInfo.mission || 'benchmark-missions\\PB-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz';
  // Use selected mission if set, otherwise use INI mission
  const effectiveMissionPath = selectedMission 
    ? `benchmark-missions\\${selectedMission}` 
    : iniMissionPath;
  const mission = projectRoot ? `${projectRoot}\\4-Performance-Testing\\${effectiveMissionPath}` : `4-Performance-Testing\\${effectiveMissionPath}`;
  const recordLength = configInfo.WaitRecordLength ? (parseInt(configInfo.WaitRecordLength) / 1000) : 60;
  const numberOfRuns = configInfo.NumberOfRuns ? parseInt(configInfo.NumberOfRuns) : 1;

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Main Panel - Configuration */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-6 max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-white mb-6">DCS Benchmarking</h2>

          {/* Tip Box */}
          {showTip && (
            <div className="mb-6 p-4 bg-warning-500/20 border border-warning-500/50 rounded-lg">
              <div className="flex items-start space-x-3">
                <Lightbulb className="w-5 h-5 text-warning-500 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-semibold text-warning-500 mb-1">Tip: Benchmark Before Optimization</h4>
                  <p className="text-sm text-warning-200">
                    Run a benchmark first to establish a baseline, then apply optimizations and run another benchmark 
                    to compare results in CapFrameX. This helps you measure the actual performance improvements.
                  </p>
                </div>
                <button
                  onClick={() => {
                    setShowTip(false);
                    localStorage.setItem('dcsmax-tip-benchmarking', 'false');
                  }}
                  className="text-warning-500/60 hover:text-warning-500 transition-colors"
                  title="Dismiss tip"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>
          )}

          {/* Debug/Error info */}
          {configError && (
            <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-300 text-sm">
              Error loading config: {configError}
            </div>
          )}
          {!config && !configError && (
            <div className="mb-4 p-3 bg-blue-500/20 border border-blue-500/50 rounded-lg text-blue-300 text-sm">
              Loading configuration...
            </div>
          )}

          {/* Control Buttons */}
          <div className="space-y-3 mb-6">
            <button
              onClick={async () => {
                const result = await window.dcsMax.openFile('4-Performance-Testing/4.1.1-dcs-testing-configuration.ini');
                if (!result.success) {
                  alert('Failed to open file: ' + result.error);
                }
              }}
              disabled={running}
              className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 rounded-lg transition-colors"
            >
              <Edit3 className="w-4 h-4" />
              <span>Edit Configuration</span>
            </button>

            <button
              onClick={loadConfig}
              disabled={running}
              className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-slate-700 hover:bg-slate-600 disabled:bg-slate-800 rounded-lg transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              <span>Refresh Config</span>
            </button>

            {!running ? (
              <button
                onClick={runBenchmark}
                className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-green-600 hover:bg-green-700 rounded-lg transition-colors font-semibold"
              >
                <Play className="w-5 h-5" />
                <span>Start Benchmark</span>
              </button>
            ) : (
              <button
                onClick={stopBenchmark}
                className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-red-600 hover:bg-red-700 rounded-lg transition-colors font-semibold"
              >
                <StopCircle className="w-5 h-5" />
                <span>Stop Benchmark</span>
              </button>
            )}
          </div>

          {/* Test Configuration Group */}
          <div className="bg-slate-800 rounded-lg border border-slate-700 mb-6 overflow-hidden">
            <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
              <h3 className="text-lg font-semibold text-white">Test Configuration</h3>
            </div>
            
            <div className="p-4">
              {/* Top Stats Row - 3 columns */}
              <div className="grid grid-cols-3 gap-3 mb-4">
                <div className="bg-slate-700/50 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-white">{activeTests.length}</div>
                  <div className="text-slate-400 text-xs">Active Tests</div>
                </div>
                <div className="bg-slate-700/50 rounded-lg p-3 text-center">
                  <div className="text-2xl font-bold text-white">{totalCombinations}</div>
                  <div className="text-slate-400 text-xs">Total Runs</div>
                </div>
                <div className="bg-slate-700/50 rounded-lg p-3 text-center">
                  <div className="text-slate-400 text-xs mb-1">VR Mode</div>
                  <div className={`text-lg font-semibold ${enableVR ? 'text-green-400' : 'text-slate-300'}`}>
                    {enableVR ? 'Enabled' : 'Disabled'}
                  </div>
                </div>
              </div>

              {/* Second Stats Row - 2 columns */}
              <div className="grid grid-cols-2 gap-3 mb-4">
                <div className="bg-slate-700/50 rounded-lg p-3 text-center">
                  <div className="text-slate-400 text-xs mb-1">Record Length</div>
                  <div className="text-lg font-semibold text-white">{recordLength}s</div>
                </div>
                <div className="bg-slate-700/50 rounded-lg p-3 text-center">
                  <div className="text-slate-400 text-xs mb-1">Runs per Test</div>
                  <div className="text-lg font-semibold text-white">{numberOfRuns}</div>
                </div>
              </div>

              {/* Mission Selection */}
              <div className="mb-4">
                <div className="text-slate-400 text-xs mb-2">Mission</div>
                <select
                  value={selectedMission}
                  onChange={(e) => setSelectedMission(e.target.value)}
                  disabled={running}
                  className="w-full bg-slate-700/50 border border-slate-600/50 rounded p-2 text-sm text-slate-300 focus:outline-none focus:border-blue-500 disabled:opacity-50"
                >
                  <option value="">Use INI default ({iniMissionPath.split('\\').pop()})</option>
                  {availableMissions.map((m) => (
                    <option key={m} value={m}>{m}</option>
                  ))}
                </select>
              </div>

              {/* Options */}
              <div className="mb-4">
                <label className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={closeAppsAfterTests}
                    onChange={(e) => setCloseAppsAfterTests(e.target.checked)}
                    disabled={running}
                    className="w-4 h-4 rounded border-slate-600 bg-slate-700 text-blue-600 focus:ring-blue-500 focus:ring-offset-slate-800 disabled:opacity-50"
                  />
                  <span className="text-sm text-slate-300">Close all programs after finishing tests</span>
                </label>
              </div>

              {/* Test Variations */}
              <div>
                <div className="text-slate-400 text-xs mb-2">Test Variations</div>
                <div className="border-t border-slate-600/50">
                  {activeTests.length === 0 ? (
                    <div className="py-4 text-center text-slate-500 text-sm">
                      <Settings className="w-6 h-6 mx-auto mb-1 opacity-50" />
                      Baseline Mode - No test variations configured
                    </div>
                  ) : (
                    <div className="divide-y divide-slate-700/50">
                      {activeTests.map((test) => (
                        <div key={test.setting} className="flex items-center justify-between py-2 px-1">
                          <span className="text-white font-medium text-sm">{test.setting}</span>
                          <span className="text-blue-400 text-sm flex-1 text-center px-2">{test.values.join(', ')}</span>
                          <span className="text-slate-500 text-xs">{test.count} value{test.count > 1 ? 's' : ''}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Info */}
          <div className="p-4 bg-purple-500/10 border border-purple-500/30 rounded-lg mb-6">
            <h4 className="font-semibold text-purple-400 mb-2 flex items-center">
              <Activity className="w-4 h-4 mr-2" />
              Requirements
            </h4>
            <ul className="text-sm text-slate-300 space-y-1">
              <li>• AutoHotkey v2.0 must be installed</li>
              <li>• CapFrameX must be installed</li>
              <li>• Notepad++ must be installed</li>
              <li>• Test configuration is set up</li>
            </ul>
          </div>

          {/* Instructions */}
          <div className="p-4 bg-slate-800 border border-slate-700 rounded-lg">
            <p className="text-slate-300 text-sm">
              Click "Start Benchmark" to begin automated testing.
            </p>
            <p className="text-slate-400 text-xs mt-2">
              Log and progress will be displayed in Notepad++ during the benchmark run.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Benchmarking;
