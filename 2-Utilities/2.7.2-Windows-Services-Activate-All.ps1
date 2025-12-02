# =====================================================
# Start-And-Enable-AllServices.ps1
# What it does:
#   • If a service is Disabled  → Sets it to Automatic + Starts it
#   • If a service is Stopped   → Starts it
#   • Shows clear before/after status
# Requires: Run as Administrator
# =====================================================

# Force Administrator check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Cyan
    Pause
    exit 1
}

Write-Host "=== ENABLE AND START ALL POSSIBLE WINDOWS SERVICES ===" -ForegroundColor Cyan
Write-Host "Working... This may take 1-2 minutes`n" -ForegroundColor Yellow

$services = Get-WmiObject Win32_Service | Select-Object Name, DisplayName, State, StartMode, PathName

$changed = 0
$started = 0
$failed  = @()

foreach ($svc in $services) {
    $name = $svc.Name
    $display = $svc.DisplayName
    $currentMode = $svc.StartMode
    $currentState = $svc.State

    # Skip services that are part of drivers or have no valid path (usually can't be changed)
    if ($svc.PathName -like "*\Driver\*") { continue }
    if ($svc.PathName -like "*\driver\*") { continue }

    $needsChange = $false

    # Do we need to touch this service?

    # 1. If service is Disabled → Enable it (set to Automatic)
    if ($currentMode -eq "Disabled") {
        Write-Host "Enabling  → $display ($name)" -ForegroundColor Magenta
        try {
            Set-Service -Name $name -StartupType Automatic -ErrorAction Stop
            $changed++
            $needsChange = $true
        }
        catch {
            Write-Host "    FAILED to enable: $($_.Exception.Message)" -ForegroundColor Cyan
            $failed += "$display ($name) → Enable failed"
            continue
        }
    }

    # 2. If service is Stopped (or was just enabled) → Start it
    if ($currentState -eq "Stopped" -or $needsChange) {
        Write-Host "Starting  → $display ($name)" -ForegroundColor Yellow
        try {
            Start-Service -Name $name -ErrorAction Stop
            Write-Host "    Started successfully" -ForegroundColor Green
            $started++
        }
        catch {
            Write-Host "    FAILED to start: $($_.Exception.Message)" -ForegroundColor Cyan
            $failed += "$display ($name) → Start failed"
        }
    }
    else {
        # Already running and not disabled → nothing to do
        Write-Host "Running   → $display" -ForegroundColor Gray
    }
}

# ====================== FINAL REPORT ======================
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                     SUMMARY"                              -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Services enabled (were Disabled) : $changed"  -ForegroundColor Magenta
Write-Host "Services started                 : $started" -ForegroundColor Green
Write-Host "Total services processed         : $($services.Count)"
if ($failed.Count -gt 0) {
    Write-Host "`nFailed operations ($($failed.Count)):" -ForegroundColor Cyan
    $failed | ForEach-Object { Write-Host "   • $_" }
}
else {
    Write-Host "`nAll possible services are now ENABLED and RUNNING!" -ForegroundColor Green
}

Write-Host "`nScript finished. A reboot is recommended for full effect." -ForegroundColor Cyan
Pause