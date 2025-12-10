# Minimal Path Resolver for DCS-Max
# Single function: Get-DCSLocation - discovers DCS Saved Games across multi-computer setups

function Get-DCSLocation {
    <#
    .SYNOPSIS
        Discovers DCS Saved Games folder across different drives and user profiles
    
    .DESCRIPTION
        Scans D:\, E:\, then C:\ for Users\*\Saved Games\DCS
        Returns first valid path found, or fallback to standard location
    
    .OUTPUTS
        String: Path to Saved Games folder (parent of DCS folder)
    #>
    
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
