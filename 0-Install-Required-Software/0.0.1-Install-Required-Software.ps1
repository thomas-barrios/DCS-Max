# DCS-Max Required Software Installer
# Smart installer that checks existing software and installs only what's needed

# Assures administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Write-Host "🔧 DCS-Max Software & Configuration Setup" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if winget is available
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
try {
    winget --version > $null 2>&1
    Write-Host "✅ Windows Package Manager (winget): Available" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Windows Package Manager (winget) is not available." -ForegroundColor Red
    Write-Host "   Please install it from Microsoft Store first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Function to check if software is installed
function Test-SoftwareInstalled {
    param([string]$PackageId)
    try {
        $result = winget list --id $PackageId --exact 2>$null
        return $result -match $PackageId
    } catch {
        return $false
    }
}

# Software definitions
$Software = @(
    @{Name = "CapFrameX"; Id = "CXWorld.CapFrameX"; Description = "Performance benchmarking and analysis tool"}
    @{Name = "AutoHotkey v2"; Id = "AutoHotkey.AutoHotkey"; Description = "Automation scripting for benchmark workflows"}
    @{Name = "Notepad++"; Id = "Notepad++.Notepad++"; Description = "Log viewer and configuration editor"}
)

# Common flags to prevent hangs and prompts
$wingetFlags = "--exact --scope=user --accept-package-agreements --accept-source-agreements --silent"

# Check installation status
Write-Host "📦 Required Software Status:" -ForegroundColor Cyan
Write-Host "─────────────────────────────" -ForegroundColor Cyan

$toInstall = @()
$alreadyInstalled = @()

foreach ($app in $Software) {
    Write-Host -NoNewline "   $($app.Name)... "
    
    if (Test-SoftwareInstalled -PackageId $app.Id) {
        Write-Host "[Installed ✓]" -ForegroundColor Green
        $alreadyInstalled += $app
    } else {
        Write-Host "[Missing]" -ForegroundColor Yellow
        $toInstall += $app
    }
}

Write-Host ""

# Summary and installation
if ($toInstall.Count -eq 0) {
    Write-Host "🎉 All required software is already installed!" -ForegroundColor Green
    Write-Host "   $($alreadyInstalled.Count) of $($Software.Count) applications ready" -ForegroundColor Green
} else {
    Write-Host "🚀 Installing missing software ($($toInstall.Count) of $($Software.Count))..." -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = 0
    foreach ($app in $toInstall) {
        Write-Host "Installing $($app.Name)..." -ForegroundColor Yellow
        Write-Host "   → $($app.Description)" -ForegroundColor Gray
        
        try {
            $result = Invoke-Expression "winget install --id=$($app.Id) $wingetFlags" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ $($app.Name) installed successfully" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "   ⚠️  $($app.Name) installation may have issues" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "   ❌ Failed to install $($app.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Final status
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    if ($successCount -eq $toInstall.Count) {
        Write-Host "🎉 Installation Complete!" -ForegroundColor Green
        Write-Host "   All $($Software.Count) applications are now ready for DCS-Max" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Installation Completed with Issues" -ForegroundColor Yellow
        Write-Host "   $successCount of $($toInstall.Count) new installations succeeded" -ForegroundColor Yellow
        Write-Host "   $($alreadyInstalled.Count) were already installed" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Cyan
Write-Host "   • Launch each application to complete initial setup" -ForegroundColor Gray
Write-Host "   • Return to DCS-Max UI to configure paths and settings" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")