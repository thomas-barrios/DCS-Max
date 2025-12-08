; VR Hardware Manager for DCS-Max Benchmarking
; Provides abstraction layer for multi-headset VR startup and control
; Supports: Meta Quest, HTC Vive/SteamVR, Pimax

; ============================================
; HEADSET PATH RESOLUTION
; ============================================

GetMetaQuestPath() {
    ; Check standard installation paths
    paths := [
        "C:\Program Files\Meta\MetaQuestLink\MetaQuestLink.exe",
        A_ProgramFiles . "\Meta\MetaQuestLink\MetaQuestLink.exe"
    ]
    
    for path in paths {
        if (FileExist(path)) {
            return path
        }
    }
    
    return ""
}

GetSteamVRPath() {
    ; Get Steam installation path from registry
    try {
        steamPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath")
        steamVRPath := steamPath . "\steamapps\common\SteamVR\bin\win64\vrserver.exe"
        if (FileExist(steamVRPath)) {
            return steamVRPath
        }
    } catch as e {
        ; Registry key may not exist
    }
    
    ; Try default path
    defaultPath := "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrserver.exe"
    if (FileExist(defaultPath)) {
        return defaultPath
    }
    
    return ""
}

GetPimaxPath() {
    ; Check standard installation paths
    paths := [
        "C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe",
        A_ProgramFiles . "\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
    ]
    
    for path in paths {
        if (FileExist(path)) {
            return path
        }
    }
    
    return ""
}

GetHeadsetPath(hardware) {
    ; Returns the full path to the headset executable based on hardware type
    switch (hardware) {
        case "MetaQuest":
            return GetMetaQuestPath()
        case "HTCVive":
            return GetSteamVRPath()
        case "Pimax":
            return GetPimaxPath()
        default:
            return ""
    }
}

; ============================================
; HEADSET DETECTION
; ============================================

DetectInstalledHeadset() {
    ; Detects which VR headset is installed on the system.
    ; Returns the first found: "MetaQuest", "HTCVive", "Pimax", or ""
    
    ; Check Meta Quest
    if (FileExist(GetMetaQuestPath())) {
        return "MetaQuest"
    }
    
    ; Check HTC Vive / SteamVR
    if (FileExist(GetSteamVRPath())) {
        return "HTCVive"
    }
    
    ; Check Pimax
    if (FileExist(GetPimaxPath())) {
        return "Pimax"
    }
    
    return ""
}

; ============================================
; VR STARTUP FUNCTIONS
; ============================================

StartMetaQuest(exePath) {
    ; Starts Meta Quest Link software
    ; Handles both USB Link and Airlink connections
    if (!exePath || !FileExist(exePath)) {
        return false
    }
    
    try {
        Run(exePath)
        return true
    } catch as e {
        return false
    }
}

StartSteamVR(exePath) {
    ; Starts SteamVR (used by HTC Vive and Valve Index)
    ; exePath should be path to vrserver.exe or Steam installation
    try {
        ; If path is to vrserver.exe directly, use it
        if (FileExist(exePath)) {
            Run(exePath)
        } else {
            ; Try to start SteamVR through Steam
            steamPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath")
            steamExe := steamPath . "\steam.exe"
            if (FileExist(steamExe)) {
                ; Launch SteamVR through Steam
                Run(steamExe . " -applaunch 250820")
            } else {
                return false
            }
        }
        return true
    } catch as e {
        return false
    }
}

StartPimax(exePath) {
    ; Starts Pimax Client
    if (!exePath || !FileExist(exePath)) {
        return false
    }
    
    try {
        Run(exePath)
        return true
    } catch as e {
        return false
    }
}

StartVRHardware(hardware, exePath := "") {
    ; Main VR startup dispatcher
    ; Detects headset type and calls appropriate startup function
    ;
    ; Parameters:
    ; - hardware: "MetaQuest", "HTCVive", "Pimax", or "auto"
    ; - exePath: Optional path to executable, or "auto" for auto-detection
    
    ; Auto-detect if needed
    if (hardware = "auto") {
        hardware := DetectInstalledHeadset()
        if (!hardware) {
            return false
        }
    }
    
    ; Get path if not provided or set to auto
    if (!exePath || exePath = "auto") {
        exePath := GetHeadsetPath(hardware)
        if (!exePath) {
            return false
        }
    }
    
    ; Call appropriate startup function
    switch (hardware) {
        case "MetaQuest":
            return StartMetaQuest(exePath)
        case "HTCVive":
            return StartSteamVR(exePath)
        case "Pimax":
            return StartPimax(exePath)
        default:
            return false
    }
}

; ============================================
; VR STATUS CHECKING
; ============================================

CheckVRRunning(hardware) {
    ; Checks if VR hardware is currently running
    switch (hardware) {
        case "MetaQuest":
            return WinExist("ahk_exe MetaQuestLink.exe") > 0
        case "HTCVive":
            return WinExist("ahk_exe vrserver.exe") > 0 || WinExist("ahk_exe SteamVR.exe") > 0
        case "Pimax":
            return WinExist("ahk_exe PimaxClient.exe") > 0
        default:
            return false
    }
}

CheckMetaQuestConnection() {
    ; Checks if Meta Quest is connected via USB Link
    ; Returns true if MetaQuest process can be found or if headset is present
    ; This is a basic check - actual USB connection validation would require more advanced methods
    
    ; Check if Meta Quest Link app can be found
    exePath := GetMetaQuestPath()
    if (!exePath) {
        return false
    }
    
    ; Check if already running
    if (WinExist("ahk_exe MetaQuestLink.exe")) {
        return true
    }
    
    ; Try to detect via registry or hardware - simplified check
    ; A full implementation would use Windows USB device enumeration
    return true  ; Assume connection if app is available
}

; ============================================
; VR SHUTDOWN FUNCTIONS
; ============================================

StopMetaQuest() {
    ; Cleanly stops Meta Quest Link
    try {
        if (WinExist("ahk_exe MetaQuestLink.exe")) {
            WinClose("ahk_exe MetaQuestLink.exe")
            Sleep(1000)
        }
        ProcessClose("MetaQuestLink.exe")
    } catch as e {
        ; Process may not exist
    }
}

StopSteamVR() {
    ; Cleanly stops SteamVR
    try {
        ; Stop tracking processes
        ProcessClose("vrserver.exe")
        ProcessClose("vrcompositor.exe")
        ProcessClose("SteamVR.exe")
    } catch as e {
        ; Processes may not exist
    }
}

StopPimax() {
    ; Cleanly stops Pimax Client
    try {
        if (WinExist("ahk_exe PimaxClient.exe")) {
            WinClose("ahk_exe PimaxClient.exe")
            Sleep(1000)
        }
        ProcessClose("PimaxClient.exe")
    } catch as e {
        ; Process may not exist
    }
}

StopVRHardware(hardware) {
    ; Main VR shutdown dispatcher
    switch (hardware) {
        case "MetaQuest":
            StopMetaQuest()
        case "HTCVive":
            StopSteamVR()
        case "Pimax":
            StopPimax()
    }
}

; ============================================
; TIMING UTILITIES
; ============================================

GetDefaultVRStartupTime(hardware) {
    ; Returns default recommended startup time for each headset
    ; These are baseline values - users can calibrate for their specific system
    switch (hardware) {
        case "MetaQuest":
            return 18000  ; 18 seconds - includes USB handshake + Link init
        case "HTCVive":
            return 15000  ; 15 seconds - SteamVR startup
        case "Pimax":
            return 15000  ; 15 seconds - Pimax client startup
        default:
            return 20000  ; 20 second fallback
    }
}
