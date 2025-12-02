# Build script for DCS-Max WebView2 Launcher
# Uses the built-in .NET Framework compiler (no SDK required)

param(
    [switch]$Release,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "=== DCS-Max WebView2 Build Script ===" -ForegroundColor Cyan

# Find csc.exe (C# compiler) from .NET Framework
$cscPaths = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$csc = $null
foreach ($path in $cscPaths) {
    if (Test-Path $path) {
        $csc = $path
        break
    }
}

if (-not $csc) {
    Write-Host "ERROR: C# compiler (csc.exe) not found." -ForegroundColor Red
    Write-Host "This script requires .NET Framework 4.0+ which should be built into Windows." -ForegroundColor Yellow
    exit 1
}
Write-Host "Found C# compiler: $csc" -ForegroundColor Green

# Check for NuGet packages - we need WebView2 and Newtonsoft.Json
$packagesDir = Join-Path $scriptDir "packages"
$webView2Dir = Join-Path $packagesDir "Microsoft.Web.WebView2.1.0.2210.55"
$jsonDir = Join-Path $packagesDir "Newtonsoft.Json.13.0.3"

$needsPackages = $false
if (-not (Test-Path $webView2Dir)) { $needsPackages = $true }
if (-not (Test-Path $jsonDir)) { $needsPackages = $true }

if ($needsPackages) {
    Write-Host "`nDownloading required NuGet packages..." -ForegroundColor Yellow
    
    # Download NuGet.exe if not present
    $nugetPath = Join-Path $scriptDir "nuget.exe"
    if (-not (Test-Path $nugetPath)) {
        Write-Host "Downloading NuGet.exe..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath
    }
    
    # Install packages
    if (-not (Test-Path $packagesDir)) { New-Item -ItemType Directory -Path $packagesDir | Out-Null }
    
    & $nugetPath install Microsoft.Web.WebView2 -Version 1.0.2210.55 -OutputDirectory $packagesDir
    & $nugetPath install Newtonsoft.Json -Version 13.0.3 -OutputDirectory $packagesDir
}

# Find the actual package directories (may have different case)
$webView2Dir = Get-ChildItem -Path $packagesDir -Directory | Where-Object { $_.Name -like "Microsoft.Web.WebView2*" } | Select-Object -First 1 -ExpandProperty FullName
$jsonDir = Get-ChildItem -Path $packagesDir -Directory | Where-Object { $_.Name -like "Newtonsoft.Json*" } | Select-Object -First 1 -ExpandProperty FullName

if (-not $webView2Dir -or -not $jsonDir) {
    Write-Host "ERROR: Failed to install NuGet packages." -ForegroundColor Red
    exit 1
}

# Clean if requested
if ($Clean) {
    Write-Host "`nCleaning build artifacts..." -ForegroundColor Yellow
    if (Test-Path "bin") { Remove-Item -Recurse -Force "bin" }
    if (Test-Path "obj") { Remove-Item -Recurse -Force "obj" }
    Write-Host "Clean complete!" -ForegroundColor Green
}

# Create output directory
$outputDir = Join-Path $scriptDir "bin"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }

# Copy web files
$distPath = Join-Path $scriptDir "dist"
$webPath = Join-Path $outputDir "web"
if (Test-Path $distPath) {
    Write-Host "`nCopying web app..." -ForegroundColor Yellow
    if (Test-Path $webPath) { Remove-Item -Recurse -Force $webPath }
    Copy-Item -Recurse $distPath $webPath
    Write-Host "Web app copied to: $webPath" -ForegroundColor Green
} else {
    Write-Host "WARNING: React app not built. Run 'npm run build' first." -ForegroundColor Yellow
}

# Find DLL references
$webView2Dll = Join-Path $webView2Dir "lib\net45\Microsoft.Web.WebView2.Core.dll"
$webView2WinFormsDll = Join-Path $webView2Dir "lib\net45\Microsoft.Web.WebView2.WinForms.dll"
$jsonDll = Join-Path $jsonDir "lib\net45\Newtonsoft.Json.dll"

Write-Host "`nCompiling DCS-Max launcher..." -ForegroundColor Yellow

# Compile
$sourceFile = Join-Path $scriptDir "Program-CS5.cs"
$outputExe = Join-Path $outputDir "DCS-Max.exe"

$references = @(
    "/reference:$webView2Dll",
    "/reference:$webView2WinFormsDll",
    "/reference:$jsonDll",
    "/reference:System.dll",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.Drawing.dll",
    "/reference:System.Core.dll"
)

$compilerArgs = @(
    "/target:winexe",
    "/out:$outputExe",
    "/optimize+",
    "/platform:x64"
) + $references + @($sourceFile)

if (Test-Path (Join-Path $scriptDir "app.manifest")) {
    $compilerArgs += "/win32manifest:$(Join-Path $scriptDir 'app.manifest')"
}

& $csc @compilerArgs

if ($LASTEXITCODE -eq 0) {
    # Copy required DLLs to output
    Copy-Item $webView2Dll $outputDir -Force
    Copy-Item $webView2WinFormsDll $outputDir -Force
    Copy-Item $jsonDll $outputDir -Force
    
    # Copy WebView2 loader
    $loaderDir = Join-Path $webView2Dir "runtimes\win-x64\native"
    if (Test-Path $loaderDir) {
        Copy-Item (Join-Path $loaderDir "WebView2Loader.dll") $outputDir -Force
    }
    
    $size = [math]::Round((Get-Item $outputExe).Length / 1KB, 2)
    Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
    Write-Host "Executable: $outputExe" -ForegroundColor Cyan
    Write-Host "Size: $size KB" -ForegroundColor Cyan
    
    # Calculate total size
    $totalSize = [math]::Round(((Get-ChildItem -Recurse $outputDir | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
    Write-Host "Total folder size: $totalSize MB" -ForegroundColor Cyan
    Write-Host "`nTo run: .\bin\DCS-Max.exe" -ForegroundColor Yellow
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
