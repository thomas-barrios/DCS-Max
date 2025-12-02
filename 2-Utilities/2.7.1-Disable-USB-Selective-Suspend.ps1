#Requires -RunAsAdministrator
<#
    Disable-UsbPowerSaving.ps1

    - Disables "Allow the computer to turn off this device to save power"
      for USB Root Hub / Generic USB Hub devices (registry).
    - Disables USB Selective Suspend in the current power plan (AC + DC).

    Use: Run from an elevated PowerShell window.
#>

Write-Host "=== Disabling USB power saving & selective suspend ===`n"

# -----------------------------
# 1) Disable USB Selective Suspend (Power Options)
# -----------------------------

try {
    # Get current active power scheme GUID
    $schemeLine = powercfg -getactivescheme 2>$null
    if ($schemeLine -match 'GUID:\s*([a-fA-F0-9-]+)') {
        $currentScheme = $matches[1]
        Write-Host "Current power scheme: $currentScheme"

        # USB subgroup + USB selective suspend setting GUIDs
        $subUsbGuid   = '4f971e89-eebd-4455-a8de-9e59040e7347'  # SUB_USB
        $usbSsGuid    = '2a737441-1930-4402-8d77-b2bebba308a3'  # USB Selective Suspend

        Write-Host "Disabling USB selective suspend for AC..."
        powercfg -setacvalueindex $currentScheme $subUsbGuid $usbSsGuid 0

        Write-Host "Disabling USB selective suspend for DC (battery)..."
        powercfg -setdcvalueindex $currentScheme $subUsbGuid $usbSsGuid 0

        # Re-activate the scheme to apply changes
        powercfg -S $currentScheme
        Write-Host "USB selective suspend set to: Disabled (AC + DC).`n"
    } else {
        Write-Warning "Could not detect active power scheme. Skipping powercfg changes."
    }
}
catch {
    Write-Warning "Error while configuring USB selective suspend: $($_.Exception.Message)"
}

# -----------------------------
# 2) Disable per-device USB hub power saving (registry)
#    (Equivalent to unchecking 'Allow the computer to turn off this device')
# -----------------------------

# Target name fragments for USB hubs
$targetNames = @(
    'USB Root Hub',
    'Generic USB Hub'
)

# Registry roots where USB controllers/hubs live
$enumPaths = @(
    'HKLM:\SYSTEM\CurrentControlSet\Enum\USB',
    'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI'
)

function Set-UsbHubPowerManagement {
    param(
        [string]$KeyPath
    )

    try {
        $props = Get-ItemProperty -Path $KeyPath -ErrorAction Stop
    } catch {
        return
    }

    # Try to identify the device by FriendlyName or DeviceDesc
    $nameParts = @()
    if ($props.PSObject.Properties.Name -contains 'FriendlyName') {
        $nameParts += $props.FriendlyName
    }
    if ($props.PSObject.Properties.Name -contains 'DeviceDesc') {
        $nameParts += $props.DeviceDesc
    }
    $fullName = ($nameParts -join ' ') -as [string]

    if ([string]::IsNullOrWhiteSpace($fullName)) {
        return
    }

    foreach ($pattern in $targetNames) {
        if ($fullName -like "*$pattern*") {
            Write-Host "Configuring power settings for: $fullName"
            $devParamsKey = Join-Path $KeyPath 'Device Parameters'

            if (-not (Test-Path $devParamsKey)) {
                New-Item -Path $devParamsKey -Force | Out-Null
            }

            # These values are used by many USB devices to control selective suspend.
            # Set them to 0 to effectively prevent Windows from putting them to sleep.
            New-ItemProperty -Path $devParamsKey -Name 'DeviceSelectiveSuspended' -PropertyType DWord -Value 0 -Force | Out-Null
            New-ItemProperty -Path $devParamsKey -Name 'SelectiveSuspendEnabled'  -PropertyType DWord -Value 0 -Force | Out-Null

            Write-Host "  -> DeviceSelectiveSuspended = 0"
            Write-Host "  -> SelectiveSuspendEnabled  = 0`n"
            break
        }
    }
}

Write-Host "Scanning registry for USB Root Hubs / Generic USB Hubs..."

foreach ($root in $enumPaths) {
    if (-not (Test-Path $root)) { continue }

    Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        # Only process leaf keys (with properties) – others will be containers
        try {
            $null = Get-ItemProperty -Path $_.PSPath -ErrorAction Stop
            Set-UsbHubPowerManagement -KeyPath $_.PSPath
        } catch {
            # Ignore keys we can't read
        }
    }
}

Write-Host "`n=== Done. Reboot Windows for all changes to take full effect. ==="
