# Add-DefenderExclusions.ps1
# Adiciona pastas específicas nas exclusões do Microsoft Defender

# Lista de pastas a serem adicionadas
$paths = @(
    "C:\Program Files (x86)\CapFrameX",
    "C:\Program Files (x86)\NVIDIA Corporation",
    "C:\Program Files (x86)\RivaTuner Statistics Server",
    "C:\Program Files (x86)\Tacview",
    "C:\Program Files\AutoHotkey",
    "C:\Program Files\Eagle Dynamics",
    "C:\Program Files\Notepad++",
    "C:\Program Files\NVIDIA Corporation",
    "C:\Program Files\nvidiaProfileInspector",
    "C:\Program Files\obs-studio",
    "C:\Program Files\OpenXR-Quad-Views-Foveated",
    "C:\Program Files\OpenXR-Toolkit",
    "C:\Program Files\Pimax",
    "C:\Program Files\PimaxXR",
    "C:\Program Files\Process Lasso",
    "C:\Program Files\XRFrameTools",
    "C:\Users\Thomas\Documents\CapFrameX",
    "C:\Users\Thomas\Documents\Tacview",
    "D:\Program Files\Eagle Dynamics\DCS World",
    "D:\Users\Thomas\Saved Games\DCS",
    "C:\ProgramData\DCS-SimpleRadio-Standalone"
)

$existing = @()
$missing  = @()

Write-Host "Verificando pastas..."`n

foreach ($p in $paths) {
    if (Test-Path $p) {
        $existing += $p
    } else {
        $missing += $p
    }
}

if ($existing.Count -gt 0) {
    Write-Host "Adicionando às exclusões do Microsoft Defender:" -ForegroundColor Green
    $existing | ForEach-Object { Write-Host "  - $_" }

    try {
        Add-MpPreference -ExclusionPath $existing
        Write-Host "`nConcluído. Pastas adicionadas às exclusões." -ForegroundColor Green
    }
    catch {
        Write-Host "`nERRO ao adicionar exclusões:" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
else {
    Write-Host "Nenhuma pasta existente encontrada para adicionar." -ForegroundColor Yellow
}

if ($missing.Count -gt 0) {
    Write-Host "`nAs seguintes pastas NÃO foram encontradas (verifique se os caminhos estão corretos):" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" }
}

Write-Host "`nExclusões atuais do Defender (trecho):"
(Get-MpPreference).ExclusionPath
