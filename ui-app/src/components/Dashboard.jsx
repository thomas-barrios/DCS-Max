import React from 'react';
import { 
  Activity, 
  Database, 
  Wrench, 
  Zap, 
  TrendingUp,
  AlertCircle,
  CheckCircle2,
  Clock,
  Download,
  Settings
} from 'lucide-react';

function Dashboard({ systemInfo, isAdmin, onNavigate }) {
  const quickActions = [
    {
      title: 'Create System Backup',
      description: 'Backup DCS settings, services, and registry',
      icon: Database,
      action: 'backup',
      tab: 'backup',
      color: 'blue'
    },
    {
      title: 'Install Required Software',
      description: 'Install CapFrameX, AutoHotkey, and Notepad++ via winget',
      icon: Download,
      action: 'install',
      tab: 'install',
      color: 'cyan'
    },
    {
      title: 'Performance Testing',
      description: 'Configure and run DCS benchmarks',
      icon: Activity,
      action: 'benchmark',
      tab: 'performance',
      color: 'purple'
    },
    {
      title: 'Optimize System',
      description: 'Apply performance optimizations',
      icon: Wrench,
      action: 'optimize',
      tab: 'optimization',
      color: 'green',
      requiresAdmin: true
    },
    {
      title: 'View Logs',
      description: 'Check recent activity and errors',
      icon: AlertCircle,
      action: 'logs',
      tab: 'logs',
      color: 'yellow'
    },
    {
      title: 'Settings',
      description: 'Configure application paths and preferences',
      icon: Settings,
      action: 'settings',
      tab: 'settings',
      color: 'slate'
    }
  ];

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-8">
        {/* Header */}
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-white mb-2">
            Welcome to DCS-Max
          </h2>
          <p className="text-slate-400">
            The Ultimate DCS World Performance Optimization Suite
          </p>
        </div>

        {/* System Info Cards */}
        {systemInfo && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
            <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
              <div className="text-slate-400 text-sm mb-1">Operating System</div>
              <div className="text-white font-semibold">{systemInfo.OS}</div>
            </div>
            <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
              <div className="text-slate-400 text-sm mb-1">RAM</div>
              <div className="text-white font-semibold">{systemInfo.RAM} GB</div>
            </div>
            <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
              <div className="text-slate-400 text-sm mb-1">CPU</div>
              <div className="text-white font-semibold truncate" title={systemInfo.CPU}>
                {systemInfo.CPU}
              </div>
            </div>
            <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
              <div className="text-slate-400 text-sm mb-1">GPU</div>
              <div className="text-white font-semibold truncate" title={systemInfo.GPU}>
                {systemInfo.GPU}
              </div>
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="mb-8">
          <h3 className="text-xl font-bold text-white mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {quickActions.map((action) => {
              const Icon = action.icon;
              const isDisabled = action.requiresAdmin && !isAdmin;
              
              return (
                <button
                  key={action.action}
                  disabled={isDisabled}
                  onClick={() => !isDisabled && onNavigate && onNavigate(action.tab)}
                  className={`
                    relative bg-slate-800 rounded-lg p-6 border border-slate-700
                    hover:border-${action.color}-500 transition-all text-left
                    ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:shadow-lg cursor-pointer'}
                  `}
                >
                  <div className="flex items-start space-x-4">
                    <div className={`p-3 rounded-lg bg-${action.color}-500/20`}>
                      <Icon className={`w-6 h-6 text-${action.color}-400`} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-lg font-semibold text-white mb-1">
                        {action.title}
                      </h4>
                      <p className="text-slate-400 text-sm">
                        {action.description}
                      </p>
                      {isDisabled && (
                        <p className="text-warning-400 text-xs mt-2">
                          Requires administrator privileges
                        </p>
                      )}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Features Overview */}
        <div className="mb-8">
          <h3 className="text-xl font-bold text-white mb-4">Features</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
              <Zap className="w-8 h-8 text-yellow-400 mb-3" />
              <h4 className="text-lg font-semibold text-white mb-2">
                Performance Optimization
              </h4>
              <p className="text-slate-400 text-sm">
                Disable unnecessary Windows services and tasks that cause stutters and frame drops
              </p>
            </div>
            <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
              <Database className="w-8 h-8 text-blue-400 mb-3" />
              <h4 className="text-lg font-semibold text-white mb-2">
                Safe Backups
              </h4>
              <p className="text-slate-400 text-sm">
                Complete backup/restore for DCS configs, Windows tasks, services, and registry
              </p>
            </div>
            <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
              <TrendingUp className="w-8 h-8 text-green-400 mb-3" />
              <h4 className="text-lg font-semibold text-white mb-2">
                Automated Testing
              </h4>
              <p className="text-slate-400 text-sm">
                Test 128+ graphics settings combinations with CapFrameX integration
              </p>
            </div>
          </div>
        </div>

        {/* Getting Started */}
        <div className="bg-gradient-to-r from-blue-900/50 to-purple-900/50 rounded-lg p-6 border border-blue-700/50">
          <h3 className="text-xl font-bold text-white mb-4 flex items-center">
            <CheckCircle2 className="w-6 h-6 mr-2 text-green-400" />
            Getting Started
          </h3>
          <ol className="space-y-3 text-slate-300">
            <li className="flex items-start">
              <span className="font-bold text-blue-400 mr-3">1.</span>
              <span>Create a system restore point and backup your current settings</span>
            </li>
            <li className="flex items-start">
              <span className="font-bold text-blue-400 mr-3">2.</span>
              <span>Run a benchmark to measure current performance</span>
            </li>
            <li className="flex items-start">
              <span className="font-bold text-blue-400 mr-3">3.</span>
              <span>Review and apply optimization settings in the Optimization tab</span>
            </li>
            <li className="flex items-start">
              <span className="font-bold text-blue-400 mr-3">4.</span>
              <span>Run another benchmark to measure performance improvements</span>
            </li>
            <li className="flex items-start">
              <span className="font-bold text-blue-400 mr-3">5.</span>
              <span>Monitor logs for any issues or warnings</span>
            </li>
          </ol>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
