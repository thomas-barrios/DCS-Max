<#=====================================================================
  Restore-BrokenMicrosoftStore.ps1
  Reverts your system to the exact "Microsoft Store NOT working" state
  (matches your services1.txt configuration)
  Run as Administrator!  (Right-click PowerShell --> Run as administrator)
=====================================================================#>

# List of services that must be in the BROKEN state (exactly like services1.txt)
$BrokenConfig = @{
    # Service Name                             = @{ StartupType ; Status ("Running" or $null = Stopped) }

    # === Critical ones that break the Store ===
    "wlidsvc"                                 = @{ StartupType = "Disabled";  Status = $null }      # Microsoft Account Sign-in Assistant
    "DiagTrack"                               = @{ StartupType = "Disabled";  Status = $null }      # Connected User Experiences and Telemetry

    # === The rest — exactly as they were in services1.txt (non-working) ===
    "AMD 3D V-Cache Performance Optimizer Service" = @{ StartupType = "Disabled"; Status = $null }
    "AMD Application Compatibility Database Service" = @{ StartupType = "Disabled"; Status = $null }
    "AMD Provisioning Packages Service"     = @{ StartupType = "Disabled"; Status = $null }
    "AsusUpdateCheck"                        = @{ StartupType = "Disabled"; Status = $null }
    "AssignedAccessManager Service"          = @{ StartupType = "Disabled"; Status = $null }
    "Auto Time Zone Updater"                 = @{ StartupType = "Disabled"; Status = $null }
    "AVCTP service"                          = @{ StartupType = "Disabled"; Status = $null }
    "Connected User Experiences and Telemetry" = @{ StartupType = "Disabled"; Status = $null }
    "Diagnostic Policy Service"              = @{ StartupType = "Disabled"; Status = $null }
    "Diagnostic Service Host"                = @{ StartupType = "Disabled"; Status = $null }
    "Diagnostic System Host"                 = @{ StartupType = "Disabled"; Status = $null }
    "DialogBlockingService"                  = @{ StartupType = "Disabled"; Status = $null }
    "Distributed Link Tracking Client"       = @{ StartupType = "Disabled"; Status = $null }
    "Downloaded Maps Manager"                = @{ StartupType = "Disabled"; Status = $null }
    "File History Service"                   = @{ StartupType = "Disabled"; Status = $null }
    "Function Discovery Resource Publication" = @{ StartupType = "Disabled"; Status = $null }
    "Geolocation Service"                    = @{ StartupType = "Disabled"; Status = $null }
    "Microsoft App-V Client"                 = @{ StartupType = "Disabled"; Status = $null }
    "Net.Tcp Port Sharing Service"           = @{ StartupType = "Disabled"; Status = $null }
    "Network Connected Devices Auto-Setup"   = @{ StartupType = "Disabled"; Status = $null }
    "Parental Controls"                      = @{ StartupType = "Disabled"; Status = $null }
    "Payments and NFC/SE Manager"            = @{ StartupType = "Disabled"; Status = $null }
    "Power"                                  = @{ StartupType = "Disabled"; Status = $null }
    "Print Spooler"                          = @{ StartupType = "Disabled"; Status = $null }
    "Printer Extensions and Notifications"  = @{ StartupType = "Disabled"; Status = $null }
    "Problem Reports Control Panel Support"  = @{ StartupType = "Disabled"; Status = $null }
    "Quality Windows Audio Video Experience" = @{ StartupType = "Disabled"; Status = $null }
    "Realtek Audio Universal Service"        = @{ StartupType = "Disabled"; Status = $null }
    "Remote Desktop Configuration"           = @{ StartupType = "Disabled"; Status = $null }
    "Remote Desktop Services"               = @{ StartupType = "Disabled"; Status = $null }
    "Remote Registry"                        = @{ StartupType = "Disabled"; Status = $null }
    "Retail Demo Service"                    = @{ StartupType = "Disabled"; Status = $null }
    "Routing and Remote Access"              = @{ StartupType = "Disabled"; Status = $null }
    "Secure Socket Tunneling Protocol Service" = @{ StartupType = "Disabled"; Status = $null }
    "Sensor Data Service"                    = @{ StartupType = "Disabled"; Status = $null }
    "Sensor Monitoring Service"              = @{ StartupType = "Disabled"; Status = $null }
    "Sensor Service"                         = @{ StartupType = "Disabled"; Status = $null }
    "Smart Card"                             = @{ StartupType = "Disabled"; Status = $null }
    "Smart Card Device Enumeration Service"  = @{ StartupType = "Disabled"; Status = $null }
    "Smart Card Removal Policy"              = @{ StartupType = "Disabled"; Status = $null }
    "SSDP Discovery"                         = @{ StartupType = "Disabled"; Status = $null }
    "UPnP Device Host"                       = @{ StartupType = "Disabled"; Status = $null }
    "WalletService"                          = @{ StartupType = "Disabled"; Status = $null }
    "WebClient"                              = @{ StartupType = "Disabled"; Status = $null }
    "Wi-Fi Direct Services Connection Manager Service" = @{ StartupType = "Disabled"; Status = $null }
    "Windows Camera Frame Server"            = @{ StartupType = "Manual";    Status = "Running" }  # was Running in broken config
    "Windows Defender Advanced Threat Protection Service" = @{ StartupType = "Disabled"; Status = $null }
    "Windows Image Acquisition (WIA)"        = @{ StartupType = "Disabled"; Status = $null }
    "Windows Insider Service"                = @{ StartupType = "Disabled"; Status = $null }
    "Windows Push Notifications System Service" = @{ StartupType = "Disabled"; Status = $null }
    "Windows Remote Management (WS-Management)" = @{ StartupType = "Disabled"; Status = $null }
    "Windows Search"                         = @{ StartupType = "Disabled"; Status = $null }
    "Work Folders"                           = @{ StartupType = "Disabled"; Status = $null }
    "Xbox Accessory Management Service"      = @{ StartupType = "Disabled"; Status = $null }
    "Xbox Live Auth Manager"                 = @{ StartupType = "Disabled"; Status = $null }
    "Xbox Live Game Save"                    = @{ StartupType = "Disabled"; Status = $null }
    "Xbox Live Networking Service"           = @{ StartupType = "Disabled"; Status = $null }
}

