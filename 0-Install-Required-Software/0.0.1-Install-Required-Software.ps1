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

# Install CapFrameX
Write-Host "Installing CapFrameX..."
winget install --id=CXWorld.CapFrameX --exact --scope=user

# Install AutoHotkey
Write-Host "Installing AutoHotkey..."
winget install --id=AutoHotkey.AutoHotkey --exact --scope=user

# Install Notepad++
Write-Host "Installing Notepad++..."
winget install --id=Notepad++.Notepad++ --exact --scope=user

Write-Host "Installation complete. Please launch each application to complete setup."