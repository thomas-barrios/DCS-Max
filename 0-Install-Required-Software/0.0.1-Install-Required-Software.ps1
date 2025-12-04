# DCS-Max Required Software Installer
# Installs CapFrameX, AutoHotkey, and Notepad++ using winget (user scope)

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Write-Host "Installing required software for DCS-Max..."

# Check if winget is available
try {
    winget --version > $null 2>&1
} catch {
    Write-Host "Error: winget is not available. Please install Windows Package Manager first." -ForegroundColor Red
    exit 1
}

Write-Host "Winget found. Proceeding with installations..."

# Common flags to prevent hangs and prompts
$wingetFlags = "--exact --scope=user --accept-package-agreements --accept-source-agreements --silent"

# Install CapFrameX
Write-Host "Installing CapFrameX..."
Invoke-Expression "winget install --id=CXWorld.CapFrameX $wingetFlags"

# Install AutoHotkey
Write-Host "Installing AutoHotkey..."
Invoke-Expression "winget install --id=AutoHotkey.AutoHotkey $wingetFlags"

# Install Notepad++
Write-Host "Installing Notepad++..."
Invoke-Expression "winget install --id=Notepad++.Notepad++ $wingetFlags"

Write-Host "Installation complete. Please launch each application to complete setup."