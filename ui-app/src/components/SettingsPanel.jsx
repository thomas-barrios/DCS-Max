import React, { useState } from 'react';
import { 
  ExternalLink,
  Lightbulb
} from 'lucide-react';

function SettingsPanel() {
  const [showTips, setShowTips] = useState(() => {
    const saved = localStorage.getItem('dcsmax-show-tips');
    return saved === null ? true : saved === 'true';
  });

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
                onClick={(e) => {
                  e.preventDefault();
                  window.dcsMax?.openExternal?.(link.url);
                }}
                className="flex items-center justify-between p-3 bg-slate-800/50 hover:bg-slate-700/50 rounded transition-colors"
              >
                <span className="text-slate-200">{link.label}</span>
                <ExternalLink className="w-4 h-4 text-blue-400" />
              </a>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default SettingsPanel;
