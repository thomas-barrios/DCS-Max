# Minimal Path Resolver for DCS-Max
# Single function: Get-DCSLocation - returns Saved Games base folder

function Get-DCSLocation {
    <#
    .SYNOPSIS
        Discovers DCS Saved Games folder across different drives and user profiles
    
    .DESCRIPTION
        First reads config-global.json's paths.savedGamesPath and returns its parent (Saved Games).
        If not configured, scans D:\, E:\, then C:\ for Users\*\Saved Games\DCS.
        Returns first valid path found, or fallback to standard location.
    
    .OUTPUTS
        String: Path to Saved Games folder (parent of DCS folder)
    #>
    
    # Prefer value from config-global.json if available
    try {
        $configPath = Join-Path $PSScriptRoot "..\config-global.json"
        if (Test-Path $configPath) {
            $cfg = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            if ($cfg.paths -and $cfg.paths.savedGamesPath) {
                $sg = [Environment]::ExpandEnvironmentVariables($cfg.paths.savedGamesPath)
                if (-not [string]::IsNullOrWhiteSpace($sg)) {
                    $sg = $sg.TrimEnd('\\')
                    # Return the parent Saved Games folder if a DCS profile is provided
                    $parent = Split-Path -Path $sg -Parent
                    if (Test-Path $parent) { return $parent }
                    return $parent
                }
            }
        }
    } catch { }

    $drives = @("D", "E", "C")
    
    foreach ($drive in $drives) {
        $drivePath = "$($drive):\Users"
        
        if (-not (Test-Path $drivePath)) { continue }
        
        # For C: drive, check current user first
        if ($drive -eq "C") {
            $testPath = Join-Path $env:USERPROFILE "Saved Games\DCS"
            if (Test-Path $testPath) {
                return Join-Path $env:USERPROFILE "Saved Games"
            }
            continue
        }
        
        # For D: and E: drives, scan all user folders
        try {
            $users = Get-ChildItem -Path $drivePath -Directory -ErrorAction SilentlyContinue
            foreach ($user in $users) {
                $testPath = Join-Path $user.FullName "Saved Games\DCS"
                if (Test-Path $testPath) {
                    return Join-Path $user.FullName "Saved Games"
                }
            }
        } catch {
            Write-Host "Warning: Failed to search drive $drive for DCS Saved Games: $_" -ForegroundColor Yellow
        }
    }
    
    # Fallback: standard location
    return Join-Path $env:USERPROFILE "Saved Games"
}

function Expand-ConfigPath {
    <#
    .SYNOPSIS
        Expands environment variables in config paths
    
    .OUTPUTS
        String: Expanded path
    #>
    param([string]$Path)
    
    $Path = $Path -replace '%USERPROFILE%', $env:USERPROFILE
    $Path = $Path -replace '%ProgramFiles%', $env:ProgramFiles
    $Path = $Path -replace '%ProgramFiles\(x86\)%', ${env:ProgramFiles(x86)}
    $Path = $Path -replace '%USERNAME%', $env:USERNAME
    
    return $Path
}
