# Create Windows System Restore Point for DCS-Max
# Optional: -NoPause to skip the pause at end (for automation/UI)

param([switch]$NoPause = $false)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"

# Header
Write-Host ""
Write-Host "[RESTORE POINT] Windows System Restore Point" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor DarkGray
Write-Host "[DATE]   $timestamp" -ForegroundColor Gray
Write-Host "------------------------------------------------" -ForegroundColor DarkGray

try {
    # Create restore point
    Checkpoint-Computer -Description "DCS-Max Operation - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "[OK]     System restore point created" -ForegroundColor Green
    
    # Summary
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[DONE]   Restore point creation complete" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "[FAIL]   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    if (-not $NoPause) { Pause }
    exit 1
}
if (-not $NoPause) { Pause }