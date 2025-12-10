# DCS-Max Development Restore Defaults
# Restores all config JSON files to default/safe values for clean releases

param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Restoring config-global.json to defaults..." -ForegroundColor Yellow

$configGlobalDefaults = @{
    version = "2.0.0"
    description = "DCS-Max Global Configuration - Paths, VR hardware, timing, shared by all scripts"
    paths = @{
        dcsExe = "%ProgramFiles%\Eagle Dynamics\DCS World\bin\DCS.exe"
        dcsInstallation = "%ProgramFiles%\Eagle Dynamics\DCS World"
        savedGamesPath = "%USERPROFILE%\Saved Games\DCS"
        pimax = "%ProgramFiles%\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
        capframex = "%USERPROFILE%\AppData\Local\Microsoft\WinGet\Packages\CXWorld.CapFrameX_Microsoft.Winget.Source_8wekyb3d8bbwe\CapFrameX.exe"
        capframexFolder = "%USERPROFILE%\Documents\CapFrameX\Captures"
        notepadpp = "%ProgramFiles%\Notepad++\notepad++.exe"
        autohotkey = "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
    }
    vr = @{
        enabled = $false
        hardware = ""
    }
    vrHeadsets = @{
        metaquest = @{
            name = "Meta Quest (Link/Air Link)"
            path = "%ProgramFiles%\Meta\MetaQuestLink\MetaQuestLink.exe"
        }
        steamvr = @{
            name = "SteamVR (Vive/Index/Reverb G2)"
            path = "%ProgramFiles(x86)%\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe"
        }
        pimax = @{
            name = "Pimax"
            path = "%ProgramFiles%\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
        }
    }
}

if ($WhatIf) {
    Write-Host "  [WHATIF] Would restore config-global.json" -ForegroundColor Gray
} else {
    $configGlobalDefaults | ConvertTo-Json -Depth 10 | Set-Content -Path "config-global.json" -Encoding UTF8
    Write-Host "  ✓ Restored config-global.json" -ForegroundColor Green
}

# ============================================
# CONFIG-OPTIMIZATIONS.JSON - All Enabled
# ============================================

Write-Host "Restoring config-optimizations.json to all enabled..." -ForegroundColor Yellow

# Read current config to preserve structure but disable all
try {
    $configOptimizations = Get-Content -Path "config-optimizations.json" -Raw | ConvertFrom-Json
} catch {
    Write-Host "Error: Failed to load config-optimizations.json: $_" -ForegroundColor Red
    Write-Host "Cannot restore defaults. Please check the config file." -ForegroundColor Red
    exit 1
}

# Enable all registry optimizations
if ($configOptimizations.registryOptimizations) {
    foreach ($key in $configOptimizations.registryOptimizations.PSObject.Properties.Name) {
        if ($configOptimizations.registryOptimizations.$key -is [object] -and $configOptimizations.registryOptimizations.$key.enabled -ne $null) {
            $configOptimizations.registryOptimizations.$key.enabled = $true
        } elseif ($configOptimizations.registryOptimizations.$key -is [bool]) {
            $configOptimizations.registryOptimizations.$key = $true
        }
    }
}

# Enable all service optimizations
if ($configOptimizations.serviceOptimizations) {
    foreach ($key in $configOptimizations.serviceOptimizations.PSObject.Properties.Name) {
        if ($configOptimizations.serviceOptimizations.$key -is [object] -and $configOptimizations.serviceOptimizations.$key.enabled -ne $null) {
            $configOptimizations.serviceOptimizations.$key.enabled = $true
        } elseif ($configOptimizations.serviceOptimizations.$key -is [bool]) {
            $configOptimizations.serviceOptimizations.$key = $true
        }
    }
}

# Enable all task optimizations
if ($configOptimizations.taskOptimizations) {
    foreach ($key in $configOptimizations.taskOptimizations.PSObject.Properties.Name) {
        if ($configOptimizations.taskOptimizations.$key -is [object] -and $configOptimizations.taskOptimizations.$key.enabled -ne $null) {
            $configOptimizations.taskOptimizations.$key.enabled = $true
        } elseif ($configOptimizations.taskOptimizations.$key -is [bool]) {
            $configOptimizations.taskOptimizations.$key = $true
        }
    }
}

# Enable all cache optimizations
if ($configOptimizations.cacheOptimizations) {
    foreach ($key in $configOptimizations.cacheOptimizations.PSObject.Properties.Name) {
        if ($configOptimizations.cacheOptimizations.$key -is [object] -and $configOptimizations.cacheOptimizations.$key.enabled -ne $null) {
            $configOptimizations.cacheOptimizations.$key.enabled = $true
        } elseif ($configOptimizations.cacheOptimizations.$key -is [bool]) {
            $configOptimizations.cacheOptimizations.$key = $true
        }
    }
}

if ($WhatIf) {
    Write-Host "  [WHATIF] Would restore config-optimizations.json (all enabled)" -ForegroundColor Gray
} else {
    $configOptimizations | ConvertTo-Json -Depth 10 | Set-Content -Path "config-optimizations.json" -Encoding UTF8
    Write-Host "  ✓ Restored config-optimizations.json (all optimizations enabled)" -ForegroundColor Green
}

# ============================================
# CONFIG-TESTS.JSON - Default Test Settings
# ============================================

Write-Host "Restoring config-tests.json to defaults..." -ForegroundColor Yellow

$configTestsDefaults = @{
    version = "1.0.0"
    description = "DCS-Max Benchmark Testing Configuration - Test parameters, timing, and performance analysis. Global paths/VR in config-global.json"
    testConfiguration = @{
        dryRun = $false
        mission = "Su25-caucasus-ordzhonikidze-04air-98ground-cavok-sp-noserver-25min.miz"
        numberOfRuns = 1
        maxRetries = 1
    }
    timing = @{
        vr = 20000
        missionReady = 45000
        beforeRecord = 3000
        recordLength = 60000
        capFrameXWrite = 5000
        missionRestart = 30000
    }
    testsToRun = @(
        @{
            setting = "AA"
            values = @("DLAA", "MSAA")
            enabled = $false
        }
        @{
            setting = "MSAA"
            values = @(0, 1, 2, 3, 4)
            enabled = $false
        }
        @{
            setting = "textures"
            values = @(0, 2)
            enabled = $false
        }
        @{
            setting = "shadows"
            values = @(1, 3)
            enabled = $false
        }
        @{
            setting = "Upscaling"
            values = @("DLSS", "FSR", "OFF")
            enabled = $false
        }
    )
}

if ($WhatIf) {
    Write-Host "  [WHATIF] Would restore config-tests.json" -ForegroundColor Gray
} else {
    $configTestsDefaults | ConvertTo-Json -Depth 10 | Set-Content -Path "config-tests.json" -Encoding UTF8
    Write-Host "  ✓ Restored config-tests.json" -ForegroundColor Green
}

# ============================================
# SUMMARY
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "WHATIF MODE - No changes made" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "Config files restored to defaults!" -ForegroundColor Green
    Write-Host "Ready for clean release packaging." -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan