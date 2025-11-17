# PowerShell function to parse INI files (built-in, no modules needed)
function Get-IniContent {
    param([string]$FilePath)
    $ini = @{}
    $section = ""
    Get-Content $FilePath | ForEach-Object {
        $line = $_.Trim()
        if ($line -match "^\[(.+)\]$") {
            $section = $matches[1]
            $ini[$section] = @{}
        } elseif ($line -match "^(.+?)\s*=\s*(.+)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($section) {
                $ini[$section][$key] = $value
            }
        }
    }
    return $ini
}

# Load config
$config = Get-IniContent -FilePath "master-config.ini"

# Access settings (split comma-separated lists)
$backupFiles = $config["backup"]["FilesToBackup"] -split ","
Write-Host "Backup files: $backupFiles"

$services = $config["optimization"]["ServicesToOptimize"] -split ","
Write-Host "Services to optimize: $services"

# Access registry settings
$registryList = $config["optimization"]["WindowsRegistryToOptimize"] -split ","
Write-Host "Registry settings to optimize: $registryList"

# Find and display registry keys and values
$registrySections = $config.Keys | Where-Object { $_ -like "registry.*" }
foreach ($section in $registrySections) {
    Write-Host "Registry section: $section"
    foreach ($key in $config[$section].Keys) {
        $value = $config[$section][$key]
        Write-Host "  $key = $value"
    }
}

# Function to update registry keys with values from config
function Update-RegistryFromConfig {
    param([hashtable]$Config, [switch]$WhatIf)
    
    $registrySections = $Config.Keys | Where-Object { $_ -like "registry.*" }
    foreach ($section in $registrySections) {
        # Extract the registry path from the section name (remove 'registry."' and trailing '"')
        $regPath = $section -replace '^registry\."', '' -replace '"$', ''
        Write-Host "Processing registry path: $regPath"
        
        foreach ($key in $Config[$section].Keys) {
            $value = $Config[$section][$key]
            # Skip comments (lines starting with #)
            if ($key -notmatch '^#') {
                try {
                    if ($WhatIf) {
                        Write-Host "  [WHATIF] Would set $regPath\$key = $value"
                    } else {
                        Set-ItemProperty -Path "Registry::$regPath" -Name $key -Value $value -Type DWord -ErrorAction Stop
                        Write-Host "  [OK] Set $regPath\$key = $value"
                    }
                } catch {
                    Write-Host "  [ERROR] Failed to set $regPath\$key = $value : $_"
                }
            }
        }
    }
}

# Example usage: Update registry (use -WhatIf for dry run)
Update-RegistryFromConfig -Config $config -WhatIf
# Update-RegistryFromConfig -Config $config  # Uncomment to apply changes