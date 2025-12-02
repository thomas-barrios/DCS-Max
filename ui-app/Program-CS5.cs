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

namespace DcsMaxLauncher
{
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
            InitializeForm();
            CreateLoadingUI();
            // Show form immediately with loading UI
            this.Show();
            Application.DoEvents();
            // Then start WebView2 initialization
            InitializeWebView();
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
            projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".."));
            
            // If running from build output, adjust path
            if (!Directory.Exists(Path.Combine(projectRoot, "Backups")))
            {
                projectRoot = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", ".."));
            }
        }

        private async void InitializeWebView()
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

                    // INI Operations
                    readIniConfig: function(iniPath) {
                        return this._invoke('readIniConfig', [iniPath]);
                    },
                    writeIniConfig: function(iniPath, content) {
                        return this._invoke('writeIniConfig', [iniPath, content]);
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
                    case "readIniConfig":
                        result = await ReadIniConfig(args[0] != null ? args[0].Value<string>() : null);
                        break;
                    case "writeIniConfig":
                        result = await WriteIniConfig(
                            args[0] != null ? args[0].Value<string>() : null, 
                            args[1] != null ? args[1].Value<string>() : null);
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
                    case "watchLog":
                        StartWatchingLog(args[0] != null ? args[0].Value<string>() : null);
                        return; // No response needed
                    case "stopWatchLog":
                        StopWatchingLog();
                        return; // No response needed
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

        private async Task<object> ReadIniConfig(string iniPath)
        {
            try
            {
                string fullPath = Path.Combine(projectRoot, iniPath);
                string content = await Task.Run(delegate { return File.ReadAllText(fullPath); });
                var parsed = ParseIni(content);
                return new { success = true, content = content, parsed = parsed };
            }
            catch (Exception ex)
            {
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
                var backups = new List<object>();

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

                        backups.Add(new
                        {
                            name = name,
                            type = backupType,
                            date = info.LastWriteTime,
                            size = isDir ? 0 : info.Length
                        });
                    }
                });

                return new { success = true, backups = backups.OrderByDescending(delegate(object b) { return ((dynamic)b).date; }).ToList() };
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
                            "$ram = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0); " +
                            "$cpu = (Get-CimInstance Win32_Processor).Name; " +
                            "$gpu = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Microsoft|Basic' } | Select-Object -First 1).Name; " +
                            "if (-not $gpu) { $gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name }; " +
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
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
