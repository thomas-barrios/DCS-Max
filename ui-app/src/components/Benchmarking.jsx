import React, { useState, useEffect, useCallback } from 'react';
import { 
  Play, 
  StopCircle, 
  Settings, 
  Edit3,
  RefreshCw,
  Activity,
  Lightbulb
} from 'lucide-react';

function Benchmarking() {
  const [config, setConfig] = useState(null);
  const [running, setRunning] = useState(false);

  const loadConfig = useCallback(async () => {
    try {
      const result = await window.dcsMax.readIniConfig('4-Performance-Testing/4.1.1-dcs-testing-configuration.ini');
      if (result.success) {
        setConfig(result.parsed);
      }
    } catch (err) {
      console.error('Error loading config:', err);
    }
  }, []);

  useEffect(() => {
    loadConfig();
    
    // Auto-refresh when window regains focus (after editing file externally)
    const handleFocus = () => {
      loadConfig();
    };
    window.addEventListener('focus', handleFocus);
    
    return () => {
      window.removeEventListener('focus', handleFocus);
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

    // Start the AutoHotkey benchmark script (without --headless, so Notepad++ opens)
    window.dcsMax.executeScriptStream('4-Performance-Testing/4.1.2-dcs-testing-automation.ahk', []);
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
  const totalCombinations = activeTests.reduce((total, test) => {
    return total === 0 ? test.count : total * test.count;
  }, 0);

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Main Panel - Configuration */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-6 max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-white mb-6">DCS Benchmarking</h2>

          {/* Tip Box */}
          <div className="mb-6 p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-lg">
            <div className="flex items-start space-x-3">
              <Lightbulb className="w-5 h-5 text-yellow-400 flex-shrink-0 mt-0.5" />
              <div>
                <h4 className="font-semibold text-yellow-400 mb-1">Tip: Benchmark Before Optimization</h4>
                <p className="text-sm text-slate-300">
                  Run a benchmark first to establish a baseline, then apply optimizations and run another benchmark 
                  to compare results in CapFrameX. This helps you measure the actual performance improvements.
                </p>
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 gap-3 mb-6">
            <div className="bg-slate-800 rounded-lg p-3 border border-slate-700">
              <div className="text-slate-400 text-xs mb-1">Active Tests</div>
              <div className="text-2xl font-bold text-white">{activeTests.length}</div>
            </div>
            <div className="bg-slate-800 rounded-lg p-3 border border-slate-700">
              <div className="text-slate-400 text-xs mb-1">Total Runs</div>
              <div className="text-2xl font-bold text-white">{totalCombinations}</div>
            </div>
          </div>

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

          {/* Active Tests List */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-white mb-3">Active Test Settings</h3>
            {activeTests.length === 0 ? (
              <div className="text-center py-8 text-slate-400">
                <Settings className="w-12 h-12 mx-auto mb-3 opacity-50" />
                <p className="text-sm">No tests configured</p>
                <p className="text-xs">Edit the configuration to add tests</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-2">
                {activeTests.map((test) => (
                  <div
                    key={test.setting}
                    className="bg-slate-800 rounded-lg p-3 border border-slate-700"
                  >
                    <div className="font-semibold text-white text-sm mb-1">
                      {test.setting}
                    </div>
                    <div className="text-xs text-slate-400">
                      {test.values.join(', ')}
                    </div>
                    <div className="text-xs text-blue-400 mt-1">
                      {test.count} variations
                    </div>
                  </div>
                ))}
              </div>
            )}
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
