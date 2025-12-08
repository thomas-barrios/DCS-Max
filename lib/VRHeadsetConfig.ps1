# VR Headset Configuration Management
# Provides abstraction layer for multi-headset support
# Handles detection, path resolution, and settings backup

# ============================================
# HEADSET DETECTION
# ============================================

function Detect-InstalledHeadsets {
    <#
    .SYNOPSIS
    Detects which VR headsets are installed on the system.
    
    .DESCRIPTION
    Checks registry, Program Files, and common installation paths for:
    - Meta Quest Link
    - HTC Vive / SteamVR
    - Pimax
    
    .OUTPUTS
    Array of installed headset names: @("MetaQuest") or @("HTCVive", "Pimax") etc
    #>
    
    $installed = @()
    
    # Check Meta Quest
    if (Test-MetaQuestInstalled) {
        $installed += "MetaQuest"
    }
    
    # Check HTC Vive / SteamVR
    if (Test-SteamVRInstalled) {
        $installed += "HTCVive"
    }
    
    # Check Pimax
    if (Test-PimaxInstalled) {
        $installed += "Pimax"
    }
    
    return $installed
}

function Test-MetaQuestInstalled {
    <#
    .SYNOPSIS
    Tests if Meta Quest Link software is installed
    #>
    
    # Check registry
    try {
        $regPath = "HKLM:\SOFTWARE\Meta"
        if (Test-Path $regPath) {
            return $true
        }
    } catch {}
    
    # Check common installation paths
    $paths = @(
        "C:\Program Files\Meta\MetaQuestLink\MetaQuestLink.exe",
        "$env:PROGRAMFILES\Meta\MetaQuestLink\MetaQuestLink.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    return $false
}

function Test-SteamVRInstalled {
    <#
    .SYNOPSIS
    Tests if SteamVR (used by HTC Vive, Valve Index) is installed
    #>
    
    # Check registry for Steam installation
    try {
        $steamPath = Get-SteamInstallPath
        if ($steamPath) {
            $steamVRPath = Join-Path $steamPath "steamapps\common\SteamVR"
            if (Test-Path $steamVRPath) {
                return $true
            }
        }
    } catch {}
    
    return $false
}

function Test-PimaxInstalled {
    <#
    .SYNOPSIS
    Tests if Pimax software is installed
    #>
    
    # Check common installation paths
    $paths = @(
        "C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe",
        "$env:PROGRAMFILES\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    # Check registry
    try {
        $regPath = "HKLM:\SOFTWARE\Pimax"
        if (Test-Path $regPath) {
            return $true
        }
    } catch {}
    
    return $false
}

# ============================================
# PATH RESOLUTION
# ============================================

function Get-MetaQuestPath {
    <#
    .SYNOPSIS
    Returns path to MetaQuestLink.exe
    
    .OUTPUTS
    Full path to executable or empty string if not found
    #>
    
    # Try standard paths first
    $standardPaths = @(
        "C:\Program Files\Meta\MetaQuestLink\MetaQuestLink.exe",
        "$env:PROGRAMFILES\Meta\MetaQuestLink\MetaQuestLink.exe"
    )
    
    foreach ($path in $standardPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to get from registry
    try {
        $metaReg = Get-ItemProperty "HKLM:\SOFTWARE\Meta" -ErrorAction SilentlyContinue
        if ($metaReg -and $metaReg.InstallPath) {
            $exePath = Join-Path $metaReg.InstallPath "MetaQuestLink.exe"
            if (Test-Path $exePath) {
                return $exePath
            }
        }
    } catch {}
    
    return ""
}

function Get-SteamInstallPath {
    <#
    .SYNOPSIS
    Returns path to Steam installation directory
    
    .OUTPUTS
    Full path to Steam directory or empty string if not found
    #>
    
    try {
        $steamReg = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue
        if ($steamReg -and $steamReg.InstallPath) {
            return $steamReg.InstallPath
        }
    } catch {}
    
    # Fallback to common installation path
    $defaultPath = "C:\Program Files (x86)\Steam"
    if (Test-Path $defaultPath) {
        return $defaultPath
    }
    
    return ""
}

function Get-SteamVRPath {
    <#
    .SYNOPSIS
    Returns path to SteamVR root directory
    
    .OUTPUTS
    Full path to SteamVR directory or empty string if not found
    #>
    
    $steamPath = Get-SteamInstallPath
    if ($steamPath) {
        $steamVRPath = Join-Path $steamPath "steamapps\common\SteamVR"
        if (Test-Path $steamVRPath) {
            return $steamVRPath
        }
    }
    
    return ""
}

function Get-PimaxPath {
    <#
    .SYNOPSIS
    Returns path to PimaxClient.exe
    
    .OUTPUTS
    Full path to executable or empty string if not found
    #>
    
    $standardPaths = @(
        "C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe",
        "$env:PROGRAMFILES\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
    )
    
    foreach ($path in $standardPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try registry
    try {
        $pimaxReg = Get-ItemProperty "HKLM:\SOFTWARE\Pimax" -ErrorAction SilentlyContinue
        if ($pimaxReg -and $pimaxReg.InstallPath) {
            $exePath = Join-Path $pimaxReg.InstallPath "PimaxClient\pimaxui\PimaxClient.exe"
            if (Test-Path $exePath) {
                return $exePath
            }
        }
    } catch {}
    
    return ""
}

function Get-HeadsetPath {
    <#
    .SYNOPSIS
    Returns path to headset executable based on headset type
    
    .PARAMETER Headset
    Headset type: MetaQuest, HTCVive, or Pimax
    
    .OUTPUTS
    Full path to executable or empty string if not found
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('MetaQuest', 'HTCVive', 'Pimax')]
        [string]$Headset
    )
    
    switch ($Headset) {
        'MetaQuest' { return Get-MetaQuestPath }
        'HTCVive' { return Get-SteamVRPath }
        'Pimax' { return Get-PimaxPath }
        default { return "" }
    }
}

# ============================================
# SETTINGS BACKUP CONFIGURATION
# ============================================

function Get-VRBackupGroups {
    <#
    .SYNOPSIS
    Returns backup group definitions for installed VR headsets only
    
    .DESCRIPTION
    Returns array of backup groups with conditional inclusion based on
    whether the headset is actually installed. Only includes groups where
    at least one file/folder exists to avoid [SKIP] messages for non-existent VR setups.
    
    .OUTPUTS
    Array of backup group objects with Label, Files, and Folders (only enabled headsets)
    #>
    
    # Get Steam path for VR group
    $steamRoot = Get-SteamInstallPath
    $groups = @()
    
    # Meta Quest - only add if settings file exists
    if (Test-Path "$env:APPDATA\Meta\MetaQuestLink\settings.json") {
        $groups += @{
            Label = "Meta Quest Settings"
            Files = @(
                "$env:APPDATA\Meta\MetaQuestLink\settings.json"
            )
            Folders = @()
        }
    }
    
    # HTC Vive / SteamVR - only add if config exists
    if ($steamRoot -and (Test-Path (Join-Path $steamRoot "config\steamvr.vrsettings"))) {
        $groups += @{
            Label = "HTC Vive / SteamVR Settings"
            Files = @(
                Join-Path $steamRoot "config\steamvr.vrsettings"
            )
            Folders = @()
        }
    }
    
    # Pimax - only add if config exists
    if ((Test-Path "$env:USERPROFILE\AppData\Local\Pimax\runtime\profile.json") -or 
        (Test-Path "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\Common Setting.json")) {
        $groups += @{
            Label = "Pimax VR"
            Files = @(
                "$env:USERPROFILE\AppData\Local\Pimax\runtime\profile.json",
                "$env:USERPROFILE\AppData\Roaming\PiTool\manifest\PiTool\Common Setting.json"
            )
            Folders = @()
        }
    }
    
    return $groups
}

# ============================================
# EXPORTS
# ============================================

Export-ModuleMember -Function @(
    'Detect-InstalledHeadsets',
    'Get-MetaQuestPath',
    'Get-SteamInstallPath',
    'Get-SteamVRPath',
    'Get-PimaxPath',
    'Get-HeadsetPath',
    'Get-VRBackupGroups',
    'Test-MetaQuestInstalled',
    'Test-SteamVRInstalled',
    'Test-PimaxInstalled'
)
