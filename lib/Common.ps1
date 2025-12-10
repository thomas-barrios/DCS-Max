# DCS-Max Common Library Functions
# Shared utilities used across multiple scripts

# Helper function to check if optimization is enabled
# Supports both old boolean format and new object format with 'enabled' property
function Test-OptEnabled {
    param([string]$Id, $configData)

    if ($configData -eq $null) { return $true }
    if ($configData.Count -eq 0) { return $true }

    # Handle both hashtable and PSCustomObject
    if ($configData -is [hashtable]) {
        if (-not $configData.ContainsKey($Id)) { return $true }
        $opt = $configData[$Id]
    } else {
        # PSCustomObject
        if (-not $configData.PSObject.Properties.Name.Contains($Id)) { return $true }
        $opt = $configData.$Id
    }

    # Handle both old boolean format and new object format
    if ($opt -is [bool]) {
        return $opt
    } elseif ($opt -is [object] -and $opt.enabled -ne $null) {
        return $opt.enabled
    }
    return $true  # Default to enabled if format is unrecognized
}

# Helper function to load configuration with error handling
function Load-ConfigFile {
    param([string]$configPath, [string]$configName)

    if (-not (Test-Path $configPath)) {
        Write-Host "Warning: $configName not found at $configPath" -ForegroundColor Yellow
        return $null
    }

    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-Host "Loaded $configName from $configPath" -ForegroundColor Gray
        return $config
    } catch {
        Write-Host "Error: Failed to load $configName from $configPath`: $_" -ForegroundColor Red
        return $null
    }
}

# Helper function to get script root directory consistently
function Get-ScriptRoot {
    param([string]$scriptPath = $MyInvocation.MyCommand.Path)

    $scriptDir = Split-Path -Parent $scriptPath
    $rootDir = Split-Path -Parent $scriptDir
    return $rootDir
}

# Helper function to expand environment variables in paths
function Expand-ConfigPath {
    param([string]$path)

    if ([string]::IsNullOrEmpty($path)) {
        return $path
    }

    return [Environment]::ExpandEnvironmentVariables($path)
}