# =================================================================
# Apply the broken configuration
# =================================================================
$Changes = 0

foreach ($Name in $BrokenConfig.Keys) {
    $Target = $BrokenConfig[$Name]

    # Resolve display name --> service name if needed (most are already exact)
    $Svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $Svc) {
        # Try by display name (a few services have different internal names)
        $Svc = Get-Service | Where-Object { $_.DisplayName -eq $Name } | Select-Object -First 1
    }

    if (-not $Svc) {
        Write-Warning "Not found on this system --> $Name"
        continue
    }

    $RealName = $Svc.Name

    # --- Startup Type ---
    $CurrentStartType = (Get-CimInstance Win32_Service -Filter "Name='$RealName'").StartMode
    $Map = @{'Auto'='Automatic'; 'Disabled'='Disabled'; 'Manual'='Manual'}
    $CurrentNormalized = $Map[$CurrentStartType]

    if ($CurrentNormalized -ne $Target.StartupType) {
        Write-Host "[$RealName] Startup --> $($Target.StartupType)" -ForegroundColor Cyan
        Set-Service -Name $RealName -StartupType $Target.StartupType
        $Changes++
    }

    # --- Running / Stopped ---
    $ShouldRun = $Target.Status -eq "Running"
    $IsRunning = $Svc.Status -eq "Running"

    if ($IsRunning -and -not $ShouldRun) {
        Write-Host "[$RealName] Stopping" -ForegroundColor Yellow
        Stop-Service -Name $RealName -Force -ErrorAction SilentlyContinue
        $Changes++
    }
    elseif (-not $IsRunning -and $ShouldRun) {
        Write-Host "[$RealName] Starting" -ForegroundColor Green
        Start-Service -Name $RealName -ErrorAction SilentlyContinue
        $Changes++
    }
}

Write-Host "`nDone! $Changes changes applied." -ForegroundColor Red
Write-Host "Microsoft Store is now BROKEN again (exactly like your services1.txt state)." -ForegroundColor Red
Write-Host "Reboot recommended." -ForegroundColor Yellow