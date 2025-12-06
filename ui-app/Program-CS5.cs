using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Win32;

namespace DcsMaxLauncher
{
    // Helper class for backup listing
    public class BackupInfo
    {
        public string name { get; set; }
        public string type { get; set; }
        public DateTime date { get; set; }
        public long size { get; set; }
    }

    public class MainForm : Form
    {
        private WebView2 webView;
        private string projectRoot;
        private Process currentScriptProcess;
        private FileSystemWatcher logWatcher;
        private string watchedLogPath;
        private Panel loadingPanel;
        private Label loadingLabel;
        private System.Windows.Forms.Timer spinnerTimer;
        private int spinnerFrame = 0;
        private static readonly string[] spinnerFrames = new string[] { "◐", "◓", "◑", "◒" };

        public MainForm()
        {
            try
            {
                InitializeForm();
                CreateLoadingUI();
                // Show form immediately with loading UI
                this.Show();
                Application.DoEvents();
                // Then start WebView2 initialization
                InitializeWebView();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Initialization Error: " + ex.ToString(), "DCS-Max Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void CreateLoadingUI()
        {
            // Create loading panel that shows immediately
            loadingPanel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = System.Drawing.Color.FromArgb(15, 23, 42) // slate-900
            };

            // App title
            var titleLabel = new Label
            {
                Text = "DCS-Max",
                ForeColor = System.Drawing.Color.White,
                Font = new System.Drawing.Font("Segoe UI", 24F, System.Drawing.FontStyle.Bold),
                AutoSize = true
            };

            // Loading text with spinner
            loadingLabel = new Label
            {
                Text = "◐ Loading...",
                ForeColor = System.Drawing.Color.FromArgb(148, 163, 184), // slate-400
                Font = new System.Drawing.Font("Segoe UI", 12F),
                AutoSize = true
            };

            // Center labels on resize
            loadingPanel.Resize += (s, e) =>
            {
                titleLabel.Left = (loadingPanel.Width - titleLabel.Width) / 2;
                titleLabel.Top = (loadingPanel.Height / 2) - titleLabel.Height - 10;
                loadingLabel.Left = (loadingPanel.Width - loadingLabel.Width) / 2;
                loadingLabel.Top = (loadingPanel.Height / 2) + 10;
            };

            loadingPanel.Controls.Add(titleLabel);
            loadingPanel.Controls.Add(loadingLabel);
            this.Controls.Add(loadingPanel);

            // Animate spinner
            spinnerTimer = new System.Windows.Forms.Timer();
            spinnerTimer.Interval = 150;
            spinnerTimer.Tick += (s, e) =>
            {
                spinnerFrame = (spinnerFrame + 1) % spinnerFrames.Length;
                loadingLabel.Text = spinnerFrames[spinnerFrame] + " Loading...";
            };
            spinnerTimer.Start();
        }

        private void InitializeForm()
        {
            this.Text = "DCS-Max";
            this.Width = 1400;
            this.Height = 900;
            this.MinimumSize = new System.Drawing.Size(1200, 700);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = System.Drawing.Color.FromArgb(15, 23, 42); // Match app background
            
            // Set icon if exists
            string iconPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "assets", "icon.ico");
            if (File.Exists(iconPath))
            {
                this.Icon = new System.Drawing.Icon(iconPath);
            }

            // Get project root (go up from the launcher location)
            // The exe is in ui-app\bin\, so we need to go up 2 levels to reach DCS-Max root
            projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", ".."));
            
            // Verify we found the right folder by checking for Backups directory
            if (!Directory.Exists(Path.Combine(projectRoot, "Backups")))
            {
                // Try going up 3 levels (for bin\Debug\net48 or similar)
                projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", ".."));
            }
            if (!Directory.Exists(Path.Combine(projectRoot, "Backups")))
            {
                // Try going up 4 levels
                projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", ".."));
            }
            if (!Directory.Exists(Path.Combine(projectRoot, "Backups")))
            {
                // Fallback: maybe running from project folder directly
                projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".."));
            }
        }

        private async void InitializeWebView()
        {
            try
            {
                webView = new WebView2();
                webView.Dock = DockStyle.Fill;
                webView.DefaultBackgroundColor = System.Drawing.Color.FromArgb(15, 23, 42);
                webView.Visible = false; // Hidden until ready
                this.Controls.Add(webView);

                // Initialize WebView2 with a custom user data folder
                string userDataFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "DCS-Max", "WebView2");
                var env = await CoreWebView2Environment.CreateAsync(null, userDataFolder);
                await webView.EnsureCoreWebView2Async(env);

                // Enable DevTools with F12
                webView.CoreWebView2.Settings.AreDevToolsEnabled = true;

                // Add host object for JavaScript communication
                webView.CoreWebView2.WebMessageReceived += WebView_WebMessageReceived;

                // Inject the bridge script BEFORE any page loads
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(GetBridgeScript());

                // Show WebView when navigation completes
                webView.CoreWebView2.NavigationCompleted += OnNavigationCompleted;

                // Find web folder
                string webPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "web");
                if (!Directory.Exists(webPath))
                {
                    webPath = Path.Combine(projectRoot, "ui-app", "dist");
                }

                if (Directory.Exists(webPath))
                {
                    webView.CoreWebView2.SetVirtualHostNameToFolderMapping(
                        "dcsmax.local",
                        webPath,
                        CoreWebView2HostResourceAccessKind.Allow);
                    
                    webView.CoreWebView2.Navigate("https://dcsmax.local/index.html");
                }
                else
                {
                    MessageBox.Show(string.Format("Web app not found!\nLooked in:\n{0}", webPath), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("WebView2 Error: " + ex.ToString(), "DCS-Max Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void OnNavigationCompleted(object sender, CoreWebView2NavigationCompletedEventArgs e)
        {
            // Small delay to ensure React has rendered
            Task.Delay(100).ContinueWith(t =>
            {
                this.BeginInvoke(new Action(() =>
                {
                    spinnerTimer.Stop();
                    loadingPanel.Visible = false;
                    webView.Visible = true;
                    webView.BringToFront();
                }));
            });
        }

        private string GetBridgeScript()
        {
            return @"
                window.dcsMax = {
                    _pendingRequests: {},
                    _requestId: 0,

                    _invoke: function(method, args) {
                        return new Promise((resolve, reject) => {
                            const id = ++this._requestId;
                            this._pendingRequests[id] = { resolve, reject };
                            window.chrome.webview.postMessage(JSON.stringify({
                                id: id,
                                method: method,
                                args: args || []
                            }));
                        });
                    },

                    // JSON Operations
                    readJsonConfig: function(jsonPath) {
                        return this._invoke('readJsonConfig', [jsonPath]);
                    },
                    writeJsonConfig: function(jsonPath, data) {
                        return this._invoke('writeJsonConfig', [jsonPath, JSON.stringify(data)]);
                    },

                    // INI Operations
                    readIniConfig: function(iniPath) {
                        return this._invoke('readIniConfig', [iniPath]);
                    },
                    writeIniConfig: function(iniPath, content) {
                        return this._invoke('writeIniConfig', [iniPath, content]);
                    },
                    
                    // Performance Optimizations Config (O&O ShutUp10-style format)
                    readOptimizationConfig: function() {
                        return this._invoke('readOptimizationConfig', []);
                    },
                    writeOptimizationConfig: function(config) {
                        return this._invoke('writeOptimizationConfig', [config]);
                    },
                    getOptimizationConfigPath: function() {
                        return this._invoke('getOptimizationConfigPath', []);
                    },

                    // Script Execution
                    executeScript: function(scriptPath, args) {
                        return this._invoke('executeScript', [scriptPath, args || []]);
                    },
                    executeScriptStream: function(scriptPath, args) {
                        this._invoke('executeScriptStream', [scriptPath, args || []]);
                    },
                    onScriptOutput: function(callback) {
                        this._scriptOutputCallback = callback;
                    },
                    onScriptComplete: function(callback) {
                        this._scriptCompleteCallback = callback;
                    },
                    stopScript: function() {
                        this._invoke('stopScript', []);
                    },

                    // Backup Operations
                    listBackups: function() {
                        return this._invoke('listBackups', []);
                    },
                    importRegistry: function(regFileName) {
                        return this._invoke('importRegistry', [regFileName]);
                    },

                    // Log Operations
                    readLog: function(logPath) {
                        return this._invoke('readLog', [logPath]);
                    },
                    watchLog: function(logPath) {
                        this._invoke('watchLog', [logPath]);
                    },
                    onLogUpdated: function(callback) {
                        this._logUpdatedCallback = callback;
                    },
                    stopWatchLog: function() {
                        this._invoke('stopWatchLog', []);
                    },

                    // System Operations
                    getSystemInfo: function() {
                        return this._invoke('getSystemInfo', []);
                    },
                    isAdmin: function() {
                        return this._invoke('isAdmin', []);
                    },
                    getProjectRoot: function() {
                        return this._invoke('getProjectRoot', []);
                    },
                    listDirectory: function(relativePath) {
                        return this._invoke('listDirectory', [relativePath]);
                    },
                    getServices: function() {
                        return this._invoke('getServices', []);
                    },
                    createRestorePoint: function(name) {
                        return this._invoke('createRestorePoint', [name]);
                    },
                    openFile: function(filePath) {
                        return this._invoke('openFile', [filePath]);
                    },
                    browseForFile: function(title, filter) {
                        return this._invoke('browseForFile', [title, filter]);
                    },
                    browseForFolder: function(title) {
                        return this._invoke('browseForFolder', [title]);
                    },

                    // Command Execution
                    executeCommand: function(command) {
                        return this._invoke('executeCommand', [command]);
                    },

                    // External Links
                    openExternal: function(url) {
                        return this._invoke('openExternal', [url]);
                    },

                    // Application Path Detection & Settings
                    detectPaths: function() {
                        return this._invoke('detectPaths', []);
                    },
                    readSettingsPaths: function() {
                        return this._invoke('readSettingsPaths', []);
                    },
                    writeSettingsPaths: function(paths) {
                        return this._invoke('writeSettingsPaths', [paths]);
                    },

                    // DCS Options.lua Operations
                    readOptionsLua: function(optionsLuaPath) {
                        return this._invoke('readOptionsLua', [optionsLuaPath]);
                    },

                    // Calibration Wizard Operations
                    launchVRSoftware: function(hardware, exePath) {
                        return this._invoke('launchVRSoftware', [hardware, exePath]);
                    },
                    launchDCSWithMission: function(dcsExePath, missionPath) {
                        return this._invoke('launchDCSWithMission', [dcsExePath, missionPath]);
                    },
                    sendMissionRestart: function() {
                        return this._invoke('sendMissionRestart', []);
                    },

                    // Remove listeners (no-op for compatibility)
                    removeAllListeners: function(channel) {}
                };

                window.chrome.webview.addEventListener('message', function(event) {
                    const data = JSON.parse(event.data);
                    
                    if (data.id && window.dcsMax._pendingRequests[data.id]) {
                        const { resolve, reject } = window.dcsMax._pendingRequests[data.id];
                        delete window.dcsMax._pendingRequests[data.id];
                        if (data.error) {
                            reject(data.error);
                        } else {
                            resolve(data.result);
                        }
                    } else if (data.event === 'scriptOutput' && window.dcsMax._scriptOutputCallback) {
                        window.dcsMax._scriptOutputCallback(data.data);
                    } else if (data.event === 'scriptComplete' && window.dcsMax._scriptCompleteCallback) {
                        window.dcsMax._scriptCompleteCallback(data.data);
                    } else if (data.event === 'logUpdated' && window.dcsMax._logUpdatedCallback) {
                        window.dcsMax._logUpdatedCallback(data.data);
                    }
                });

                console.log('DCS-Max WebView2 bridge initialized');
            ";
        }

        private async void WebView_WebMessageReceived(object sender, CoreWebView2WebMessageReceivedEventArgs e)
        {
            try
            {
                // Use TryGetWebMessageAsString for messages sent via postMessage(string)
                string jsonStr = e.TryGetWebMessageAsString();
                if (string.IsNullOrEmpty(jsonStr))
                {
                    // Fallback to WebMessageAsJson if not a string
                    jsonStr = e.WebMessageAsJson;
                    if (jsonStr.StartsWith("\"") && jsonStr.EndsWith("\""))
                    {
                        jsonStr = jsonStr.Substring(1, jsonStr.Length - 2);
                        jsonStr = jsonStr.Replace("\\\"", "\"").Replace("\\\\", "\\");
                    }
                }
                
                var message = JObject.Parse(jsonStr);
                var id = message["id"] != null ? message["id"].Value<int>() : 0;
                var method = message["method"] != null ? message["method"].Value<string>() : null;
                var args = message["args"] as JArray;
                if (args == null) args = new JArray();

                object result = null;

                switch (method)
                {
                    case "readJsonConfig":
                        result = await ReadJsonConfig(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "writeJsonConfig":
                        result = await WriteJsonConfig(
                            args[0] != null ? args[0].Value<string>() : null,
                            args[1] != null ? args[1].Value<string>() : null);
                        break;
                    case "readIniConfig":
                        result = await ReadIniConfig(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "writeIniConfig":
                        result = await WriteIniConfig(
                            args[0] != null ? args[0].Value<string>() : null, 
                            args[1] != null ? args[1].Value<string>() : null);
                        break;
                    case "readOptimizationConfig":
                        result = await ReadOptimizationConfig();
                        break;
                    case "writeOptimizationConfig":
                        result = await WriteOptimizationConfig(args[0] != null ? args[0].ToObject<Dictionary<string, bool>>() : null);
                        break;
                    case "getOptimizationConfigPath":
                        result = GetOptimizationConfigPath();
                        break;
                    case "executeScript":
                        var scriptArgs = args[1] != null ? args[1].ToObject<string[]>() : new string[0];
                        result = await ExecuteScript(args[0] != null ? args[0].Value<string>() : null, scriptArgs);
                        break;
                    case "executeScriptStream":
                        var streamArgs = args[1] != null ? args[1].ToObject<string[]>() : new string[0];
                        ExecuteScriptStream(args[0] != null ? args[0].Value<string>() : null, streamArgs);
                        return; // No response needed
                    case "stopScript":
                        StopScript();
                        return;
                    case "listBackups":
                        result = await ListBackups();
                        break;
                    case "importRegistry":
                        result = await ImportRegistry(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "readLog":
                        result = await ReadLog(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "getSystemInfo":
                        result = await GetSystemInfo();
                        break;
                    case "isAdmin":
                        result = IsAdmin();
                        break;
                    case "getProjectRoot":
                        result = new { success = true, path = projectRoot };
                        break;
                    case "listDirectory":
                        result = ListDirectory(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "getServices":
                        result = await GetServices();
                        break;
                    case "createRestorePoint":
                        result = await CreateRestorePoint(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "openFile":
                        result = OpenFile(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "browseForFile":
                        result = BrowseForFile(args[0] != null ? args[0].Value<string>() : null, args[1] != null ? args[1].Value<string>() : null);
                        break;
                    case "browseForFolder":
                        result = BrowseForFolder(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "executeCommand":
                        result = await ExecuteCommand(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "openExternal":
                        result = OpenExternal(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "detectPaths":
                        result = DetectApplicationPaths();
                        break;
                    case "readSettingsPaths":
                        result = await ReadSettingsPaths();
                        break;
                    case "writeSettingsPaths":
                        result = await WriteSettingsPaths(args[0] != null ? args[0].ToObject<Dictionary<string, string>>() : null);
                        break;
                    case "watchLog":
                        StartWatchingLog(args[0] != null ? args[0].Value<string>() : null);
                        return; // No response needed
                    case "stopWatchLog":
                        StopWatchingLog();
                        return; // No response needed
                    case "readOptionsLua":
                        result = await ReadOptionsLua(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "launchVRSoftware":
                        result = LaunchVRSoftware(
                            args[0] != null ? args[0].Value<string>() : null,
                            args[1] != null ? args[1].Value<string>() : null);
                        break;
                    case "launchDCSWithMission":
                        result = LaunchDCSWithMission(
                            args[0] != null ? args[0].Value<string>() : null,
                            args[1] != null ? args[1].Value<string>() : null);
                        break;
                    case "sendMissionRestart":
                        result = SendMissionRestart();
                        break;
                    default:
                        result = new { success = false, error = "Unknown method: " + method };
                        break;
                }

                SendResponse(id, result);
            }
            catch (Exception ex)
            {
                // Send error response back to JavaScript (also needs UI thread)
                SendResponse(0, new { success = false, error = "C# Exception: " + ex.Message });
            }
        }

        private void SendResponse(int id, object result)
        {
            var response = JsonConvert.SerializeObject(new { id = id, result = result });
            
            // Must post to UI thread since WebView2 requires it
            if (this.InvokeRequired)
            {
                this.BeginInvoke(new Action(() =>
                {
                    webView.CoreWebView2.PostWebMessageAsString(response);
                }));
            }
            else
            {
                webView.CoreWebView2.PostWebMessageAsString(response);
            }
        }

        private void SendEvent(string eventName, object data)
        {
            var eventMsg = JsonConvert.SerializeObject(new { @event = eventName, data = data });
            
            // Must post to UI thread since WebView2 requires it
            if (this.InvokeRequired)
            {
                this.BeginInvoke(new Action(() =>
                {
                    webView.CoreWebView2.PostWebMessageAsString(eventMsg);
                }));
            }
            else
            {
                webView.CoreWebView2.PostWebMessageAsString(eventMsg);
            }
        }

        // ========== API Methods ==========

        private async Task<object> ReadJsonConfig(string jsonPath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, jsonPath);
                if (!File.Exists(fullPath))
                {
                    return new { success = false, error = "File not found: " + jsonPath };
                }
                string content = await Task.Run(delegate { return File.ReadAllText(fullPath); });
                var data = JObject.Parse(content);
                return new { success = true, content = content, data = data };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> WriteJsonConfig(string jsonPath, string jsonContent)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, jsonPath);
                // Format JSON nicely
                var obj = JObject.Parse(jsonContent);
                string formatted = obj.ToString(Newtonsoft.Json.Formatting.Indented);
                await Task.Run(delegate { File.WriteAllText(fullPath, formatted); });
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> ReadIniConfig(string iniPath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, iniPath);
                System.Diagnostics.Debug.WriteLine("ReadIniConfig: fullPath = " + fullPath);
                System.Diagnostics.Debug.WriteLine("ReadIniConfig: File.Exists = " + File.Exists(fullPath));
                string content = await Task.Run(delegate { return File.ReadAllText(fullPath); });
                System.Diagnostics.Debug.WriteLine("ReadIniConfig: content length = " + content.Length);
                var parsed = ParseIni(content);
                System.Diagnostics.Debug.WriteLine("ReadIniConfig: parsed sections = " + string.Join(", ", parsed.Keys));
                if (parsed.ContainsKey("DCSOptionsTests"))
                {
                    System.Diagnostics.Debug.WriteLine("ReadIniConfig: DCSOptionsTests keys = " + string.Join(", ", parsed["DCSOptionsTests"].Keys));
                }
                return new { success = true, content = content, parsed = parsed };
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("ReadIniConfig: error = " + ex.Message);
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> WriteIniConfig(string iniPath, string content)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, iniPath);
                await Task.Run(delegate { File.WriteAllText(fullPath, content); });
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        // Read and parse DCS options.lua file to extract current settings
        private async Task<object> ReadOptionsLua(string optionsLuaPath)
        {
            try
            {
                // Expand environment variables in path
                string expandedPath = Environment.ExpandEnvironmentVariables(optionsLuaPath ?? "");
                
                if (string.IsNullOrEmpty(expandedPath))
                {
                    return new { success = false, error = "No options.lua path provided" };
                }
                
                if (!File.Exists(expandedPath))
                {
                    return new { success = false, error = "File not found: " + expandedPath };
                }
                
                string content = await Task.Run(delegate { return File.ReadAllText(expandedPath); });
                
                // Parse Lua settings into a dictionary
                var settings = new Dictionary<string, object>();
                
                // Match patterns like: ["settingName"] = value,
                var regex = new System.Text.RegularExpressions.Regex(
                    @"\[""([^""]+)""\]\s*=\s*([^,\r\n}]+)",
                    System.Text.RegularExpressions.RegexOptions.Multiline
                );
                
                var matches = regex.Matches(content);
                foreach (System.Text.RegularExpressions.Match match in matches)
                {
                    if (match.Groups.Count >= 3)
                    {
                        string key = match.Groups[1].Value.Trim();
                        string rawValue = match.Groups[2].Value.Trim();
                        
                        // Parse the value (handle strings, numbers, booleans)
                        object parsedValue = ParseLuaValue(rawValue);
                        settings[key] = parsedValue;
                    }
                }
                
                return new { 
                    success = true, 
                    path = expandedPath,
                    settings = settings 
                };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }
        
        private object ParseLuaValue(string rawValue)
        {
            // Remove trailing comma if present
            rawValue = rawValue.TrimEnd(',').Trim();
            
            // Check for quoted string
            if (rawValue.StartsWith("\"") && rawValue.EndsWith("\""))
            {
                return rawValue.Substring(1, rawValue.Length - 2);
            }
            
            // Check for boolean
            if (rawValue.Equals("true", StringComparison.OrdinalIgnoreCase))
                return true;
            if (rawValue.Equals("false", StringComparison.OrdinalIgnoreCase))
                return false;
            
            // Check for number (integer or float)
            double numValue;
            if (double.TryParse(rawValue, System.Globalization.NumberStyles.Any, 
                System.Globalization.CultureInfo.InvariantCulture, out numValue))
            {
                // Return as int if it's a whole number
                if (numValue == Math.Floor(numValue) && numValue >= int.MinValue && numValue <= int.MaxValue)
                    return (int)numValue;
                return numValue;
            }
            
            // Return as-is (could be a Lua expression or other type)
            return rawValue;
        }

        // ========== Performance Optimization Config Methods (O&O ShutUp10-style format) ==========
        
        private string GetOptimizationConfigFilePath()
        {
            return Path.Combine(projectRoot, "5-Optimization", "performance-optimizations.ini");
        }

        private object GetOptimizationConfigPath()
        {
            string configPath = GetOptimizationConfigFilePath();
            return new { 
                success = true, 
                path = configPath,
                exists = File.Exists(configPath)
            };
        }

        private async Task<object> ReadOptimizationConfig()
        {
            try
            {
                string configPath = GetOptimizationConfigFilePath();
                
                // If file doesn't exist, return empty config (all defaults to enabled)
                if (!File.Exists(configPath))
                {
                    return new { 
                        success = true, 
                        exists = false,
                        config = new Dictionary<string, bool>()
                    };
                }

                var config = await Task.Run(() => ParseOptimizationConfig(configPath));
                return new { 
                    success = true, 
                    exists = true,
                    config = config 
                };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private Dictionary<string, bool> ParseOptimizationConfig(string configPath)
        {
            var config = new Dictionary<string, bool>();
            var lines = File.ReadAllLines(configPath);

            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                
                // Skip empty lines and comments
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("#") || trimmed.StartsWith("="))
                    continue;

                // Parse O&O format: ID<whitespace>+/-<whitespace># Description
                // Example: R001	+	# CPU Core Parking: Disabled
                // Also matches: CAT_REGISTRY	+	# Registry Optimization category
                var match = System.Text.RegularExpressions.Regex.Match(trimmed, @"^([A-Z][A-Z0-9_]+)\s+([+-])\s+#");
                if (match.Success)
                {
                    string id = match.Groups[1].Value;
                    bool enabled = match.Groups[2].Value == "+";
                    config[id] = enabled;
                }
            }

            return config;
        }

        private async Task<object> WriteOptimizationConfig(Dictionary<string, bool> config)
        {
            try
            {
                string configPath = GetOptimizationConfigFilePath();
                
                // If file doesn't exist, we can't update it (need template first)
                if (!File.Exists(configPath))
                {
                    return new { success = false, error = "Config file not found. Run optimization once to create it." };
                }

                await Task.Run(() => UpdateOptimizationConfigFile(configPath, config));
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private void UpdateOptimizationConfigFile(string configPath, Dictionary<string, bool> config)
        {
            var lines = File.ReadAllLines(configPath);
            var updatedLines = new List<string>();
            var processedIds = new HashSet<string>();

            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                
                // Check if this line matches an optimization entry (including CAT_ entries)
                var match = System.Text.RegularExpressions.Regex.Match(trimmed, @"^([A-Z][A-Z0-9_]+)\s+([+-])\s+(#.*)$");
                if (match.Success)
                {
                    string id = match.Groups[1].Value;
                    string comment = match.Groups[3].Value;
                    processedIds.Add(id);
                    
                    // Use config value if provided, otherwise keep existing
                    bool enabled = config.ContainsKey(id) ? config[id] : (match.Groups[2].Value == "+");
                    string newState = enabled ? "+" : "-";
                    
                    updatedLines.Add(string.Format("{0}\t{1}\t{2}", id, newState, comment));
                }
                else
                {
                    // Keep non-matching lines as-is (comments, headers, etc.)
                    updatedLines.Add(line);
                }
            }

            // Add any CAT_ entries that aren't in the file yet
            var categoryIds = new Dictionary<string, string>
            {
                { "CAT_REGISTRY", "# Registry Optimization category enabled" },
                { "CAT_SERVICES", "# Windows Services category enabled" },
                { "CAT_TASKS", "# Scheduled Tasks category enabled" },
                { "CAT_CACHE", "# Cache Cleaning category enabled" }
            };

            // Find position to insert category entries (after the header comments)
            int insertPosition = 0;
            for (int i = 0; i < updatedLines.Count; i++)
            {
                if (updatedLines[i].StartsWith("# ==========") && updatedLines[i].Contains("REGISTRY"))
                {
                    insertPosition = i;
                    break;
                }
            }

            var newCatLines = new List<string>();
            foreach (var cat in categoryIds)
            {
                if (!processedIds.Contains(cat.Key) && config.ContainsKey(cat.Key))
                {
                    string state = config[cat.Key] ? "+" : "-";
                    newCatLines.Add(string.Format("{0}\t{1}\t{2}", cat.Key, state, cat.Value));
                }
            }

            if (newCatLines.Count > 0 && insertPosition > 0)
            {
                newCatLines.Insert(0, "");
                newCatLines.Insert(1, "# CATEGORY TOGGLES");
                newCatLines.Add("");
                updatedLines.InsertRange(insertPosition, newCatLines);
            }

            File.WriteAllLines(configPath, updatedLines, Encoding.UTF8);
        }

        private object OpenFile(string filePath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, filePath);
                if (!File.Exists(fullPath))
                {
                    return new { success = false, error = "File not found: " + fullPath };
                }
                
                Process.Start(new ProcessStartInfo
                {
                    FileName = fullPath,
                    UseShellExecute = true
                });
                
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object ListDirectory(string relativePath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, relativePath);
                if (!Directory.Exists(fullPath))
                {
                    return new { success = false, error = "Directory not found: " + fullPath };
                }
                
                var files = Directory.GetFiles(fullPath)
                    .Select(f => Path.GetFileName(f))
                    .ToArray();
                
                var directories = Directory.GetDirectories(fullPath)
                    .Select(d => Path.GetFileName(d))
                    .ToArray();
                
                return new { success = true, files = files, directories = directories };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> ExecuteCommand(string command)
        {
            try
            {
                return await Task.Run(() =>
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -Command \"{0}\"", command.Replace("\"", "\\\"")),
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        CreateNoWindow = true
                    };

                    using (var process = Process.Start(psi))
                    {
                        string stdout = process.StandardOutput.ReadToEnd();
                        string stderr = process.StandardError.ReadToEnd();
                        process.WaitForExit();

                        return new
                        {
                            success = process.ExitCode == 0,
                            exitCode = process.ExitCode,
                            stdout = stdout,
                            stderr = stderr
                        };
                    }
                });
            }
            catch (Exception ex)
            {
                return new { success = false, exitCode = -1, stdout = "", stderr = ex.Message };
            }
        }

        private object OpenExternal(string url)
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = url,
                    UseShellExecute = true
                });
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object LaunchVRSoftware(string hardware, string exePath)
        {
            try
            {
                if (string.IsNullOrEmpty(exePath))
                {
                    return new { success = false, error = "VR software path not specified" };
                }

                // Expand environment variables
                exePath = Environment.ExpandEnvironmentVariables(exePath);

                if (!File.Exists(exePath))
                {
                    return new { success = false, error = "VR software not found: " + exePath };
                }

                // Check if already running based on hardware type
                string processName = "";
                if (hardware == "Pimax")
                {
                    processName = "PimaxClient";
                }
                else if (hardware == "SteamVR")
                {
                    processName = "vrserver";
                }

                if (!string.IsNullOrEmpty(processName))
                {
                    var existing = Process.GetProcessesByName(processName);
                    if (existing.Length > 0)
                    {
                        return new { success = true, alreadyRunning = true, message = hardware + " already running" };
                    }
                }

                Process.Start(new ProcessStartInfo
                {
                    FileName = exePath,
                    UseShellExecute = true
                });
                return new { success = true, alreadyRunning = false };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object LaunchDCSWithMission(string dcsExePath, string missionPath)
        {
            try
            {
                if (string.IsNullOrEmpty(dcsExePath))
                {
                    return new { success = false, error = "DCS path not specified" };
                }

                // Expand environment variables
                dcsExePath = Environment.ExpandEnvironmentVariables(dcsExePath);
                if (!string.IsNullOrEmpty(missionPath))
                {
                    missionPath = Environment.ExpandEnvironmentVariables(missionPath);
                }

                if (!File.Exists(dcsExePath))
                {
                    return new { success = false, error = "DCS not found: " + dcsExePath };
                }

                // Check if DCS is already running
                var existing = Process.GetProcessesByName("DCS");
                if (existing.Length > 0)
                {
                    return new { success = true, alreadyRunning = true, message = "DCS already running" };
                }

                string arguments = "";
                if (!string.IsNullOrEmpty(missionPath))
                {
                    arguments = string.Format("--mission \"{0}\"", missionPath);
                }

                Process.Start(new ProcessStartInfo
                {
                    FileName = dcsExePath,
                    Arguments = arguments,
                    UseShellExecute = true
                });
                return new { success = true, alreadyRunning = false };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object SendMissionRestart()
        {
            try
            {
                // Find DCS window
                var dcsProcess = Process.GetProcessesByName("DCS").FirstOrDefault();
                if (dcsProcess == null)
                {
                    return new { success = false, error = "DCS is not running" };
                }

                IntPtr hwnd = dcsProcess.MainWindowHandle;
                if (hwnd == IntPtr.Zero)
                {
                    return new { success = false, error = "Could not find DCS window" };
                }

                // Use AutoHotkey to send Shift+R - most reliable for games
                // Create a temporary AHK script
                string tempScript = Path.Combine(Path.GetTempPath(), "dcs_restart.ahk");
                string ahkScript = @"
#Requires AutoHotkey v2.0
#SingleInstance Force

; Wait a moment for this script to start
Sleep 200

; Activate DCS window
if WinExist(""ahk_exe DCS.exe"") {
    WinActivate
    WinWaitActive ""ahk_exe DCS.exe"",, 2
    Sleep 300
    
    ; Send Shift+R
    Send ""+r""
}

ExitApp
";
                File.WriteAllText(tempScript, ahkScript);

                // Find AutoHotkey
                string ahkPath = @"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe";
                if (!File.Exists(ahkPath))
                {
                    ahkPath = @"C:\Program Files\AutoHotkey\AutoHotkey.exe";
                }
                if (!File.Exists(ahkPath))
                {
                    // Try to find via registry or common paths
                    string[] possiblePaths = new string[]
                    {
                        @"C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe",
                        @"C:\Program Files (x86)\AutoHotkey\AutoHotkey.exe",
                        Environment.ExpandEnvironmentVariables(@"%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe")
                    };
                    foreach (var path in possiblePaths)
                    {
                        if (File.Exists(path))
                        {
                            ahkPath = path;
                            break;
                        }
                    }
                }

                if (!File.Exists(ahkPath))
                {
                    // Fallback: delete temp file and return error
                    try { File.Delete(tempScript); } catch { }
                    return new { success = false, error = "AutoHotkey not found. Please install AutoHotkey v2." };
                }

                var psi = new ProcessStartInfo
                {
                    FileName = ahkPath,
                    Arguments = "\"" + tempScript + "\"",
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var process = Process.Start(psi))
                {
                    process.WaitForExit(5000);
                }

                // Clean up temp file
                try { File.Delete(tempScript); } catch { }

                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        // Window management imports
        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool BringWindowToTop(IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool IsIconic(IntPtr hWnd);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr lpdwProcessId);

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

        [System.Runtime.InteropServices.DllImport("kernel32.dll")]
        private static extern uint GetCurrentThreadId();

        private const int SW_RESTORE = 9;

        private Dictionary<string, Dictionary<string, string>> ParseIni(string content)
        {
            var result = new Dictionary<string, Dictionary<string, string>>();
            string currentSection = "";
            
            foreach (var line in content.Split('\n'))
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith(";") || trimmed.StartsWith("#"))
                    continue;

                if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
                {
                    currentSection = trimmed.Substring(1, trimmed.Length - 2);
                    if (!result.ContainsKey(currentSection))
                        result[currentSection] = new Dictionary<string, string>();
                }
                else if (trimmed.Contains("="))
                {
                    var parts = trimmed.Split(new[] { '=' }, 2);
                    if (parts.Length == 2 && !string.IsNullOrEmpty(currentSection))
                    {
                        result[currentSection][parts[0].Trim()] = parts[1].Trim();
                    }
                }
            }
            return result;
        }

        private async Task<object> ExecuteScript(string scriptPath, string[] args)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, scriptPath);
                var result = await Task.Run(delegate { return RunPowerShell(fullPath, args); });
                return result;
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message, stdout = "", stderr = "" };
            }
        }

        private object RunPowerShell(string scriptPath, string[] args)
        {
            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -File \"{0}\" {1}", scriptPath, string.Join(" ", args)),
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                WorkingDirectory = Path.GetDirectoryName(scriptPath)
            };

            using (var process = Process.Start(psi))
            {
                string stdout = process.StandardOutput.ReadToEnd();
                string stderr = process.StandardError.ReadToEnd();
                process.WaitForExit();

                return new
                {
                    success = process.ExitCode == 0,
                    code = process.ExitCode,
                    stdout = stdout,
                    stderr = stderr
                };
            }
        }

        private string FindAutoHotkey()
        {
            // Check common AutoHotkey v2 installation paths
            string[] paths = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "v2", "AutoHotkey64.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "v2", "AutoHotkey.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "AutoHotkey", "v2", "AutoHotkey.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "AutoHotkey", "v2", "AutoHotkey.exe")
            };
            
            foreach (string path in paths)
            {
                if (File.Exists(path))
                {
                    return path;
                }
            }
            
            // Fallback to PATH
            return "AutoHotkey.exe";
        }

        private void ExecuteScriptStream(string scriptPath, string[] args)
        {
            string fullPath = Path.Combine(projectRoot, scriptPath);
            string extension = Path.GetExtension(fullPath).ToLowerInvariant();
            
            Task.Run(delegate
            {
                try
                {
                    ProcessStartInfo psi;
                    
                    if (extension == ".reg")
                    {
                        // Registry files need to be imported using reg.exe
                        psi = new ProcessStartInfo
                        {
                            FileName = "reg.exe",
                            Arguments = string.Format("import \"{0}\"", fullPath),
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            CreateNoWindow = true,
                            WorkingDirectory = Path.GetDirectoryName(fullPath)
                        };
                    }
                    else if (extension == ".ahk")
                    {
                        // AutoHotkey v2 scripts - find the executable
                        string ahkPath = FindAutoHotkey();
                        this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stdout", data = "Using AutoHotkey: " + ahkPath + "\n" }); }));
                        this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stdout", data = "Script: " + fullPath + "\n" }); }));
                        
                        if (!File.Exists(fullPath))
                        {
                            this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stderr", data = "ERROR: Script file not found: " + fullPath + "\n" }); }));
                            this.BeginInvoke(new Action(delegate { SendEvent("scriptComplete", new { code = 1, stdout = "", stderr = "Script not found" }); }));
                            return;
                        }
                        
                        // Pass arguments directly (caller controls --headless flag)
                        string allArgs = string.Join(" ", args).Trim();
                        psi = new ProcessStartInfo
                        {
                            FileName = ahkPath,
                            Arguments = string.Format("\"{0}\" {1}", fullPath, allArgs),
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            CreateNoWindow = true,
                            WorkingDirectory = Path.GetDirectoryName(fullPath)
                        };
                    }
                else if (extension == ".bat" || extension == ".cmd")
                {
                    // Batch files
                    psi = new ProcessStartInfo
                    {
                        FileName = "cmd.exe",
                        Arguments = string.Format("/c \"{0}\" {1}", fullPath, string.Join(" ", args)),
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        CreateNoWindow = true,
                        WorkingDirectory = Path.GetDirectoryName(fullPath)
                    };
                }
                else
                {
                    // Default: PowerShell scripts (.ps1)
                    psi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -File \"{0}\" {1}", fullPath, string.Join(" ", args)),
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        CreateNoWindow = true,
                        WorkingDirectory = Path.GetDirectoryName(fullPath)
                    };
                }

                currentScriptProcess = Process.Start(psi);
                var stdout = new StringBuilder();
                var stderr = new StringBuilder();

                currentScriptProcess.OutputDataReceived += delegate(object s, DataReceivedEventArgs evt)
                {
                    if (evt.Data != null)
                    {
                        stdout.AppendLine(evt.Data);
                        this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stdout", data = evt.Data + "\n" }); }));
                    }
                };

                currentScriptProcess.ErrorDataReceived += delegate(object s, DataReceivedEventArgs evt)
                {
                    if (evt.Data != null)
                    {
                        stderr.AppendLine(evt.Data);
                        this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stderr", data = evt.Data + "\n" }); }));
                    }
                };

                currentScriptProcess.BeginOutputReadLine();
                currentScriptProcess.BeginErrorReadLine();
                currentScriptProcess.WaitForExit();

                int exitCode = currentScriptProcess.ExitCode;
                currentScriptProcess = null;

                this.BeginInvoke(new Action(delegate { SendEvent("scriptComplete", new { code = exitCode, stdout = stdout.ToString(), stderr = stderr.ToString() }); }));
                }
                catch (Exception ex)
                {
                    this.BeginInvoke(new Action(delegate { SendEvent("scriptOutput", new { type = "stderr", data = "ERROR: " + ex.Message + "\n" }); }));
                    this.BeginInvoke(new Action(delegate { SendEvent("scriptComplete", new { code = -1, stdout = "", stderr = ex.Message }); }));
                }
            });
        }

        private void StopScript()
        {
            if (currentScriptProcess != null && !currentScriptProcess.HasExited)
            {
                currentScriptProcess.Kill();
                currentScriptProcess = null;
            }
        }

        private void StartWatchingLog(string logPath)
        {
            // Stop any existing watcher
            StopWatchingLog();
            
            string fullPath = Path.Combine(projectRoot, logPath);
            watchedLogPath = fullPath;
            
            // Read existing content first
            SendLogContent();
            
            // Set up file system watcher
            string directory = Path.GetDirectoryName(fullPath);
            string filename = Path.GetFileName(fullPath);
            
            logWatcher = new FileSystemWatcher(directory, filename);
            logWatcher.NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size;
            logWatcher.Changed += OnLogFileChanged;
            logWatcher.EnableRaisingEvents = true;
        }

        private void SendLogContent()
        {
            try
            {
                if (File.Exists(watchedLogPath))
                {
                    // Read entire file with sharing enabled
                    string content;
                    using (var fs = new FileStream(watchedLogPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (var reader = new StreamReader(fs))
                    {
                        content = reader.ReadToEnd();
                    }
                    
                    if (!string.IsNullOrEmpty(content))
                    {
                        this.BeginInvoke(new Action(delegate { SendEvent("logUpdated", new { content = content }); }));
                    }
                }
            }
            catch { }
        }

        private void OnLogFileChanged(object sender, FileSystemEventArgs e)
        {
            // Small delay to ensure file is written
            System.Threading.Thread.Sleep(100);
            SendLogContent();
        }

        private void StopWatchingLog()
        {
            if (logWatcher != null)
            {
                logWatcher.EnableRaisingEvents = false;
                logWatcher.Changed -= OnLogFileChanged;
                logWatcher.Dispose();
                logWatcher = null;
            }
            watchedLogPath = null;
        }

        private async Task<object> ListBackups()
        {
            try
            {
                string backupsDir = Path.Combine(projectRoot, "Backups");
                var backups = new List<BackupInfo>();

                if (!Directory.Exists(backupsDir))
                {
                    return new { success = true, backups = backups };
                }

                await Task.Run(delegate
                {
                    foreach (var entry in Directory.GetFileSystemEntries(backupsDir))
                    {
                        var name = Path.GetFileName(entry);
                        if (name.StartsWith("_")) continue;

                        var info = new FileInfo(entry);
                        var isDir = Directory.Exists(entry);

                        string backupType = "Unknown";
                        if (isDir)
                        {
                            backupType = "DCS Settings";
                        }
                        else if (name.EndsWith("-services-backup.json"))
                        {
                            backupType = "Windows Services";
                        }
                        else if (name.EndsWith("-tasks-backup.xml"))
                        {
                            backupType = "Scheduled Tasks";
                        }
                        else if (name.EndsWith("-registry-backup.reg"))
                        {
                            backupType = "Registry Keys";
                        }
                        else
                        {
                            continue;
                        }

                        backups.Add(new BackupInfo
                        {
                            name = name,
                            type = backupType,
                            date = info.LastWriteTime,
                            size = isDir ? 0 : info.Length
                        });
                    }
                });

                return new { success = true, backups = backups.OrderByDescending(b => b.date).ToList() };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> ImportRegistry(string regFileName)
        {
            try
            {
                string regFilePath = Path.Combine(projectRoot, "Backups", regFileName);
                
                if (!File.Exists(regFilePath))
                {
                    return new { success = false, error = "Registry file not found: " + regFilePath };
                }

                return await Task.Run(delegate
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = "regedit.exe",
                        Arguments = string.Format("/s \"{0}\"", regFilePath),
                        UseShellExecute = true,
                        Verb = "runas"
                    };

                    using (var process = Process.Start(psi))
                    {
                        process.WaitForExit();
                        return new { success = process.ExitCode == 0, file = regFilePath };
                    }
                });
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> ReadLog(string logPath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, logPath);
                
                // Create log file if it doesn't exist
                if (!File.Exists(fullPath))
                {
                    string directory = Path.GetDirectoryName(fullPath);
                    if (!Directory.Exists(directory))
                    {
                        Directory.CreateDirectory(directory);
                    }
                    File.WriteAllText(fullPath, "");
                }
                
                string content = await Task.Run(delegate { return File.ReadAllText(fullPath); });
                return new { success = true, content = content };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> GetSystemInfo()
        {
            try
            {
                return await Task.Run(new Func<object>(delegate
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"" +
                            "$ErrorActionPreference = 'SilentlyContinue'; " +
                            "$os = (Get-CimInstance Win32_OperatingSystem).Caption; " +
                            "$ram = [Math]::Ceiling((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB); " +
                            "$cpu = (Get-CimInstance Win32_Processor).Name; " +
                            "$gpus = Get-CimInstance Win32_VideoController; " +
                            "$gpu = ($gpus | Where-Object { $_.Name -match 'NVIDIA|AMD|Radeon|GeForce|RTX|GTX' } | Select-Object -First 1).Name; " +
                            "if (-not $gpu) { $gpu = ($gpus | Where-Object { $_.Name -notmatch 'Microsoft|Basic|DisplayLink|Virtual|Remote' } | Select-Object -First 1).Name }; " +
                            "if (-not $gpu) { $gpu = ($gpus | Select-Object -First 1).Name }; " +
                            "$dcsPath = Join-Path $env:USERPROFILE 'Saved Games\\DCS'; " +
                            "@{ OS = if ($os) { $os } else { 'Unknown' }; RAM = if ($ram) { $ram } else { 0 }; CPU = if ($cpu) { $cpu } else { 'Unknown' }; GPU = if ($gpu) { $gpu } else { 'Unknown' }; DCSPath = $dcsPath } | ConvertTo-Json -Compress\"",
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        CreateNoWindow = true
                    };

                    using (var process = Process.Start(psi))
                    {
                        string output = process.StandardOutput.ReadToEnd();
                        process.WaitForExit();

                        try
                        {
                            var info = JsonConvert.DeserializeObject<JObject>(output.Trim());
                            return new { success = true, info = info };
                        }
                        catch
                        {
                            return new { success = true, info = new { OS = "Unknown", RAM = 0, CPU = "Unknown", GPU = "Unknown", DCSPath = "" } };
                        }
                    }
                }));
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object IsAdmin()
        {
            try
            {
                var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
                var principal = new System.Security.Principal.WindowsPrincipal(identity);
                bool isAdmin = principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
                return new { success = true, isAdmin = isAdmin };
            }
            catch
            {
                return new { success = false, isAdmin = false };
            }
        }

        private async Task<object> GetServices()
        {
            try
            {
                return await Task.Run(delegate
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"Get-Service | Select-Object Name, DisplayName, Status, StartType | ConvertTo-Json\"",
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        CreateNoWindow = true
                    };

                    using (var process = Process.Start(psi))
                    {
                        string output = process.StandardOutput.ReadToEnd();
                        process.WaitForExit();

                        try
                        {
                            var services = JsonConvert.DeserializeObject<JArray>(output.Trim());
                            return new { success = true, services = services };
                        }
                        catch
                        {
                            return new { success = true, services = new JArray() };
                        }
                    }
                });
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private async Task<object> CreateRestorePoint(string name)
        {
            try
            {
                string restorePointName = name;
                if (string.IsNullOrEmpty(restorePointName))
                {
                    restorePointName = "DCS-Max_Backup_" + DateTime.Now.ToString("yyyy-MM-dd-HH-mm-ss");
                }

                string rpName = restorePointName; // Capture for closure
                return await Task.Run(new Func<object>(delegate
                {
                    var psi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -Command \"Checkpoint-Computer -Description '{0}' -RestorePointType 'MODIFY_SETTINGS'\"", rpName),
                        UseShellExecute = false,
                        RedirectStandardError = true,
                        CreateNoWindow = true
                    };

                    using (var process = Process.Start(psi))
                    {
                        string stderr = process.StandardError.ReadToEnd();
                        process.WaitForExit();

                        if (process.ExitCode == 0)
                        {
                            return new { success = true, name = rpName };
                        }
                        else if (stderr.Contains("1058") || stderr.Contains("frequency"))
                        {
                            return new { success = false, error = "Windows limits restore point creation to once per 24 hours." };
                        }
                        else
                        {
                            return new { success = false, error = stderr };
                        }
                    }
                }));
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        // ========== Application Path Detection ==========

        private object DetectApplicationPaths()
        {
            try
            {
                var paths = new Dictionary<string, object>();
                
                // DCS World Executable
                paths["dcsPath"] = DetectDcsPath();
                
                // DCS Saved Games Folder
                paths["savedGamesPath"] = DetectDcsSavedGamesPath();
                
                // CapFrameX
                paths["capframexPath"] = DetectCapFrameXPath();
                
                // AutoHotkey v2
                paths["autoHotkeyPath"] = DetectAutoHotkeyPath();
                
                // Pimax Client
                paths["pimaxPath"] = DetectPimaxPath();
                
                // Notepad++
                paths["notepadppPath"] = DetectNotepadPPPath();
                
                return new { success = true, paths = paths };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object DetectDcsPath()
        {
            // Try registry first (Steam and standalone installations)
            string[] registryPaths = new string[]
            {
                @"SOFTWARE\Eagle Dynamics\DCS World",
                @"SOFTWARE\Eagle Dynamics\DCS World OpenBeta",
                @"SOFTWARE\WOW6432Node\Eagle Dynamics\DCS World",
                @"SOFTWARE\WOW6432Node\Eagle Dynamics\DCS World OpenBeta"
            };

            foreach (string regPath in registryPaths)
            {
                try
                {
                    using (RegistryKey key = Registry.LocalMachine.OpenSubKey(regPath))
                    {
                        if (key != null)
                        {
                            object pathValue = key.GetValue("Path");
                            if (pathValue != null)
                            {
                                string dcsRoot = pathValue.ToString();
                                string exePath = Path.Combine(dcsRoot, "bin", "DCS.exe");
                                if (File.Exists(exePath))
                                {
                                    return new { found = true, path = exePath, source = "registry" };
                                }
                            }
                        }
                    }
                }
                catch { }
            }

            // Check common installation paths
            string[] commonPaths = new string[]
            {
                @"C:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe",
                @"C:\Program Files\Eagle Dynamics\DCS World OpenBeta\bin\DCS.exe",
                @"D:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe",
                @"D:\Program Files\Eagle Dynamics\DCS World OpenBeta\bin\DCS.exe",
                @"E:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe",
                @"D:\Games\DCS World\bin\DCS.exe",
                @"E:\Games\DCS World\bin\DCS.exe"
            };

            foreach (string path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            return new { found = false, path = @"C:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe", source = "default" };
        }

        private object DetectDcsSavedGamesPath()
        {
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            
            // Check for DCS and DCS.openbeta folders
            string[] possiblePaths = new string[]
            {
                Path.Combine(userProfile, "Saved Games", "DCS"),
                Path.Combine(userProfile, "Saved Games", "DCS.openbeta")
            };

            foreach (string path in possiblePaths)
            {
                if (Directory.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            // Return default path even if not found
            return new { found = false, path = Path.Combine(userProfile, "Saved Games", "DCS"), source = "default" };
        }

        private object DetectCapFrameXPath()
        {
            // Try registry first (winget/installer registrations)
            try
            {
                string[] registryPaths = new string[]
                {
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{F0A3FF6B-0A2A-4BB6-B3B2-7E8C9A8E0001}_is1",
                    @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{F0A3FF6B-0A2A-4BB6-B3B2-7E8C9A8E0001}_is1",
                    @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\CapFrameX",
                    @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\CapFrameX"
                };

                foreach (string regPath in registryPaths)
                {
                    using (RegistryKey key = Registry.LocalMachine.OpenSubKey(regPath))
                    {
                        if (key != null)
                        {
                            object installLocation = key.GetValue("InstallLocation");
                            if (installLocation != null)
                            {
                                string exePath = Path.Combine(installLocation.ToString(), "CapFrameX.exe");
                                if (File.Exists(exePath))
                                {
                                    return new { found = true, path = exePath, source = "registry" };
                                }
                            }
                        }
                    }
                }
            }
            catch { }

            // Check common installation paths
            string[] commonPaths = new string[]
            {
                @"C:\Program Files (x86)\CapFrameX\CapFrameX.exe",
                @"C:\Program Files\CapFrameX\CapFrameX.exe",
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CapFrameX", "CapFrameX.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "CapFrameX", "CapFrameX.exe"),
                // Winget often installs here
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "CXWorld", "CapFrameX", "CapFrameX.exe")
            };

            foreach (string path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            return new { found = false, path = @"C:\Program Files (x86)\CapFrameX\CapFrameX.exe", source = "default" };
        }

        private object DetectAutoHotkeyPath()
        {
            // Try registry first
            try
            {
                string[] registryPaths = new string[]
                {
                    @"SOFTWARE\AutoHotkey",
                    @"SOFTWARE\WOW6432Node\AutoHotkey"
                };

                foreach (string regPath in registryPaths)
                {
                    using (RegistryKey key = Registry.LocalMachine.OpenSubKey(regPath))
                    {
                        if (key != null)
                        {
                            object installDir = key.GetValue("InstallDir");
                            if (installDir != null)
                            {
                                // Check for v2 first, then v1
                                string v2Path = Path.Combine(installDir.ToString(), "v2", "AutoHotkey64.exe");
                                if (File.Exists(v2Path))
                                {
                                    return new { found = true, path = v2Path, source = "registry" };
                                }
                                v2Path = Path.Combine(installDir.ToString(), "v2", "AutoHotkey.exe");
                                if (File.Exists(v2Path))
                                {
                                    return new { found = true, path = v2Path, source = "registry" };
                                }
                            }
                        }
                    }
                }
            }
            catch { }

            // Check common installation paths
            string[] commonPaths = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "v2", "AutoHotkey64.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "v2", "AutoHotkey.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "AutoHotkey", "v2", "AutoHotkey.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "AutoHotkey", "v2", "AutoHotkey.exe"),
                // Standalone AutoHotkey v2 installation
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "AutoHotkey64.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "AutoHotkey.exe"),
                // User installation paths
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AutoHotkey", "v2", "AutoHotkey64.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AutoHotkey", "v2", "AutoHotkey.exe")
            };

            foreach (string path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            return new { found = false, path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "AutoHotkey", "v2", "AutoHotkey.exe"), source = "default" };
        }

        private object DetectPimaxPath()
        {
            string[] commonPaths = new string[]
            {
                @"C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe",
                @"C:\Program Files (x86)\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
            };

            foreach (string path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            return new { found = false, path = @"C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe", source = "default" };
        }

        private object DetectNotepadPPPath()
        {
            // Try registry first
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Notepad++"))
                {
                    if (key != null)
                    {
                        object pathValue = key.GetValue("");
                        if (pathValue != null)
                        {
                            string exePath = Path.Combine(pathValue.ToString(), "notepad++.exe");
                            if (File.Exists(exePath))
                            {
                                return new { found = true, path = exePath, source = "registry" };
                            }
                        }
                    }
                }
            }
            catch { }

            string[] commonPaths = new string[]
            {
                @"C:\Program Files\Notepad++\notepad++.exe",
                @"C:\Program Files (x86)\Notepad++\notepad++.exe"
            };

            foreach (string path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return new { found = true, path = path, source = "filesystem" };
                }
            }

            return new { found = false, path = @"C:\Program Files\Notepad++\notepad++.exe", source = "default" };
        }

        // ========== Settings INI Read/Write ==========

        private string GetSettingsIniPath()
        {
            // Legacy INI path (deprecated - no longer used)
            // Config now uses testing-configuration.json instead
            return Path.Combine(projectRoot, "4-Performance-Testing", "4.1.1-dcs-testing-configuration.ini");
        }

        private async Task<object> ReadSettingsPaths()
        {
            try
            {
                string iniPath = GetSettingsIniPath();
                if (!File.Exists(iniPath))
                {
                    return new { success = false, error = "INI file not found", paths = new Dictionary<string, string>() };
                }

                var paths = await Task.Run(() => ParsePathsFromIni(iniPath));
                return new { success = true, paths = paths };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private Dictionary<string, string> ParsePathsFromIni(string iniPath)
        {
            var paths = new Dictionary<string, string>();
            string content = File.ReadAllText(iniPath);
            
            // Map INI keys to settings keys
            var keyMapping = new Dictionary<string, string>
            {
                { "dcsExe", "dcsPath" },
                { "optionsLua", "savedGamesPath" }, // Will extract folder from this
                { "capframex", "capframexPath" },
                { "autohotkey", "autoHotkeyPath" },
                { "pimax", "pimaxPath" },
                { "notepadpp", "notepadppPath" },
                { "mission", "benchmarkMissionPath" }
            };

            string currentSection = "";
            foreach (var line in content.Split('\n'))
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith(";"))
                    continue;

                // Skip comments that start with #
                if (trimmed.StartsWith("#"))
                    continue;

                if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
                {
                    currentSection = trimmed.Substring(1, trimmed.Length - 2);
                    continue;
                }

                // Only read from DevelopmentOverrides or Configuration sections
                if (currentSection != "DevelopmentOverrides" && currentSection != "Configuration")
                    continue;

                if (trimmed.Contains("="))
                {
                    var parts = trimmed.Split(new[] { '=' }, 2);
                    if (parts.Length == 2)
                    {
                        string key = parts[0].Trim();
                        string value = parts[1].Trim();

                        // Expand environment variables
                        value = Environment.ExpandEnvironmentVariables(value);

                        if (keyMapping.ContainsKey(key))
                        {
                            string settingsKey = keyMapping[key];
                            
                            // Special handling for optionsLua -> savedGamesPath (extract folder)
                            if (key == "optionsLua" && !string.IsNullOrEmpty(value))
                            {
                                // Get parent folder of Config folder
                                string configDir = Path.GetDirectoryName(value);
                                if (configDir != null && configDir.EndsWith("Config", StringComparison.OrdinalIgnoreCase))
                                {
                                    value = Path.GetDirectoryName(configDir) ?? value;
                                }
                            }
                            
                            paths[settingsKey] = value;
                        }
                    }
                }
            }

            return paths;
        }

        private async Task<object> WriteSettingsPaths(Dictionary<string, string> paths)
        {
            try
            {
                string iniPath = GetSettingsIniPath();
                if (!File.Exists(iniPath))
                {
                    return new { success = false, error = "INI file not found" };
                }

                await Task.Run(() => UpdateIniWithPaths(iniPath, paths));
                return new { success = true };
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private void UpdateIniWithPaths(string iniPath, Dictionary<string, string> paths)
        {
            var lines = File.ReadAllLines(iniPath).ToList();
            
            // Map settings keys to INI keys
            var keyMapping = new Dictionary<string, string>
            {
                { "dcsPath", "dcsExe" },
                { "savedGamesPath", "optionsLua" }, // Will convert to optionsLua path
                { "capframexPath", "capframex" },
                { "autoHotkeyPath", "autohotkey" },
                { "pimaxPath", "pimax" },
                { "notepadppPath", "notepadpp" },
                { "benchmarkMissionPath", "mission" }
            };

            bool inDevOverrides = false;
            var processedKeys = new HashSet<string>();

            for (int i = 0; i < lines.Count; i++)
            {
                var trimmed = lines[i].Trim();

                if (trimmed.StartsWith("["))
                {
                    inDevOverrides = trimmed == "[DevelopmentOverrides]";
                    continue;
                }

                if (!inDevOverrides) continue;

                // Check if this line matches any of our path keys
                foreach (var mapping in keyMapping)
                {
                    string settingsKey = mapping.Key;
                    string iniKey = mapping.Value;

                    if (paths.ContainsKey(settingsKey) && (trimmed.StartsWith(iniKey + " =") || trimmed.StartsWith(iniKey + "=")))
                    {
                        string value = paths[settingsKey];
                        
                        // Special handling for savedGamesPath -> optionsLua
                        if (settingsKey == "savedGamesPath")
                        {
                            value = Path.Combine(value, "Config", "options.lua");
                        }

                        lines[i] = iniKey + " = " + value;
                        processedKeys.Add(settingsKey);
                    }
                }
            }

            // Add any missing paths to DevelopmentOverrides section
            int devOverridesIndex = -1;
            for (int i = 0; i < lines.Count; i++)
            {
                if (lines[i].Trim() == "[DevelopmentOverrides]")
                {
                    devOverridesIndex = i;
                    break;
                }
            }

            if (devOverridesIndex >= 0)
            {
                // Find next section or end of file
                int insertIndex = devOverridesIndex + 1;
                while (insertIndex < lines.Count && !lines[insertIndex].Trim().StartsWith("["))
                {
                    insertIndex++;
                }

                // Add missing paths before next section
                foreach (var mapping in keyMapping)
                {
                    string settingsKey = mapping.Key;
                    string iniKey = mapping.Value;

                    if (paths.ContainsKey(settingsKey) && !processedKeys.Contains(settingsKey))
                    {
                        string value = paths[settingsKey];
                        
                        if (settingsKey == "savedGamesPath")
                        {
                            value = Path.Combine(value, "Config", "options.lua");
                        }

                        lines.Insert(insertIndex, iniKey + " = " + value);
                        insertIndex++;
                    }
                }
            }

            File.WriteAllLines(iniPath, lines, Encoding.UTF8);
        }

        private object BrowseForFile(string title, string filter)
        {
            try
            {
                using (var dialog = new OpenFileDialog())
                {
                    dialog.Title = title ?? "Select File";
                    dialog.Filter = filter ?? "All Files (*.*)|*.*";
                    dialog.CheckFileExists = true;
                    
                    if (dialog.ShowDialog(this) == DialogResult.OK)
                    {
                        return new { success = true, path = dialog.FileName };
                    }
                    return new { success = false, cancelled = true };
                }
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }

        private object BrowseForFolder(string title)
        {
            try
            {
                using (var dialog = new FolderBrowserDialog())
                {
                    dialog.Description = title ?? "Select Folder";
                    dialog.ShowNewFolderButton = true;
                    
                    if (dialog.ShowDialog(this) == DialogResult.OK)
                    {
                        return new { success = true, path = dialog.SelectedPath };
                    }
                    return new { success = false, cancelled = true };
                }
            }
            catch (Exception ex)
            {
                return new { success = false, error = ex.Message };
            }
        }
    }

    static class Program
    {
        [STAThread]
        static void Main()
        {
            // Global exception handlers
            Application.ThreadException += (s, e) =>
            {
                MessageBox.Show("Thread Exception: " + e.Exception.ToString(), "DCS-Max Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            };
            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
            {
                MessageBox.Show("Unhandled Exception: " + e.ExceptionObject.ToString(), "DCS-Max Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            };
            
            try
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Fatal Error: " + ex.ToString(), "DCS-Max Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
