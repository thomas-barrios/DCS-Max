# DCS-Max Configuration Parser
# Purpose: Shared functions for reading/writing performance-optimizations.ini
# Format: O&O ShutUp10-style (ID<tab>+/-<tab># Description)
#
# Usage:
#   . .\Assets\config-parser.ps1
#   $config = Get-OptimizationConfig
#   if ($config["R001"]) { # Apply optimization R001 }

function Get-OptimizationConfigPath {
    <#
    .SYNOPSIS
        Returns the path to the performance-optimizations.ini file
    #>
    param(
        [string]$ScriptDir = $PSScriptRoot
    )
    
    # Navigate from Assets or 5-Optimization to find the config
    $rootDir = Split-Path -Parent $ScriptDir
    
    # Try 5-Optimization folder first
    $configPath = Join-Path $rootDir "5-Optimization\performance-optimizations.ini"
    if (Test-Path $configPath) {
        return $configPath
    }
    
    # Try current directory (if script is in 5-Optimization)
    $configPath = Join-Path $ScriptDir "performance-optimizations.ini"
    if (Test-Path $configPath) {
        return $configPath
    }
    
    # Try parent's 5-Optimization (if script is in a subfolder)
    $configPath = Join-Path (Split-Path -Parent $rootDir) "5-Optimization\performance-optimizations.ini"
    if (Test-Path $configPath) {
        return $configPath
    }
    
    return $null
}

function Get-OptimizationConfig {
    <#
    .SYNOPSIS
        Parses the performance-optimizations.ini file and returns a hashtable of enabled optimizations
    
    .DESCRIPTION
        Reads the O&O ShutUp10-style configuration file and returns a hashtable where:
        - Keys are optimization IDs (R001, S001, T001, C001, etc.)
        - Values are $true (enabled, +) or $false (disabled, -)
        
        If the config file doesn't exist, returns an empty hashtable (all items default to enabled)
    
    .PARAMETER ConfigPath
        Optional path to the config file. If not specified, searches for it automatically.
    
    .OUTPUTS
        Hashtable of optimization ID -> enabled state
    
    .EXAMPLE
        $config = Get-OptimizationConfig
        if ($config["R001"] -ne $false) {
            # Apply R001 optimization (defaults to enabled if not in config)
        }
    #>
    param(
        [string]$ConfigPath = $null
    )
    
    $config = @{}
    
    # Find config file if not specified
    if (-not $ConfigPath) {
        $ConfigPath = Get-OptimizationConfigPath -ScriptDir $PSScriptRoot
    }
    
    # If no config file exists, return empty hashtable (all defaults to enabled)
    if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
        return $config
    }
    
    # Parse the config file
    Get-Content $ConfigPath | ForEach-Object {
        $line = $_.Trim()
        
        # Skip empty lines and comments
        if ($line -eq "" -or $line.StartsWith("#") -or $line.StartsWith("=")) {
            return
        }
        
        # Parse format: ID<tab>+/-<tab># Description
        # Also handle spaces as separator for flexibility
        if ($line -match "^([A-Z]\d{3})\s+([+-])\s+#") {
            $id = $matches[1]
            $enabled = $matches[2] -eq "+"
            $config[$id] = $enabled
        }
    }
    
    return $config
}

function Test-OptimizationEnabled {
    <#
    .SYNOPSIS
        Checks if a specific optimization is enabled
    
    .DESCRIPTION
        Returns $true if the optimization should be applied.
        If the ID is not in the config, defaults to $true (enabled).
    
    .PARAMETER Config
        Hashtable from Get-OptimizationConfig
    
    .PARAMETER Id
        Optimization ID (e.g., R001, S001, T001)
    
    .OUTPUTS
        Boolean - $true if enabled, $false if disabled
    
    .EXAMPLE
        $config = Get-OptimizationConfig
        if (Test-OptimizationEnabled -Config $config -Id "R001") {
            # Apply R001 optimization
        }
    #>
    param(
        [hashtable]$Config,
        [string]$Id
    )
    
    # If not in config or config is empty, default to enabled
    if (-not $Config.ContainsKey($Id)) {
        return $true
    }
    
    return $Config[$Id]
}

function Set-OptimizationConfig {
    <#
    .SYNOPSIS
        Writes optimization settings to the config file
    
    .DESCRIPTION
        Updates the performance-optimizations.ini file with new enabled/disabled states.
        Preserves comments and formatting.
    
    .PARAMETER ConfigPath
        Path to the config file
    
    .PARAMETER Id
        Optimization ID to update
    
    .PARAMETER Enabled
        $true for enabled (+), $false for disabled (-)
    
    .EXAMPLE
        Set-OptimizationConfig -Id "R001" -Enabled $false
    #>
    param(
        [string]$ConfigPath = $null,
        [string]$Id,
        [bool]$Enabled
    )
    
    if (-not $ConfigPath) {
        $ConfigPath = Get-OptimizationConfigPath -ScriptDir $PSScriptRoot
    }
    
    if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
        Write-Warning "Config file not found: $ConfigPath"
        return $false
    }
    
    $newState = if ($Enabled) { "+" } else { "-" }
    $content = Get-Content $ConfigPath
    $updated = $false
    
    $newContent = $content | ForEach-Object {
        if ($_ -match "^$Id\s+[+-]\s+#") {
            $updated = $true
            $_ -replace "^($Id\s+)[+-](\s+#)", "`$1$newState`$2"
        } else {
            $_
        }
    }
    
    if ($updated) {
        $newContent | Set-Content $ConfigPath -Encoding UTF8
        return $true
    }
    
    return $false
}

# Export functions for module use
Export-ModuleMember -Function Get-OptimizationConfig, Get-OptimizationConfigPath, Test-OptimizationEnabled, Set-OptimizationConfig -ErrorAction SilentlyContinue
