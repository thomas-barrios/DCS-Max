# DCS-Max Release Builder
# Creates a clean release zip with only the files users need

param(
    [string]$Version = "1.2.1",
    [switch]$Open
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "=== DCS-Max Release Builder ===" -ForegroundColor Cyan
Write-Host "Version: $Version" -ForegroundColor Yellow

# Create release folder OUTSIDE the project (sibling folder)
$releaseDir = Join-Path (Split-Path $scriptDir -Parent) "DCS-Max-Releases"
$releaseName = "DCS-Max-v$Version"
$releaseFolder = Join-Path $releaseDir $releaseName
$releaseZip = Join-Path $releaseDir "$releaseName.zip"

# Clean previous release of same version
if (Test-Path $releaseFolder) { Remove-Item -Recurse -Force $releaseFolder }
if (Test-Path $releaseZip) { Remove-Item -Force $releaseZip }

# Create release directory
New-Item -ItemType Directory -Path $releaseFolder -Force | Out-Null
Write-Host "`nCreating release package..." -ForegroundColor Yellow

# ============================================
# FILES TO INCLUDE IN RELEASE
# ============================================

# 1. Main launcher
Copy-Item "DCS-Max.bat" $releaseFolder

# 2. Documentation (use lean release README)
if (Test-Path "RELEASE_README.md") {
    Copy-Item "RELEASE_README.md" (Join-Path $releaseFolder "README.md")
} elseif (Test-Path "README.md") {
    Copy-Item "README.md" $releaseFolder
}
$docs = @("CHANGELOG.md", "LICENSE", "quick-start-guide.md", "performance-guide.md", "performance-optimizations.md", "troubleshooting.md")
foreach ($doc in $docs) {
    if (Test-Path $doc) { Copy-Item $doc $releaseFolder }
}

# 3. Script folders (0-5)
$scriptFolders = @(
    "0-Install-Required-Software",
    "1-Backup-Restore",
    "2-Utilities",
    "3-Templates",
    "4-Performance-Testing",
    "5-Optimization",
    "lib"
)

foreach ($folder in $scriptFolders) {
    if (Test-Path $folder) {
        Copy-Item -Recurse $folder (Join-Path $releaseFolder $folder)
    }
}

# 4. UI App (only compiled files)
$uiAppDest = Join-Path $releaseFolder "ui-app"
New-Item -ItemType Directory -Path $uiAppDest -Force | Out-Null

# Check if app is built
$binPath = Join-Path $scriptDir "ui-app\bin"
if (-not (Test-Path (Join-Path $binPath "DCS-Max.exe"))) {
    Write-Host "Building UI app first..." -ForegroundColor Yellow
    Push-Location "ui-app"
    & .\build.ps1
    Pop-Location
}

# Copy only the bin folder (compiled app)
Copy-Item -Recurse $binPath (Join-Path $uiAppDest "bin")

# 5. Create empty Backups folder with readme and empty log
$backupsDir = Join-Path $releaseFolder "Backups"
New-Item -ItemType Directory -Path $backupsDir -Force | Out-Null
Set-Content -Path (Join-Path $backupsDir "_README.txt") -Value "This folder stores your backup files created by DCS-Max."
Set-Content -Path (Join-Path $backupsDir "_BackupLog.txt") -Value "# DCS-Max Backup Log`r`n# Logs will appear here after running backup operations."

# ============================================
# CLEANUP - Remove dev files that snuck in
# ============================================

# Remove any .git folders
Get-ChildItem -Path $releaseFolder -Recurse -Directory -Filter ".git" -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Remove debug files from bin
$debugFiles = @("webview-debug.log", "test.exe")
foreach ($file in $debugFiles) {
    $debugPath = Join-Path $uiAppDest "bin\$file"
    if (Test-Path $debugPath) { Remove-Item -Force $debugPath }
}

# Remove Debug/Release subfolders if they exist
$devFolders = @("Debug", "Release")
foreach ($folder in $devFolders) {
    $devPath = Join-Path $uiAppDest "bin\$folder"
    if (Test-Path $devPath) { Remove-Item -Recurse -Force $devPath }
}

# Clear log files (keep file, empty content)
$logFile = Join-Path $releaseFolder "Backups\_BackupLog.txt"
if (Test-Path $logFile) {
    Set-Content -Path $logFile -Value "# DCS-Max Backup Log`n# Logs will appear here after running backup operations."
}

# Clear benchmark logs
$benchmarkLog = Join-Path $releaseFolder "4-Performance-Testing\4.1.2-dcs-testing-automation.log"
if (Test-Path $benchmarkLog) {
    Set-Content -Path $benchmarkLog -Value "# DCS-Max Benchmark Log`r`n# Logs will appear here after running benchmarks."
}

# Remove DevelopmentOverrides section from testing config
$testingConfig = Join-Path $releaseFolder "4-Performance-Testing\4.1.1-dcs-testing-configuration.ini"
if (Test-Path $testingConfig) {
    $content = Get-Content $testingConfig -Raw
    # Remove the DevelopmentOverrides section (from header comment to the ending separator)
    $content = $content -replace '(?s)#={10,}\r?\n# Development Overrides.*?\[DevelopmentOverrides\].*?#={10,}\r?\n', ''
    Set-Content -Path $testingConfig -Value $content -NoNewline
}

# ============================================
# CREATE ZIP
# ============================================

Write-Host "`nCreating zip archive..." -ForegroundColor Yellow
Compress-Archive -Path $releaseFolder -DestinationPath $releaseZip -Force

# Get file sizes
$zipSize = (Get-Item $releaseZip).Length / 1MB
$folderSize = (Get-ChildItem -Path $releaseFolder -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host "`n=== Release Complete ===" -ForegroundColor Green
Write-Host "Folder: $releaseFolder" -ForegroundColor Cyan
Write-Host "ZIP:    $releaseZip" -ForegroundColor Cyan
Write-Host "Folder Size: $([math]::Round($folderSize, 2)) MB" -ForegroundColor Yellow
Write-Host "ZIP Size:    $([math]::Round($zipSize, 2)) MB" -ForegroundColor Yellow

# List contents
Write-Host "`nRelease contents:" -ForegroundColor Yellow
Get-ChildItem $releaseFolder | ForEach-Object {
    $size = if ($_.PSIsContainer) {
        $s = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB
        "$([math]::Round($s, 0)) KB"
    } else {
        "$([math]::Round($_.Length / 1KB, 0)) KB"
    }
    Write-Host "  $($_.Name) ($size)"
}

if ($Open) {
    explorer.exe $releaseDir
}

Write-Host "`nUsers can extract the zip and double-click DCS-Max.bat to start!" -ForegroundColor Green
