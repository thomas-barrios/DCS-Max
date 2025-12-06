import React, { useState, useEffect, useMemo } from 'react';
import {
  Save,
  X,
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
  Plus,
  Trash2,
  AlertTriangle,
  FolderOpen
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
  vr: Glasses,
  upscaling: Maximize
};

// Performance impact colors
const impactColors = {
  HIGH: 'bg-red-500/20 text-red-400 border-red-500/30',
  MEDIUM: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  LOW: 'bg-green-500/20 text-green-400 border-green-500/30',
  NONE: 'bg-slate-500/20 text-slate-400 border-slate-500/30'
};

function TestConfigEditor({ config, schema, onSave, onCancel }) {
  const [activeTab, setActiveTab] = useState('tests');
  const [editedConfig, setEditedConfig] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedCategories, setExpandedCategories] = useState({});
  const [impactFilter, setImpactFilter] = useState('all');
  const [hasChanges, setHasChanges] = useState(false);

  // Initialize edited config from props
  useEffect(() => {
    if (config) {
      setEditedConfig(JSON.parse(JSON.stringify(config)));
    }
  }, [config]);

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

  // Get category metadata
  const categories = useMemo(() => {
    if (!schema?.categories) return [];
    return schema.categories;
  }, [schema]);

  // Filter settings based on search and impact filter
  const filteredSettingsByCategory = useMemo(() => {
    const filtered = {};
    
    Object.entries(settingsByCategory).forEach(([category, settings]) => {
      const filteredSettings = settings.filter(setting => {
        // Search filter
        const matchesSearch = !searchQuery || 
          setting.displayName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          setting.key?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          setting.description?.toLowerCase().includes(searchQuery.toLowerCase());
        
        // Impact filter
        const matchesImpact = impactFilter === 'all' || 
          setting.performanceImpact === impactFilter;
        
        return matchesSearch && matchesImpact;
      });
      
      if (filteredSettings.length > 0) {
        filtered[category] = filteredSettings;
      }
    });
    
    return filtered;
  }, [settingsByCategory, searchQuery, impactFilter]);

  // Check if a setting is enabled in testsToRun
  const isSettingEnabled = (settingKey) => {
    if (!editedConfig?.testsToRun) return false;
    return editedConfig.testsToRun.some(t => t.setting === settingKey && t.enabled !== false);
  };

  // Get test values for a setting
  const getTestValues = (settingKey) => {
    if (!editedConfig?.testsToRun) return [];
    const test = editedConfig.testsToRun.find(t => t.setting === settingKey);
    return test?.values || [];
  };

  // Toggle a setting on/off
  const toggleSetting = (settingKey, settingMeta) => {
    setEditedConfig(prev => {
      const newConfig = { ...prev };
      if (!newConfig.testsToRun) newConfig.testsToRun = [];
      
      const existingIndex = newConfig.testsToRun.findIndex(t => t.setting === settingKey);
      
      if (existingIndex >= 0) {
        // Toggle existing
        newConfig.testsToRun = [...newConfig.testsToRun];
        newConfig.testsToRun[existingIndex] = {
          ...newConfig.testsToRun[existingIndex],
          enabled: !newConfig.testsToRun[existingIndex].enabled
        };
      } else {
        // Add new with default values (first two from range)
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

  // Update test values for a setting
  const updateTestValues = (settingKey, newValues) => {
    setEditedConfig(prev => {
      const newConfig = { ...prev };
      const testIndex = newConfig.testsToRun?.findIndex(t => t.setting === settingKey);
      
      if (testIndex >= 0) {
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

  // Toggle a specific value in a test
  const toggleValue = (settingKey, value) => {
    const currentValues = getTestValues(settingKey);
    let newValues;
    
    if (currentValues.includes(value)) {
      newValues = currentValues.filter(v => v !== value);
    } else {
      newValues = [...currentValues, value].sort((a, b) => {
        if (typeof a === 'number' && typeof b === 'number') return a - b;
        return String(a).localeCompare(String(b));
      });
    }
    
    updateTestValues(settingKey, newValues);
  };

  // Update configuration value
  const updateConfigValue = (path, value) => {
    setEditedConfig(prev => {
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

  // Toggle category expansion
  const toggleCategory = (categoryId) => {
    setExpandedCategories(prev => ({
      ...prev,
      [categoryId]: !prev[categoryId]
    }));
  };

  // Handle save
  const handleSave = () => {
    onSave(editedConfig);
    setHasChanges(false);
  };

  // Count enabled tests per category
  const getEnabledCount = (categorySettings) => {
    return categorySettings.filter(s => isSettingEnabled(s.key)).length;
  };

  if (!editedConfig || !schema) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-400">Loading configuration...</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-slate-900">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700 bg-slate-800">
        <div className="flex items-center space-x-3">
          <Settings className="w-5 h-5 text-blue-400" />
          <h2 className="text-lg font-semibold text-white">Test Configuration Editor</h2>
          {hasChanges && (
            <span className="px-2 py-0.5 text-xs bg-yellow-500/20 text-yellow-400 rounded">
              Unsaved changes
            </span>
          )}
        </div>
        <div className="flex items-center space-x-2">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-slate-300 hover:text-white hover:bg-slate-700 rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={!hasChanges}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 disabled:text-slate-500 text-white rounded-lg transition-colors"
          >
            <Save className="w-4 h-4" />
            <span>Save Configuration</span>
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-700 bg-slate-800/50">
        <button
          onClick={() => setActiveTab('tests')}
          className={`px-6 py-3 font-medium transition-colors ${
            activeTab === 'tests'
              ? 'text-blue-400 border-b-2 border-blue-400'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          Test Settings
        </button>
        <button
          onClick={() => setActiveTab('config')}
          className={`px-6 py-3 font-medium transition-colors ${
            activeTab === 'config'
              ? 'text-blue-400 border-b-2 border-blue-400'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          Configuration
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden">
        {activeTab === 'tests' ? (
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
                </select>
              </div>

              {/* Categories */}
              <div className="space-y-2">
                {categories.map(category => {
                  const categorySettings = filteredSettingsByCategory[category.id];
                  if (!categorySettings) return null;
                  
                  const Icon = categoryIcons[category.id] || Settings;
                  const isExpanded = expandedCategories[category.id] !== false;
                  const enabledCount = getEnabledCount(categorySettings);
                  
                  return (
                    <div key={category.id} className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
                      {/* Category Header */}
                      <button
                        onClick={() => toggleCategory(category.id)}
                        className="w-full flex items-center justify-between px-4 py-3 hover:bg-slate-700/50 transition-colors"
                      >
                        <div className="flex items-center space-x-3">
                          {isExpanded ? (
                            <ChevronDown className="w-4 h-4 text-slate-400" />
                          ) : (
                            <ChevronRight className="w-4 h-4 text-slate-400" />
                          )}
                          <Icon className="w-5 h-5 text-blue-400" />
                          <span className="font-medium text-white">{category.name}</span>
                        </div>
                        <div className="flex items-center space-x-2">
                          {enabledCount > 0 && (
                            <span className="px-2 py-0.5 text-xs bg-blue-500/20 text-blue-400 rounded">
                              {enabledCount} selected
                            </span>
                          )}
                          <span className="text-sm text-slate-400">
                            {categorySettings.length} settings
                          </span>
                        </div>
                      </button>

                      {/* Settings List */}
                      {isExpanded && (
                        <div className="border-t border-slate-700 divide-y divide-slate-700/50">
                          {categorySettings.map(setting => (
                            <SettingRow
                              key={setting.key}
                              setting={setting}
                              isEnabled={isSettingEnabled(setting.key)}
                              selectedValues={getTestValues(setting.key)}
                              onToggle={() => toggleSetting(setting.key, setting)}
                              onToggleValue={(value) => toggleValue(setting.key, value)}
                            />
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Summary Panel */}
            <div className="w-80 border-l border-slate-700 bg-slate-800/50 p-4 overflow-y-auto">
              <h3 className="text-lg font-semibold text-white mb-4">Test Summary</h3>
              
              {editedConfig.testsToRun?.filter(t => t.enabled !== false).length > 0 ? (
                <div className="space-y-3">
                  {editedConfig.testsToRun
                    .filter(t => t.enabled !== false)
                    .map(test => {
                      const settingMeta = schema.settings[test.setting] || {};
                      return (
                        <div
                          key={test.setting}
                          className="p-3 bg-slate-700/50 rounded-lg"
                        >
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
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-400">Total Tests:</span>
                      <span className="text-white font-medium">
                        {editedConfig.testsToRun
                          .filter(t => t.enabled !== false)
                          .reduce((sum, t) => sum + t.values.length, 0)}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm mt-1">
                      <span className="text-slate-400">Combinations:</span>
                      <span className="text-white font-medium">
                        {editedConfig.testsToRun
                          .filter(t => t.enabled !== false)
                          .reduce((prod, t) => prod * t.values.length, 1) *
                          (editedConfig.configuration?.numberOfRuns || 1)}
                      </span>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8 text-slate-400">
                  <Zap className="w-8 h-8 mx-auto mb-2 opacity-50" />
                  <p className="text-sm">No tests selected</p>
                  <p className="text-xs mt-1">Select settings from the left to add tests</p>
                </div>
              )}
            </div>
          </div>
        ) : (
          <ConfigurationPanel
            config={editedConfig.configuration}
            onUpdate={(path, value) => updateConfigValue(`configuration.${path}`, value)}
          />
        )}
      </div>
    </div>
  );
}

// Individual setting row component
function SettingRow({ setting, isEnabled, selectedValues, onToggle, onToggleValue }) {
  const [showDetails, setShowDetails] = useState(false);
  
  return (
    <div className="px-4 py-3">
      <div className="flex items-start space-x-3">
        {/* Toggle */}
        <button
          onClick={onToggle}
          className={`mt-0.5 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${
            isEnabled
              ? 'bg-blue-600 border-blue-600'
              : 'border-slate-500 hover:border-slate-400'
          }`}
        >
          {isEnabled && <Check className="w-3 h-3 text-white" />}
        </button>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center space-x-2">
            <span className={`font-medium ${isEnabled ? 'text-white' : 'text-slate-300'}`}>
              {setting.displayName}
            </span>
            <span className={`px-1.5 py-0.5 text-xs rounded border ${impactColors[setting.performanceImpact] || impactColors.NONE}`}>
              {setting.performanceImpact}
            </span>
            {setting.restartRequired === 'DCS' && (
              <span className="px-1.5 py-0.5 text-xs bg-orange-500/20 text-orange-400 rounded">
                Restart
              </span>
            )}
          </div>
          
          <p className="text-sm text-slate-400 mt-1 line-clamp-2">
            {setting.description}
          </p>

          {/* Value Selection */}
          {isEnabled && setting.range && (
            <div className="mt-3">
              <div className="text-xs text-slate-400 mb-2">Select values to test:</div>
              <div className="flex flex-wrap gap-1.5">
                {setting.range.map(value => {
                  const isSelected = selectedValues.includes(value);
                  const label = setting.rangeLabels?.[setting.range.indexOf(value)] || String(value);
                  
                  return (
                    <button
                      key={value}
                      onClick={() => onToggleValue(value)}
                      className={`px-2 py-1 text-xs rounded transition-colors ${
                        isSelected
                          ? 'bg-blue-600 text-white'
                          : 'bg-slate-700 text-slate-300 hover:bg-slate-600'
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
      </div>
    </div>
  );
}

// Configuration panel component
function ConfigurationPanel({ config, onUpdate }) {
  const handlePathBrowse = async (pathKey) => {
    // This would use file picker - for now just show the path
    console.log('Browse for:', pathKey);
  };

  return (
    <div className="p-6 overflow-y-auto">
      <div className="max-w-2xl space-y-6">
        {/* VR Settings */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
          <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
            <h3 className="font-semibold text-white flex items-center space-x-2">
              <Glasses className="w-4 h-4 text-blue-400" />
              <span>VR Settings</span>
            </h3>
          </div>
          <div className="p-4 space-y-4">
            <label className="flex items-center justify-between">
              <span className="text-slate-300">Enable VR Mode</span>
              <button
                onClick={() => onUpdate('vr.enabled', !config?.vr?.enabled)}
                className={`w-12 h-6 rounded-full transition-colors ${
                  config?.vr?.enabled ? 'bg-blue-600' : 'bg-slate-600'
                }`}
              >
                <div className={`w-5 h-5 rounded-full bg-white shadow transform transition-transform ${
                  config?.vr?.enabled ? 'translate-x-6' : 'translate-x-0.5'
                }`} />
              </button>
            </label>
            
            <div>
              <label className="block text-sm text-slate-400 mb-1">VR Hardware</label>
              <select
                value={config?.vr?.hardware || 'Pimax'}
                onChange={(e) => onUpdate('vr.hardware', e.target.value)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500"
              >
                <option value="Pimax">Pimax</option>
                <option value="MetaQuest">Meta Quest</option>
                <option value="HPReverbG2">HP Reverb G2</option>
                <option value="ValveIndex">Valve Index</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>
        </div>

        {/* Timing Settings */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
          <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
            <h3 className="font-semibold text-white flex items-center space-x-2">
              <Settings className="w-4 h-4 text-blue-400" />
              <span>Timing Settings</span>
            </h3>
          </div>
          <div className="p-4 grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm text-slate-400 mb-1">Record Length (seconds)</label>
              <input
                type="number"
                value={(config?.waitTimes?.recordLength || 60000) / 1000}
                onChange={(e) => onUpdate('waitTimes.recordLength', parseInt(e.target.value) * 1000)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-1">Mission Ready Wait (seconds)</label>
              <input
                type="number"
                value={(config?.waitTimes?.missionReady || 30000) / 1000}
                onChange={(e) => onUpdate('waitTimes.missionReady', parseInt(e.target.value) * 1000)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-1">Runs per Test</label>
              <input
                type="number"
                value={config?.numberOfRuns || 1}
                onChange={(e) => onUpdate('numberOfRuns', parseInt(e.target.value))}
                min="1"
                max="10"
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-1">Max Retries</label>
              <input
                type="number"
                value={config?.maxRetries || 1}
                onChange={(e) => onUpdate('maxRetries', parseInt(e.target.value))}
                min="0"
                max="5"
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>
        </div>

        {/* Paths */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 overflow-hidden">
          <div className="px-4 py-3 bg-slate-700/50 border-b border-slate-700">
            <h3 className="font-semibold text-white flex items-center space-x-2">
              <FolderOpen className="w-4 h-4 text-blue-400" />
              <span>File Paths</span>
            </h3>
          </div>
          <div className="p-4 space-y-4">
            <div>
              <label className="block text-sm text-slate-400 mb-1">DCS Executable</label>
              <input
                type="text"
                value={config?.paths?.dcsExe || ''}
                onChange={(e) => onUpdate('paths.dcsExe', e.target.value)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:border-blue-500"
                placeholder="C:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe"
              />
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-1">Options.lua Path</label>
              <input
                type="text"
                value={config?.paths?.optionsLua || ''}
                onChange={(e) => onUpdate('paths.optionsLua', e.target.value)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:border-blue-500"
                placeholder="%USERPROFILE%\Saved Games\DCS\Config\options.lua"
              />
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-1">CapFrameX Path</label>
              <input
                type="text"
                value={config?.paths?.capframex || ''}
                onChange={(e) => onUpdate('paths.capframex', e.target.value)}
                className="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-sm focus:outline-none focus:border-blue-500"
                placeholder="C:\Program Files (x86)\CapFrameX\CapFrameX.exe"
              />
            </div>
          </div>
        </div>

        {/* Dry Run */}
        <div className="bg-slate-800 rounded-lg border border-slate-700 p-4">
          <label className="flex items-center justify-between">
            <div>
              <span className="text-white font-medium">Dry Run Mode</span>
              <p className="text-sm text-slate-400 mt-1">
                Skip actual benchmark runs for testing the script
              </p>
            </div>
            <button
              onClick={() => onUpdate('dryRun', !config?.dryRun)}
              className={`w-12 h-6 rounded-full transition-colors ${
                config?.dryRun ? 'bg-blue-600' : 'bg-slate-600'
              }`}
            >
              <div className={`w-5 h-5 rounded-full bg-white shadow transform transition-transform ${
                config?.dryRun ? 'translate-x-6' : 'translate-x-0.5'
              }`} />
            </button>
          </label>
        </div>
      </div>
    </div>
  );
}

export default TestConfigEditor;
