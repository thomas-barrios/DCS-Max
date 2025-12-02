# DCS-Max UI Application

Lightweight WebView2-based user interface for the DCS-Max performance optimization suite.

## Architecture

- **React + Vite + Tailwind** - Modern web UI (source in `src/`)
- **WebView2** - Windows native browser control (uses built-in Edge)
- **C# WinForms Launcher** - 52KB executable, no .NET SDK required

## Quick Start

Double-click `DCS-Max.bat` to launch. First run will compile the C# launcher automatically.

## Development

### Prerequisites
- Node.js 18+ (for building React UI)
- Windows 10/11 (WebView2 is built-in)
- .NET Framework 4.8 (built into Windows)

### Build React UI
```bash
npm install
npm run build
```

### Build C# Launcher
```powershell
.\build.ps1
```

### Development Mode
```bash
npm run dev
```
Then open `http://localhost:5173` in a browser for hot-reload development.

## Folder Structure

```
ui-app/
├── src/                    # React source code
│   ├── components/         # React components
│   ├── App.jsx            # Main app component
│   └── index.css          # Tailwind CSS
├── dist/                   # Built React output
├── bin/                    # Compiled C# launcher
│   ├── DCS-Max.exe        # Main executable (52KB)
│   └── web/               # Bundled web files
├── packages/              # NuGet packages (WebView2, Json)
├── Program-CS5.cs         # C# source (C# 5 compatible)
├── build.ps1              # Build script
├── index.html             # React entry point
├── vite.config.js         # Vite configuration
└── tailwind.config.js     # Tailwind configuration
```

## Size Comparison

| Version | Size |
|---------|------|
| Electron | ~200MB |
| WebView2 | ~1.6MB |

WebView2 uses the Edge browser already installed on Windows, eliminating the need to bundle Chromium.
