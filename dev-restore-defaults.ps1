# DCS-Max Development Restore Defaults
# Restores all config JSON files to default/safe values for clean releases

param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Restoring config-global.json to defaults (preserve structure)..." -ForegroundColor Yellow

$configGlobalPath = "config-global.json"
$configGlobal = $null
try {
    if (Test-Path $configGlobalPath) {
        $configGlobal = Get-Content -Path $configGlobalPath -Raw | ConvertFrom-Json
    }
} catch {}

if (-not $configGlobal) {
    $configGlobal = [ordered]@{
        version = "2.0.0"
        description = "DCS-Max Global Configuration - Paths, VR hardware, timing, shared by all scripts"
        paths = @{}
        vr = @{}
    }
}

$defaultGlobal = @{
    version = "2.0.0"
    description = "DCS-Max Global Configuration - Paths, VR hardware, timing, shared by all scripts"
    paths = @{
        dcsExe = "%ProgramFiles%\Eagle Dynamics\DCS World\bin\DCS.exe"
        dcsInstallation = "%ProgramFiles%\Eagle Dynamics\DCS World"
        savedGamesPath = "%USERPROFILE%\Saved Games\DCS"
        capframex = "%USERPROFILE%\AppData\Local\Microsoft\WinGet\Packages\CXWorld.CapFrameX_Microsoft.Winget.Source_8wekyb3d8bbwe\CapFrameX.exe"
        capframexFolder = "%USERPROFILE%\Documents\CapFrameX\Captures"
        notepadpp = "%ProgramFiles%\Notepad++\notepad++.exe"
        autohotkey = "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
    }
    vr = @{
        enabled = $false
    }
}

# Helper to set/add properties safely on PSCustomObject or IDictionary
function Set-ConfigValue {
    param($obj, [string]$name, $value)
    if ($obj -is [System.Collections.IDictionary]) {
        $obj[$name] = $value
    } elseif ($obj -is [pscustomobject]) {
        if ($obj.PSObject.Properties[$name]) {
            $obj.$name = $value
        } else {
            $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
        }
    } else {
        $tmp = @{}
        $tmp[$name] = $value
        return $tmp
    }
    return $obj
}

# Apply defaults without removing custom fields
$configGlobal.version = $defaultGlobal.version
$configGlobal.description = $defaultGlobal.description

$needsPathsReset = (-not $configGlobal.paths) -or ($configGlobal.paths -isnot [pscustomobject] -and $configGlobal.paths -isnot [System.Collections.IDictionary])
if ($needsPathsReset) {
    $configGlobal = Set-ConfigValue -obj $configGlobal -name 'paths' -value @{}
}
foreach ($k in $defaultGlobal.paths.Keys) {
    $configGlobal.paths = Set-ConfigValue -obj $configGlobal.paths -name $k -value $defaultGlobal.paths.$k
}

$needsVrReset = (-not $configGlobal.vr) -or ($configGlobal.vr -isnot [pscustomobject] -and $configGlobal.vr -isnot [System.Collections.IDictionary])
if ($needsVrReset) {
    $configGlobal = Set-ConfigValue -obj $configGlobal -name 'vr' -value @{}
}
foreach ($k in $defaultGlobal.vr.Keys) {
    $configGlobal.vr = Set-ConfigValue -obj $configGlobal.vr -name $k -value $defaultGlobal.vr.$k
}



# Remove deprecated keys (ensure they do not exist)
if ($configGlobal.paths) {
    if ($configGlobal.paths -is [System.Collections.IDictionary]) {
        foreach ($dep in @('pimax')) { if ($configGlobal.paths.Contains($dep)) { $configGlobal.paths.Remove($dep) } }
    } else {
        foreach ($dep in @('pimax')) { if ($configGlobal.paths.PSObject.Properties[$dep]) { $null = $configGlobal.paths.PSObject.Properties.Remove($dep) } }
    }
}
if ($configGlobal.vr) {
    if ($configGlobal.vr -is [System.Collections.IDictionary]) {
        foreach ($dep in @('hardware')) { if ($configGlobal.vr.Contains($dep)) { $configGlobal.vr.Remove($dep) } }
    } else {
        foreach ($dep in @('hardware')) { if ($configGlobal.vr.PSObject.Properties[$dep]) { $null = $configGlobal.vr.PSObject.Properties.Remove($dep) } }
    }
}

