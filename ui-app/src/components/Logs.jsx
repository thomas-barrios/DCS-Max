import React, { useState, useEffect } from 'react';
import { 
  FileText, 
  RefreshCw, 
  Download,
  Search,
  Filter,
  AlertCircle,
  CheckCircle2,
  AlertTriangle,
  Info
} from 'lucide-react';

function Logs() {
  const [selectedLog, setSelectedLog] = useState('backup');
  const [logContent, setLogContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(false);
  const [filter, setFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');

  const logFiles = [
    { id: 'backup', name: 'Backup Log', path: 'Backups/_BackupLog.txt', icon: FileText },
    { id: 'benchmark', name: 'Benchmark Log', path: '4-Performance-Testing/4.1.2-dcs-testing-automation.log', icon: FileText },
  ];

  useEffect(() => {
    loadLog();
  }, [selectedLog]);

  useEffect(() => {
    if (autoRefresh) {
      const logFile = logFiles.find(l => l.id === selectedLog);
      window.dcsMax.watchLog(logFile.path);
      window.dcsMax.onLogUpdated((data) => {
        setLogContent(data.content);
      });

      return () => {
        window.dcsMax.stopWatchLog();
      };
    }
  }, [autoRefresh, selectedLog]);

  const loadLog = async () => {
    setLoading(true);
    const logFile = logFiles.find(l => l.id === selectedLog);
    const result = await window.dcsMax.readLog(logFile.path);
    
    if (result.success) {
      setLogContent(result.content);
    } else {
      setLogContent(`Error loading log: ${result.error}`);
    }
    setLoading(false);
  };

  const downloadLog = () => {
    const element = document.createElement('a');
    const file = new Blob([logContent], { type: 'text/plain' });
    element.href = URL.createObjectURL(file);
    element.download = `${selectedLog}-log-${new Date().toISOString().slice(0, 10)}.txt`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  const getFilteredContent = () => {
    let lines = logContent.split('\n');

    // Apply search filter
    if (searchTerm) {
      lines = lines.filter(line => 
        line.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    // Apply level filter
    if (filter !== 'all') {
      lines = lines.filter(line => {
        const lowerLine = line.toLowerCase();
        switch (filter) {
          case 'error':
            return lowerLine.includes('[error]') || lowerLine.includes('error:') || lowerLine.includes('failed');
          case 'warning':
            return lowerLine.includes('[warn]') || lowerLine.includes('warning:');
          case 'success':
            return lowerLine.includes('[ok]') || lowerLine.includes('success') || lowerLine.includes('completed');
          case 'info':
            return lowerLine.includes('[info]') || lowerLine.includes('info:');
          default:
            return true;
        }
      });
    }

    return lines.join('\n');
  };

  const highlightLine = (line) => {
    const lowerLine = line.toLowerCase();
    if (lowerLine.includes('[error]') || lowerLine.includes('error:') || lowerLine.includes('failed')) {
      return 'log-error';
    }
    if (lowerLine.includes('[warn]') || lowerLine.includes('warning:')) {
      return 'log-warning';
    }
    if (lowerLine.includes('[ok]') || lowerLine.includes('success') || lowerLine.includes('completed')) {
      return 'log-success';
    }
    if (lowerLine.includes('[info]') || lowerLine.includes('info:')) {
      return 'log-info';
    }
    return '';
  };

  const filteredContent = getFilteredContent();
  const lines = filteredContent.split('\n');

  return (
    <div className="flex-1 flex overflow-hidden">
      {/* Left Panel - Log Selection */}
      <div className="w-64 border-r border-slate-700 overflow-y-auto bg-slate-800">
        <div className="p-4">
          <h2 className="text-xl font-bold text-white mb-4">Log Files</h2>
          
          <div className="space-y-2">
            {logFiles.map((log) => {
              const Icon = log.icon;
              return (
                <button
                  key={log.id}
                  onClick={() => setSelectedLog(log.id)}
                  className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
                    selectedLog === log.id
                      ? 'bg-blue-600 text-white'
                      : 'text-slate-300 hover:bg-slate-700'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span className="text-sm font-medium">{log.name}</span>
                </button>
              );
            })}
          </div>

          {/* Filters */}
          <div className="mt-6">
            <h3 className="text-sm font-semibold text-slate-400 mb-3">Filter by Level</h3>
            <div className="space-y-2">
              {[
                { id: 'all', name: 'All', icon: FileText },
                { id: 'error', name: 'Errors', icon: AlertCircle },
                { id: 'warning', name: 'Warnings', icon: AlertTriangle },
                { id: 'success', name: 'Success', icon: CheckCircle2 },
                { id: 'info', name: 'Info', icon: Info }
              ].map((f) => {
                const Icon = f.icon;
                return (
                  <button
                    key={f.id}
                    onClick={() => setFilter(f.id)}
                    className={`w-full flex items-center space-x-2 px-3 py-2 rounded text-sm transition-colors ${
                      filter === f.id
                        ? 'bg-slate-700 text-white'
                        : 'text-slate-400 hover:bg-slate-700/50'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    <span>{f.name}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Auto-refresh toggle */}
          <div className="mt-6">
            <label className="flex items-center space-x-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoRefresh}
                onChange={(e) => setAutoRefresh(e.target.checked)}
                className="w-4 h-4 text-blue-600 bg-slate-700 border-slate-600 rounded focus:ring-blue-500"
              />
              <span className="text-sm text-slate-300">Auto-refresh</span>
            </label>
          </div>
        </div>
      </div>

      {/* Right Panel - Log Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Toolbar */}
        <div className="p-4 border-b border-slate-700 bg-slate-800">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-lg font-semibold text-white">
              {logFiles.find(l => l.id === selectedLog)?.name}
            </h3>
            <div className="flex items-center space-x-2">
              <button
                onClick={loadLog}
                disabled={loading}
                className="flex items-center space-x-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 rounded transition-colors text-sm"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                <span>Refresh</span>
              </button>
              <button
                onClick={downloadLog}
                className="flex items-center space-x-2 px-3 py-2 bg-green-600 hover:bg-green-700 rounded transition-colors text-sm"
              >
                <Download className="w-4 h-4" />
                <span>Download</span>
              </button>
            </div>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search logs..."
              className="w-full pl-10 pr-4 py-2 bg-slate-700 text-slate-200 rounded border border-slate-600 focus:border-blue-500 focus:outline-none text-sm"
            />
          </div>
        </div>

        {/* Log Content */}
        <div className="flex-1 overflow-y-auto p-4 bg-slate-950">
          {loading ? (
            <div className="flex items-center justify-center h-full">
              <RefreshCw className="w-8 h-8 text-blue-400 animate-spin" />
            </div>
          ) : filteredContent ? (
            <pre className="log-output">
              {lines.map((line, index) => (
                <div key={index} className={highlightLine(line)}>
                  {line}
                </div>
              ))}
            </pre>
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-slate-400">
              <FileText className="w-16 h-16 mb-4 opacity-50" />
              <p className="text-lg">No log content available</p>
              <p className="text-sm">The log file may be empty or not yet created</p>
            </div>
          )}
        </div>

        {/* Stats Footer */}
        <div className="p-3 border-t border-slate-700 bg-slate-800 flex items-center justify-between text-xs text-slate-400">
          <div>
            {lines.length} lines
            {searchTerm && ` (filtered from ${logContent.split('\n').length})`}
          </div>
          {autoRefresh && (
            <div className="flex items-center space-x-2 text-green-400">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span>Live</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Logs;
