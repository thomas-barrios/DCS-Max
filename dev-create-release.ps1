# DCS-Max Release Builder
# Creates a clean release zip with only the files users need

param(
    [string]$Version,
    [ValidateSet("major", "minor", "patch")]
    [string]$Increment,
    [switch]$Open
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Version file to track releases
$versionFile = Join-Path $scriptDir ".version"

# ============================================
# VERSION MANAGEMENT
# ============================================

function Get-LastVersion {
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    # If no version file, try to read from DcsMaxLauncher.csproj
    $csprojPath = Join-Path $scriptDir "ui-app\DcsMaxLauncher.csproj"
    if (Test-Path $csprojPath) {
        $content = Get-Content $csprojPath -Raw
        if ($content -match '<Version>([0-9]+\.[0-9]+\.[0-9]+)</Version>') {
            return $matches[1]
        }
    }
    return "1.0.0"
}

function Increment-Version {
    param(
        [string]$CurrentVersion,
        [string]$Type
    )
    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($Type) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }
    
    return "$major.$minor.$patch"
}

function Update-VersionInFiles {
    param([string]$NewVersion)
    
    Write-Host "`nUpdating version to $NewVersion in all files..." -ForegroundColor Yellow
    
    # 1. DcsMaxLauncher.csproj
    $csprojPath = Join-Path $scriptDir "ui-app\DcsMaxLauncher.csproj"
    if (Test-Path $csprojPath) {
        $content = Get-Content $csprojPath -Raw
        $content = $content -replace '<Version>[0-9]+\.[0-9]+\.[0-9]+</Version>', "<Version>$NewVersion</Version>"
        Set-Content -Path $csprojPath -Value $content -NoNewline
        Write-Host "  ✓ Updated DcsMaxLauncher.csproj" -ForegroundColor Green
    }
    
    # 2. App.jsx (UI version display)
    $appJsxPath = Join-Path $scriptDir "ui-app\src\App.jsx"
    if (Test-Path $appJsxPath) {
        $content = Get-Content $appJsxPath -Raw
        $content = $content -replace 'v[0-9]+\.[0-9]+\.[0-9]+', "v$NewVersion"
        Set-Content -Path $appJsxPath -Value $content -NoNewline
        Write-Host "  ✓ Updated App.jsx" -ForegroundColor Green
    }
    
    # 3. package.json
    $packageJsonPath = Join-Path $scriptDir "ui-app\package.json"
    if (Test-Path $packageJsonPath) {
        $content = Get-Content $packageJsonPath -Raw
        $content = $content -replace '"version": "[0-9]+\.[0-9]+\.[0-9]+"', "`"version`": `"$NewVersion`""
        Set-Content -Path $packageJsonPath -Value $content -NoNewline
        Write-Host "  ✓ Updated package.json" -ForegroundColor Green
    }
    
    # 4. README.md (download links)
    $readmePath = Join-Path $scriptDir "README.md"
    if (Test-Path $readmePath) {
        $content = Get-Content $readmePath -Raw
        # Update download links: v1.2.1/DCS-Max-v1.2.1.zip pattern
        $content = $content -replace 'v[0-9]+\.[0-9]+\.[0-9]+/DCS-Max-v[0-9]+\.[0-9]+\.[0-9]+\.zip', "v$NewVersion/DCS-Max-v$NewVersion.zip"
        Set-Content -Path $readmePath -Value $content -NoNewline
        Write-Host "  ✓ Updated README.md download links" -ForegroundColor Green
    }
    
    # 5. app.manifest (optional - assemblyIdentity version)
    $manifestPath = Join-Path $scriptDir "ui-app\app.manifest"
    if (Test-Path $manifestPath) {
        $content = Get-Content $manifestPath -Raw
        # assemblyIdentity uses 4-part version (1.2.1.0)
        $content = $content -replace 'version="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"', "version=`"$NewVersion.0`""
        Set-Content -Path $manifestPath -Value $content -NoNewline
        Write-Host "  ✓ Updated app.manifest" -ForegroundColor Green
    }
    
    # Save version to tracking file
    Set-Content -Path $versionFile -Value $NewVersion
    Write-Host "  ✓ Saved version to .version file" -ForegroundColor Green
}

# ============================================
# DETERMINE VERSION
# ============================================

$lastVersion = Get-LastVersion
Write-Host "=== DCS-Max Release Builder ===" -ForegroundColor Cyan
Write-Host "Last version: $lastVersion" -ForegroundColor Yellow

if ($Version) {
    # Explicit version provided
    $targetVersion = $Version
    Write-Host "Using specified version: $targetVersion" -ForegroundColor Yellow
} elseif ($Increment) {
    # Increment from last version
    $targetVersion = Increment-Version -CurrentVersion $lastVersion -Type $Increment
    Write-Host "Incrementing $Increment version: $lastVersion -> $targetVersion" -ForegroundColor Yellow
} else {
    # Interactive: ask user
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  1. Patch release (bug fixes):    $lastVersion -> $(Increment-Version $lastVersion 'patch')" -ForegroundColor White
    Write-Host "  2. Minor release (new features): $lastVersion -> $(Increment-Version $lastVersion 'minor')" -ForegroundColor White
    Write-Host "  3. Major release (breaking):     $lastVersion -> $(Increment-Version $lastVersion 'major')" -ForegroundColor White
    Write-Host "  4. Enter custom version" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Select option (1-4, or press Enter for patch)"
    
    switch ($choice) {
        "1" { $targetVersion = Increment-Version $lastVersion 'patch' }
        "2" { $targetVersion = Increment-Version $lastVersion 'minor' }
        "3" { $targetVersion = Increment-Version $lastVersion 'major' }
        "4" { 
            $targetVersion = Read-Host "Enter version (e.g., 1.3.0)"
            if (-not ($targetVersion -match '^[0-9]+\.[0-9]+\.[0-9]+$')) {
                Write-Host "Invalid version format. Use X.Y.Z" -ForegroundColor Red
                exit 1
            }
        }
        "" { $targetVersion = Increment-Version $lastVersion 'patch' }
        default { $targetVersion = Increment-Version $lastVersion 'patch' }
    }
}

Write-Host "`nTarget Version: $targetVersion" -ForegroundColor Green

# Confirm before proceeding
$confirm = Read-Host "Proceed with version $targetVersion? (Y/n)"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Update all version references
Update-VersionInFiles -NewVersion $targetVersion

# Create release folder OUTSIDE the project (sibling folder)
$releaseDir = Join-Path (Split-Path $scriptDir -Parent) "DCS-Max-Releases"
$releaseName = "DCS-Max-v$targetVersion"
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

# Remove dev/build scripts from root (should not be copied, but ensure they're not there)
$devScripts = @("create-release.ps1", "build-and-run.ps1")
foreach ($script in $devScripts) {
    $scriptPath = Join-Path $releaseFolder $script
    if (Test-Path $scriptPath) { Remove-Item -Force $scriptPath }
}

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
Write-Host "Version: $targetVersion" -ForegroundColor Cyan
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

Write-Host "`nFiles updated with version $targetVersion`:" -ForegroundColor Cyan
Write-Host "  - ui-app\DcsMaxLauncher.csproj" -ForegroundColor White
Write-Host "  - ui-app\src\App.jsx" -ForegroundColor White
Write-Host "  - ui-app\package.json" -ForegroundColor White
Write-Host "  - README.md (download links)" -ForegroundColor White
Write-Host "  - ui-app\app.manifest" -ForegroundColor White
Write-Host "  - .version (tracking file)" -ForegroundColor White

Write-Host "`nRemember to:" -ForegroundColor Yellow
Write-Host "  1. Update CHANGELOG.md with release notes" -ForegroundColor White
Write-Host "  2. Commit changes: git add -A && git commit -m 'Release v$targetVersion'" -ForegroundColor White
Write-Host "  3. Tag release: git tag v$targetVersion" -ForegroundColor White
Write-Host "  4. Push: git push && git push --tags" -ForegroundColor White

if ($Open) {
    explorer.exe $releaseDir
}

Write-Host "`nUsers can extract the zip and double-click DCS-Max.bat to start!" -ForegroundColor Green