# Remove vrHeadsets entirely (deprecated structure)
if ($configGlobal.PSObject.Properties['vrHeadsets']) { $null = $configGlobal.PSObject.Properties.Remove('vrHeadsets') }
elseif ($configGlobal -is [System.Collections.IDictionary] -and $configGlobal.Contains('vrHeadsets')) { $configGlobal.Remove('vrHeadsets') }

if ($WhatIf) {
    Write-Host "  [WHATIF] Would restore config-global.json (values only)" -ForegroundColor Gray
} else {
    $configGlobal | ConvertTo-Json -Depth 10 | Set-Content -Path $configGlobalPath -Encoding UTF8
    Write-Host "  ✓ Restored config-global.json (values updated, structure preserved)" -ForegroundColor Green
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

Write-Host "Restoring config-tests.json to defaults (preserve structure)..." -ForegroundColor Yellow

$configTestsPath = "config-tests.json"
$configTests = $null
try {
    if (Test-Path $configTestsPath) {
        $configTests = Get-Content -Path $configTestsPath -Raw | ConvertFrom-Json
    }
} catch {}

if (-not $configTests) {
    $configTests = [ordered]@{
        version = "1.0.0"
        description = "DCS-Max Benchmark Testing Configuration - Test parameters, timing, and performance analysis. Global paths/VR in config-global.json"
        testConfiguration = @{}
        timing = @{}
        testsToRun = @()
    }
}

$defaultTests = @{
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
}

$configTests.version = $defaultTests.version
$configTests.description = $defaultTests.description

if (-not $configTests.testConfiguration -or ($configTests.testConfiguration -isnot [pscustomobject] -and $configTests.testConfiguration -isnot [System.Collections.IDictionary])) {
    $configTests.testConfiguration = @{}
}
foreach ($k in $defaultTests.testConfiguration.Keys) {
    $configTests.testConfiguration = Set-ConfigValue -obj $configTests.testConfiguration -name $k -value $defaultTests.testConfiguration.$k
}

if (-not $configTests.timing -or ($configTests.timing -isnot [pscustomobject] -and $configTests.timing -isnot [System.Collections.IDictionary])) {
    $configTests.timing = @{}
}
foreach ($k in $defaultTests.timing.Keys) {
    $configTests.timing = Set-ConfigValue -obj $configTests.timing -name $k -value $defaultTests.timing.$k
}

# Normalize testsToRun: update defaults, preserve extras
$existing = @{}
foreach ($item in $configTests.testsToRun) {
    if ($item.setting) { $existing[$item.setting] = $item }
}

$updatedList = @()
foreach ($def in $defaultTests.testsToRun) {
    if ($existing.ContainsKey($def.setting)) {
        $entry = $existing[$def.setting]
        $entry.values = $def.values
        $entry.enabled = $def.enabled
        $updatedList += $entry
    } else {
        $updatedList += [pscustomobject]$def
    }
}

# Append any custom tests not in defaults
foreach ($key in $existing.Keys) {
    if (-not ($defaultTests.testsToRun.setting -contains $key)) {
        $updatedList += $existing[$key]
    }
}
if (-not $configTests.testsToRun -or ($configTests.testsToRun -isnot [System.Collections.IEnumerable])) {
    $configTests = Set-ConfigValue -obj $configTests -name 'testsToRun' -value @()
}
$configTests = Set-ConfigValue -obj $configTests -name 'testsToRun' -value $updatedList

if ($WhatIf) {
    Write-Host "  [WHATIF] Would restore config-tests.json (values only)" -ForegroundColor Gray
} else {
    $configTests | ConvertTo-Json -Depth 10 | Set-Content -Path $configTestsPath -Encoding UTF8
    Write-Host "  ✓ Restored config-tests.json (values updated, structure preserved)" -ForegroundColor Green
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