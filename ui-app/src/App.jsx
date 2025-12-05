import React, { useState, useEffect } from 'react';
import { 
  Settings, 
  Database, 
  Wrench, 
  Activity, 
  FileText, 
  AlertTriangle,
  CheckCircle,
  Shield,
  Download,
  Bug
} from 'lucide-react';
import Dashboard from './components/Dashboard';
import InstallSoftware from './components/InstallSoftware';
import BackupRestore from './components/BackupRestore';
import Optimization from './components/Optimization';
import Benchmarking from './components/Benchmarking';
import Logs from './components/Logs';
import SettingsPanel from './components/SettingsPanel';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isAdmin, setIsAdmin] = useState(false);
  const [systemInfo, setSystemInfo] = useState(null);

  useEffect(() => {
    // Check admin status
    window.dcsMax.isAdmin().then(result => {
      setIsAdmin(result.isAdmin);
    });

    // Get system info
    window.dcsMax.getSystemInfo().then(result => {
      if (result.success) {
        setSystemInfo(result.info);
      }
    });
  }, []);

  const tabs = [
    { id: 'dashboard', name: 'Dashboard', icon: Activity },
    { id: 'backup', name: 'Backup/Restore', icon: Database },
    { id: 'install', name: 'Install Required Soft', icon: Download },
    { id: 'benchmarking', name: 'Benchmarking', icon: Activity },
    { id: 'optimization', name: 'Optimization', icon: Wrench },
    { id: 'logs', name: 'Logs', icon: FileText },
    { id: 'settings', name: 'Settings', icon: Settings },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard systemInfo={systemInfo} isAdmin={isAdmin} onNavigate={setActiveTab} />;
      case 'install':
        return <InstallSoftware />;
      case 'backup':
        return <BackupRestore />;
      case 'optimization':
        return <Optimization isAdmin={isAdmin} />;
      case 'benchmarking':
        return <Benchmarking />;
      case 'logs':
        return <Logs />;
      case 'settings':
        return <SettingsPanel systemInfo={systemInfo} />;
      default:
        return <Dashboard systemInfo={systemInfo} isAdmin={isAdmin} />;
    }
  };

  return (
    <div className="flex h-screen bg-slate-900 text-slate-100">
      {/* Sidebar */}
      <div className="w-64 bg-slate-800 border-r border-slate-700 flex flex-col">
        {/* Header */}
        <div className="p-6 border-b border-slate-700">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-700 rounded-lg flex items-center justify-center">
              <Activity className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">DCS-Max</h1>
              <button 
                onClick={() => window.dcsMax?.openExternal?.('https://github.com/thomas-barrios/DCS-Max/blob/master/README.md')}
                className="text-xs text-slate-400 hover:text-blue-400 transition-colors cursor-pointer"
              >
                v1.2.1
              </button>
            </div>
          </div>
        </div>

        {/* Admin Warning */}
        {!isAdmin && (
          <div className="mx-4 mt-4 p-3 bg-warning-500/20 border border-warning-500/50 rounded-lg">
            <div className="flex items-start space-x-2">
              <AlertTriangle className="w-4 h-4 text-warning-500 flex-shrink-0 mt-0.5" />
              <div className="text-xs text-warning-200">
                Some features require administrator privileges
              </div>
            </div>
          </div>
        )}

        {isAdmin && (
          <div className="mx-4 mt-4 p-3 bg-success-500/20 border border-success-500/50 rounded-lg">
            <div className="flex items-start space-x-2">
              <Shield className="w-4 h-4 text-success-500 flex-shrink-0 mt-0.5" />
              <div className="text-xs text-success-200">
                Running with admin privileges
              </div>
            </div>
          </div>
        )}

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
                  activeTab === tab.id
                    ? 'bg-blue-600 text-white'
                    : 'text-slate-300 hover:bg-slate-700 hover:text-white'
                }`}
              >
                <Icon className="w-5 h-5" />
                <span className="font-medium">{tab.name}</span>
              </button>
            );
          })}
        </nav>

        {/* Report Issue Button */}
        <div className="px-4 pb-2">
          <button
            onClick={() => window.dcsMax?.openExternal?.('https://github.com/thomas-barrios/DCS-Max/issues')}
            className="w-full flex items-center space-x-3 px-4 py-3 rounded-lg text-slate-300 hover:bg-slate-700 hover:text-white transition-colors"
          >
            <Bug className="w-5 h-5" />
            <span className="font-medium">Report an Issue</span>
          </button>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-700">
          <div className="text-xs text-slate-400 space-y-1">
            <div>
              © 2025{' '}
              <a 
                href="https://forum.dcs.world/profile/61278-thomas-barrios/"
                onClick={(e) => {
                  e.preventDefault();
                  window.dcsMax?.openExternal?.('https://forum.dcs.world/profile/61278-thomas-barrios/');
                }}
                className="text-blue-400 hover:text-blue-300 hover:underline cursor-pointer"
              >
                HRP Wolf
              </a>
            </div>
            <div>MIT License</div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {renderContent()}
      </div>
    </div>
  );
}

export default App;
