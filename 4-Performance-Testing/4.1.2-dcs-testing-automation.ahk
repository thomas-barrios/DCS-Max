#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================
; CONFIGURATION
; ==============================

; Wait time configuration (in milliseconds)
; Adjust these values based on your system performance and requirements:
; - Faster systems may need shorter waits
; - Slower systems or loaded scenarios may need longer waits
; - VR setups typically need longer initialization times

DryRun              := true    ; set to true to skip actual benchmark runs for testing

; VR Configuration
EnableVR            := false    ; set to true to enable VR functionality, false to skip VR code
VRhardware          := "Pimax"  ; VR hardware type options:
                                ; "Pimax" - Pimax family (Crystal, Crystal Light, 8KX/5K) - High-FOV for dogfights, needs powerful PC
                                ; FUTURE NOT AVAILABLE YET: 
                                ; "MetaQuest" - Meta/Oculus Quest family (Quest 3, Quest 2/Pro) - Wireless via VD/Air Link, balanced res/FOV
                                ; "HPReverbG2" - HP Reverb G2 - High-res workhorse, excellent text clarity, narrow FOV
                                ; "ValveIndex" - Valve Index - Solid audio/tracking, reliable
                                ; "Other" - Other VR headsets (Rift S, Vive Pro/2, Pico 4, Varjo Aero/XR)

; WAITING TIMES (in milliseconds) MESURE YOUR TIMES AS THEY MAY VARY FROM PC TO PC
WaitVR 		        := 15000    ; 15s wait for VR client to open
WaitMissionReady 	:= 55000    ; 55s wait for DCS to open and mission to load
WaitBeforeRecord    := 1000     ; 1s wait after mission start before recording
WaitRecordLength    := 120000   ; 120s recording duration for benchmark
WaitCapFrameXWrite  := 5000     ; 5s wait for CapFrameX to write JSON file after recording
WaitMissionRestart  := 12000    ; 12s wait after record completion before next test
WaitDCSRestart      := 30000    ; 30s wait for DCS to fully restart

; Test configuration
NumberOfRuns        := 1        ; Number of benchmark runs per test setting (adjust as needed). Will test X times each setting/value combination
MaxRetries          := 1        ; Maximum retries for failed operations

; Time tracking variables
TotalTestCount := 0         ; Total number of tests to run
CompletedTestCount := 0     ; Tests completed so far
StartTime := ""             ; Benchmark start timestamp
BaseTimePerTest := 0        ; Average time per test in seconds

; File paths
capframexFolder     := A_MyDocuments "\CapFrameX\Captures"
optionsLua          := EnvGet("USERPROFILE") "\Saved Games\DCS\Config\options.lua"
iniFile             := A_ScriptDir "\4.1.1-dcs-testing-configuration.ini"   ; Defines witch settings/values to test
logFile             := A_ScriptDir "\4.1.2-dcs-testing-automation.log"
checkpointFile      := A_ScriptDir "\4.1.4-checkpoint.txt"

; Application paths
dcsExe              := "C:\Program Files\Eagle Dynamics\DCS World\bin\DCS.exe"  ; Update path as needed
capframex           := "C:\Program Files (x86)\CapFrameX\CapFrameX.exe"
pimax               := "C:\Program Files\Pimax\PimaxClient\pimaxui\PimaxClient.exe"
notepadpp           := "C:\Program Files\Notepad++\notepad++.exe"  ; Update path if different
mission             := A_ScriptDir "\benchmark-missions\multiplayer-JustDogfights-2min-v1.miz"

; ==============================
; INITIAL SETUP
; ==============================

; Validate critical files exist
; if (!FileExist(optionsLua)) {
;     MsgBox("ERROR: DCS options.lua not found at:`n" optionsLua "`n`nCheck the DCS location specified in the scritpR.", "DCS Benchmark Error", "0x10")
;     ExitApp(1)
; }

; if (!FileExist(mission)) {
;     MsgBox("ERROR: Benchmark mission not found at:`n" mission, "DCS Benchmark Error", "0x10")
;     ExitApp(1)
; }

originalLua := FileRead(optionsLua)

SplitPath logFile, , &logDir
DirCreate logDir

FileAppend "`n", logFile  ; Add blank line before start
LogWithTimestamp("=== DCS BATCH BENCHMARK START ===")

; Check for existing checkpoint and resume if needed
resumePoint := LoadCheckpoint()
if (resumePoint.testIndex > 0) {
    LogWithTimestamp("=== RESUMING FROM CHECKPOINT ===")
    LogWithTimestamp("Resuming from test index: " resumePoint.testIndex " | Setting: " resumePoint.setting " | Value: " resumePoint.value)
}

; ==============================
; PARSE INI FILE WITH RESTART METADATA
; ==============================

configMap := Map()
restartMap := Map()

try {
    sectionContent := IniRead(iniFile, "DCSOptionsTests")
} catch as e {
    LogWithTimestamp("ERROR: Failed to read INI file: " e.Message)
    MsgBox "Failed to read INI file: " e.Message "`n`nExpected:`n" iniFile, "INI Error", 16
    ExitApp
}

LogWithTimestamp("Parsing INI File with Restart Metadata")

for line in StrSplit(sectionContent, "`n", "`r") {
    line := Trim(line)
    if (line = "" || SubStr(line, 1, 1) = "#" || !InStr(line, "="))
        continue
    
    ; Parse inline metadata format: Setting = value1,value2 | RestartRequired=DCS
    restartRequired := "None"  ; Default value
    
    if (InStr(line, "|")) {
        parts := StrSplit(line, "|")
        line := Trim(parts[1])  ; Setting and values part
        metadataPart := Trim(parts[2])
        
        ; Extract restart requirement
        if (RegExMatch(metadataPart, "RestartRequired\s*=\s*(\w+)", &restartMatch)) {
            restartRequired := restartMatch[1]
        }
    }
    
    ; Parse setting and values
    parts := StrSplit(line, "=",, 2)
    key := Trim(parts[1])
    valuesStr := Trim(parts[2])
    values := []
    
    for val in StrSplit(valuesStr, ",") {
        val := Trim(val)
        if (val != "")
            values.Push(val)
    }
    
    if (values.Length > 0) {
        configMap[key] := values
        restartMap[key] := restartRequired
        LogWithTimestamp("Parsed setting: " key " | Values: " valuesStr " | RestartRequired: " restartRequired)
    }
}

if (configMap.Count = 0) {
    LogWithTimestamp("ERROR: No test configurations found in INI!")
    MsgBox "No test configurations found in INI!", "Error", 16
    ExitApp
}

; Calculate total tests and time estimates
TotalTestCount := 0
DcsRestartTests := 0
GraphicsRefreshTests := 0

for setting, values in configMap {
    TotalTestCount += values.Length
    restartType := restartMap[setting]
    if (restartType = "DCS") {
        DcsRestartTests += values.Length
    } else if (restartType = "None") {
        GraphicsRefreshTests += values.Length
    }
}

; Calculate estimated time per test (in seconds)
; DCS restart tests take much longer than graphics refresh tests
BaseTimePerTest := (WaitMissionReady + WaitBeforeRecord + WaitRecordLength + 
                   WaitCapFrameXWrite + WaitMissionRestart) / 1000
GraphicsRefreshTimePerTest := (WaitBeforeRecord + WaitRecordLength + 
                              WaitCapFrameXWrite + 5) / 1000  ; 5s for graphics refresh

TotalEstimatedTime := (DcsRestartTests * BaseTimePerTest) + (GraphicsRefreshTests * GraphicsRefreshTimePerTest)

; Log the benchmark plan
LogWithTimestamp("=== BENCHMARK PLAN ===")
LogWithTimestamp("Total tests to run: " TotalTestCount)
LogWithTimestamp("DCS restart tests: " DcsRestartTests " (avg " BaseTimePerTest "s each)")
LogWithTimestamp("Graphics refresh tests: " GraphicsRefreshTests " (avg " GraphicsRefreshTimePerTest "s each)")
LogWithTimestamp("Total estimated time: " FormatDuration(TotalEstimatedTime))

StartTime := A_Now

; ==============================
; MAIN TEST LOOP WITH RESTART SUPPORT
; ==============================

MainTestLoop() {
    global DryRun, resumePoint, configMap, restartMap, TotalTestCount, NumberOfRuns


    if (DryRun) {
        LogWithTimestamp("DRY RUN: Skipping application startups")
    } else {
        StartApplications()     
        ; Only start DCS initially if resuming or if first test doesn't require DCS restart
        if (resumePoint.testIndex > 0) {
            StartDCS()
        } else {
            ; Check if first test requires DCS restart
            firstTestRequiresDCSRestart := false
            for setting, values in configMap {
                restartType := restartMap[setting]
                if (restartType = "DCS") {
                    firstTestRequiresDCSRestart := true
                    break
                }
                break  ; Only check first setting
            }
            
            if (!firstTestRequiresDCSRestart) {
                StartDCS()
            } else {
                LogWithTimestamp("First test requires DCS restart - DCS will start when needed")
            }
        }
    }

    testIndex := 0

        for setting, values in configMap {
            restartType := restartMap[setting]
            
            for value in values {
                testIndex++

                LogWithTimestamp("=== CONFIGURING TEST " testIndex "/" TotalTestCount " ===")
                LogWithTimestamp("Setting: " setting " = " value " | RestartType: " restartType)

                ; Calculate progress and remaining time
                remainingTests := TotalTestCount - testIndex + 1
                estimatedRemainingTime := CalculateRemainingTime(testIndex - 1)
                                
                ; Skip to resume point if resuming
                if (resumePoint.testIndex > 0 && testIndex < resumePoint.testIndex) {
                    LogWithTimestamp("Skipping test " testIndex " (already completed)")
                    continue
                }
                
                ; Save checkpoint before each test
                SaveCheckpoint(testIndex, setting, value, restartType)
                
                ; Handle restart requirement with verification and fallback
                refreshSuccess := false
                if (restartType = "DCS") {
                    LogWithTimestamp("Restart required: DCS. Closing DCS for setting modification")
                    ; Close DCS first to prevent file caching issues
                    CloseDCS()
                    ; Reset to original values while DCS is closed
                    ResetToOriginalValues()
                    ; Apply the setting while DCS is closed
                    SetConfigValue(setting, value)
                    ; Start DCS with new settings already in place
                    StartDCS()
                    refreshSuccess := VerifySettingChanged(setting, value)
                } else {
                    ; For non-restart settings, use existing flow
                    ; Reset to original values before each test
                    ResetToOriginalValues()
                    ; Apply the setting
                    SetConfigValue(setting, value)
                    ; Ensure DCS is running for non-restart tests
                    if (!WinExist("ahk_exe DCS.exe")) {
                        LogWithTimestamp("DCS not running for non-restart test, starting DCS...")
                        StartDCS()
                    }
                }
                               
                ; Run benchmark tests for this setting/value combination
                Loop NumberOfRuns {
                    runNum := A_Index
                    LogWithTimestamp("--- RUNNING TEST " testIndex "/" TotalTestCount " Run " runNum "/" NumberOfRuns " ---")
                    ;LogWithTimestamp("Setting: " setting " | Value: " value " | RestartType: " restartType)

                    if (!RunBenchmark(setting, value, restartType)) {
                        LogWithTimestamp("ERROR: Benchmark failed, skipping to next test")
                        break
                    }
                }
                
                LogWithTimestamp("COMPLETED test " testIndex "/" TotalTestCount " for " setting " = " value)
                finalRemainingTests := TotalTestCount - testIndex
                finalEstimatedTime := CalculateRemainingTime(testIndex)
                LogWithTimestamp("Remaining time estimated: " FormatDuration(finalEstimatedTime))
            }

            ;LogWithTimestamp("--- COMPLETED TESTS FOR: " setting " ---")
        }

        ; ==============================
        ; FINAL CLEANUP
        ; ==============================

        LogWithTimestamp("=== PERFORMING FINAL CLEANUP ===")

        ; Reopen CapFrameX
        try {
            if (!DryRun) { 
                Run capframex 
                LogWithTimestamp("DRY RUN: CapFrameX would restart successfully")
            } 
            LogWithTimestamp("CapFrameX restarted successfully")
        } catch as e {
            LogWithTimestamp("ERROR: Failed to restart CapFrameX: " e.Message)
        }

        ; Restore original settings
        ResetToOriginalValues()

        ; Close applications gracefully
        CloseApplications()

        ; Clean up checkpoint file
        try {
           FileDelete checkpointFile
            LogWithTimestamp("Checkpoint file cleaned up")
        } catch {
            LogWithTimestamp("WARNING: Could not delete checkpoint file")
        }
    
    LogWithTimestamp("=== ALL TESTS COMPLETED ===")
}
MainTestLoop()




;ExitApp

; ==============================
; FUNCTIONS
; ==============================

FormatDuration(seconds) {
    totalMinutes := Round(seconds / 60)
    hours := totalMinutes // 60
    minutes := totalMinutes - (hours * 60)
    
    if (hours > 0) {
        return hours "h " minutes "min"
    } else {
        return minutes "min"
    }
}

GetCompletedTestCount() {
    global logFile
    try {
        if (FileExist(logFile)) {
            content := FileRead(logFile)
            count := 0
            Loop Parse, content, "`n" {
                if (InStr(A_LoopField, "Running test ")) {
                    count++
                }
            }
            return count
        }
    } catch {
        return 0
    }
    return 0
}

LogWithTimestamp(message) {
    global logFile
    timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    
    ; Improved retry mechanism for file access conflicts
    maxRetries := 10  ; Increased from 3 to 10
    baseRetryDelay := 50  ; Base delay in milliseconds
    
    Loop maxRetries {
        try {
            ; Use exponential backoff for better conflict resolution
            retryDelay := baseRetryDelay * (A_Index - 1)  ; 0, 50, 100, 150, 200, etc.
            if (A_Index > 1) {
                Sleep retryDelay
            }
            
            ; Try to write to the file
            FileAppend timestamp " " message "`n", logFile
            return  ; Success, exit function
        } catch as e {
            if (A_Index < maxRetries) {
                continue  ; Try again with longer delay
            } else {
                ; Last attempt failed - write to backup file instead of showing popup
                try {
                    backupLogFile := StrReplace(logFile, ".log", "_backup.log")
                    FileAppend timestamp " [BACKUP_LOG] " message "`n", backupLogFile
                } catch {
                    ; Even backup failed - silently continue to avoid interrupting the test
                }
                return
            }
        }
    }
}

SaveCheckpoint(testIndex, setting, value, restartType) {
    global checkpointFile
    
    checkpointData := testIndex "|" setting "|" value "|" restartType
    
    try {
        FileDelete checkpointFile
        FileAppend checkpointData, checkpointFile
        LogWithTimestamp("Checkpoint saved: Test " testIndex " | " setting " = " value)
    } catch as e {
        LogWithTimestamp("WARNING: Failed to save checkpoint: " e.Message)
    }
}

LoadCheckpoint() {
    global checkpointFile
    
    resumePoint := {testIndex: 0, setting: "", value: "", restartType: ""}
    
    try {
        if (FileExist(checkpointFile)) {
            checkpointData := FileRead(checkpointFile)
            parts := StrSplit(checkpointData, "|")
            if (parts.Length >= 4) {
                resumePoint.testIndex := Integer(parts[1])
                resumePoint.setting := parts[2]
                resumePoint.value := parts[3]
                resumePoint.restartType := parts[4]
                LogWithTimestamp("Checkpoint loaded: Test " resumePoint.testIndex " | " resumePoint.setting " = " resumePoint.value)
            }
        }
    } catch as e {
        LogWithTimestamp("WARNING: Failed to load checkpoint: " e.Message)
        ; Continue with fresh start
    }
    
    return resumePoint
}

; ==============================
; TIME CALCULATION FUNCTIONS
; ==============================

CalculateRemainingTime(currentTestIndex) {
    global configMap, restartMap, TotalTestCount, BaseTimePerTest, GraphicsRefreshTimePerTest
    
    remainingDcsTests := 0
    remainingGraphicsTests := 0
    testIndex := 0
    
    for setting, values in configMap {
        restartType := restartMap[setting]
        for value in values {
            testIndex++
            if (testIndex > currentTestIndex) {
                if (restartType = "DCS") {
                    remainingDcsTests++
                } else if (restartType = "None") {
                    remainingGraphicsTests++
                }
            }
        }
    }
    
    return (remainingDcsTests * BaseTimePerTest) + (remainingGraphicsTests * GraphicsRefreshTimePerTest)
}

; ==============================
; GRAPHICS SETTINGS REFRESH FUNCTIONS
; ==============================
SendKeyWithDelay(key) {
    Send key
    Sleep 10
}

OpenCloseGraphicsSettings() {
    global MaxRetries
    
    if DryRun {
        LogWithTimestamp("DRY RUN: Simulating graphics settings refresh...")
        return true
    }
    ; Only activate DCS if it's running
    if (WinExist("ahk_exe DCS.exe")) {
        WinActivate "ahk_exe DCS.exe"
        try {
            LogWithTimestamp("Refreshing graphics settings")
            SendKeyWithDelay("{Esc}")
            Loop 10 {
                SendKeyWithDelay("{Down}")
            }
            Loop 3 {
                SendKeyWithDelay("{Up}")
            }
            SendKeyWithDelay("{Space}")
            Sleep 10  ; Wait for settings to apply
            SendKeyWithDelay("{Esc}")
            LogWithTimestamp("Graphics settings refreshed successfully")
            return true 
            

        } catch as e {
            LogWithTimestamp("ERROR: Failed to refresh graphics settings: " e.Message)
            return false
        }
    } else {
        LogWithTimestamp("WARNING: DCS is not running, skipping graphics settings refresh")
        return false
    }
}

VerifySettingChanged(settingName, expectedValue) {
    global optionsLua
    
    LogWithTimestamp("DEBUG: Starting verification for " settingName " (expected: " expectedValue ")")
    
    try {
        ; Read the current options.lua file
        currentContent := FileRead(optionsLua)
        LogWithTimestamp("DEBUG: Verification - File read successfully, length: " StrLen(currentContent))
        
        actualValue := ExtractSettingValue(currentContent, settingName)
        LogWithTimestamp("DEBUG: Extracted value: '" actualValue "' (type: " Type(actualValue) ")")
        LogWithTimestamp("DEBUG: Expected value: '" expectedValue "' (type: " Type(expectedValue) ")")
        
        ; Show the context around the setting for debugging
        searchPattern := '["' . settingName . '"] = '
        settingPos := InStr(currentContent, searchPattern)
        if (settingPos > 0) {
            contextStart := Max(1, settingPos - 50)
            contextEnd := Min(StrLen(currentContent), settingPos + 100)
            contextContent := SubStr(currentContent, contextStart, contextEnd - contextStart + 1)
            ;LogWithTimestamp("DEBUG: Setting context in file: " contextContent)
        } else {
            LogWithTimestamp("DEBUG: WARNING - Setting pattern not found during verification!")
        }
        
        ; Compare expected vs actual (handle string vs numeric comparison)
        if (actualValue == expectedValue || String(actualValue) == String(expectedValue)) {
            LogWithTimestamp("VERIFIED: " settingName " successfully changed to " actualValue)
            return true
        } else {
            LogWithTimestamp("VERIFICATION FAILED: " settingName " expected '" expectedValue "' but found '" actualValue "'")
            return false
        }
    } catch as e {
        LogWithTimestamp("ERROR: Failed to verify setting change: " e.Message)
        return false
    }
}

StartApplications() {
    global capframex, pimax, WaitVR, logFile, notepadpp, EnableVR, VRhardware
    
    LogWithTimestamp("=== STARTING APPLICATIONS ===")
    
    ; Start CapFrameX
    if !FileExist(capframex) {
        LogWithTimestamp("ERROR: CapFrameX not found: " capframex)
        MsgBox "CapFrameX not found: " capframex, "Error", 16
        ExitApp
    }
    
    LogWithTimestamp("Starting CapFrameX...")
    Run capframex
    Sleep 1000
    LogWithTimestamp("CapFrameX started successfully")
    
    ; VR Hardware Setup (only if VR is enabled)
    if (EnableVR) {
        LogWithTimestamp("VR enabled - setting up " VRhardware " hardware...")
        
        ; Start Pimax Client (for Pimax VR)
        if (VRhardware = "Pimax") {
            if !FileExist(pimax) {
                LogWithTimestamp("ERROR: Pimax Client not found: " pimax)
                MsgBox "Pimax Client not found: " pimax, "Error", 16
                ExitApp
            }
            
            ; Check if Pimax is already running
            pimaxAlreadyRunning := WinExist("ahk_exe PimaxClient.exe")
            if (pimaxAlreadyRunning) {
                LogWithTimestamp("Pimax Client is already running, skipping launch, reduced wait time (2s)...")
                Sleep 2000
                LogWithTimestamp("Pimax Client startup wait completed")
            } else {
                LogWithTimestamp("Starting Pimax Client...")
                Run pimax
                Sleep WaitVR
                LogWithTimestamp("Pimax Client started successfully")
            }
        } else {
            LogWithTimestamp("VR hardware " VRhardware " selected - no additional client needed")
        }
    } else {
        LogWithTimestamp("VR disabled - skipping VR hardware setup")
    }
    
    ; Start Notepad++
    if !FileExist(notepadpp) {
        LogWithTimestamp("ERROR: Notepad++ not found: " notepadpp)
        MsgBox "Notepad++ not found: " notepadpp, "Error", 16
        ExitApp
    }
    
    LogWithTimestamp("Starting Notepad++ in monitor mode for log...")
    Run notepadpp ' -monitor "' logFile '"'
    Sleep 1000
    LogWithTimestamp("Notepad++ started successfully")
}

StartDCS() {
    global dcsExe, mission, WaitMissionReady, DryRun
    
    LogWithTimestamp("=== STARTING DCS ===")
    
    ; Check if DCS is already running
    dcsAlreadyRunning := WinExist("ahk_exe DCS.exe")
    if (dcsAlreadyRunning) {
        LogWithTimestamp("DCS is already running, skipping launch, , reduced wait time (2s)...")
        WinActivate "ahk_exe DCS.exe"
        WinWaitActive "ahk_exe DCS.exe"
        Sleep 2000
        return
    }
    
    command := Format('"{}" --mission "{}"', dcsExe, mission)
    LogWithTimestamp("Launching DCS with command: " command)
    
    try {
        if (!DryRun) {
            Run command
        } else {
            LogWithTimestamp("DRY RUN: Skipping DCS launch")
            return  ; Exit early in dry run mode
        }
    } catch as e {
        LogWithTimestamp("ERROR: Failed to launch DCS: " e.Message)
        MsgBox "Failed to launch DCS: " e.Message, "Error", 16
        ExitApp
    }
    
    LogWithTimestamp("Waiting for DCS to start...")
    if !WinWait("ahk_exe DCS.exe",, 90) {
        LogWithTimestamp("ERROR: DCS failed to start within 90 seconds")
        MsgBox "DCS failed to start!", "Error", 16
        ExitApp
    }
    
    LogWithTimestamp("DCS started, activating window...")
    WinActivate "ahk_exe DCS.exe"
    WinWaitActive "ahk_exe DCS.exe"
    
    LogWithTimestamp("Waiting for mission to load...")
    Sleep WaitMissionReady
    LogWithTimestamp("Mission loaded successfully")
}

CloseDCS() {
    global MaxRetries
    
    LogWithTimestamp("Closing DCS for setting modification...")
    
    ; Close DCS
    Loop MaxRetries {
        try {
            if (WinExist("ahk_exe DCS.exe")) {
                LogWithTimestamp("Closing DCS (attempt " A_Index "/" MaxRetries ")...")
                WinClose "ahk_exe DCS.exe"
                
                ; Wait for DCS to close
                if (WinWaitClose("ahk_exe DCS.exe",, 30)) {
                    LogWithTimestamp("DCS closed successfully")
                    break
                } else {
                    LogWithTimestamp("DCS did not close within 30 seconds, trying to force close...")
                    try {
                        ProcessClose "DCS.exe"
                        LogWithTimestamp("DCS process terminated forcefully")
                        break
                    } catch {
                        LogWithTimestamp("Failed to force close DCS process")
                    }
                }
            } else {
                LogWithTimestamp("DCS was not running")
                break
            }
        } catch as e {
            LogWithTimestamp("ERROR closing DCS (attempt " A_Index "): " e.Message)
            if (A_Index = MaxRetries) {
                LogWithTimestamp("ERROR: Failed to close DCS after " MaxRetries " attempts")
                return false
            }
            Sleep 2000
        }
    }
    
    ; Wait a moment for complete cleanup and file system synchronization
    LogWithTimestamp("Waiting for DCS cleanup and file system sync...")
    Sleep 5000
    
    return true
}

RestartDCS() {
    global WaitDCSRestart, MaxRetries, DryRun
    
    LogWithTimestamp("Restarting DCS...")
    
    ; Close DCS
    Loop MaxRetries {
        try {
            if (WinExist("ahk_exe DCS.exe")) {
                LogWithTimestamp("Closing DCS (attempt " A_Index "/" MaxRetries ")...")
                WinClose "ahk_exe DCS.exe"
                
                ; Wait for DCS to close
                if (WinWaitClose("ahk_exe DCS.exe",, 30)) {
                    LogWithTimestamp("DCS closed successfully")
                    break
                } else {
                    LogWithTimestamp("DCS did not close within 30 seconds, trying to force close...")
                    try {
                        ProcessClose "DCS.exe"
                        LogWithTimestamp("DCS process terminated forcefully")
                        break
                    } catch {
                        LogWithTimestamp("Failed to force close DCS process")
                    }
                }
            } else {
                LogWithTimestamp("DCS was not running")
                break
            }
        } catch as e {
            LogWithTimestamp("ERROR closing DCS (attempt " A_Index "): " e.Message)
            if (A_Index = MaxRetries) {
                LogWithTimestamp("ERROR: Failed to close DCS after " MaxRetries " attempts")
                return false
            }
            Sleep 2000
        }
    }
    
    ; Wait a moment for cleanup
    Sleep 3000
    
    ; Restart DCS
    if (!DryRun) StartDCS()
    
    return true
}

CloseApplications() {
    global capframex
    
    LogWithTimestamp("=== CLOSING APPLICATIONS ===")
    
    ; Close DCS
    try {
        if (WinExist("ahk_exe DCS.exe")) {
            WinClose "ahk_exe DCS.exe"
            LogWithTimestamp("DCS closed successfully")
        }
    } catch {
        LogWithTimestamp("DCS was not running or already closed")
    }
    
    ; Close CapFrameX
    try {
        if (WinExist("ahk_exe CapFrameX.exe")) {
            WinClose "ahk_exe CapFrameX.exe"
            LogWithTimestamp("CapFrameX closed successfully")
        }
    } catch {
        LogWithTimestamp("CapFrameX was not running or already closed")
    }
    
    ; Close Pimax Client
    try {
        if (WinExist("ahk_exe PimaxClient.exe")) {
            WinClose "ahk_exe PimaxClient.exe"
            LogWithTimestamp("Pimax Client closed successfully")
        } else {
            ; Try to terminate the process if window close fails
            try {
                ProcessClose "PimaxClient.exe"
                LogWithTimestamp("Pimax Client process terminated")
            } catch {
                LogWithTimestamp("Could not terminate Pimax Client process")
            }
        }
    } catch {
        LogWithTimestamp("Error closing Pimax Client")
    }

}

; Extract setting value from lua content using string operations
ExtractSettingValue(content, settingName) {
    ; Search for: ["settingName"] = 
    searchPattern := '["' . settingName . '"] = '
    settingPos := InStr(content, searchPattern)
    
    if (!settingPos) {
        return ""  ; Setting not found
    }
    
    ; Find value start (after the equals sign and any whitespace)
    valueStart := settingPos + StrLen(searchPattern)
    
    ; Skip any whitespace or tabs
    while (valueStart <= StrLen(content)) {
        char := SubStr(content, valueStart, 1)
        if (char != " " && char != "`t")
            break
        valueStart++
    }
    
    ; Find value end (comma, newline, or closing brace)
    valueEnd := valueStart
    while (valueEnd <= StrLen(content)) {
        char := SubStr(content, valueEnd, 1)
        if (char == "," || char == "`n" || char == "`r" || char == "}")
            break
        valueEnd++
    }
    
    ; Extract and clean the value
    if (valueEnd > valueStart) {
        value := SubStr(content, valueStart, valueEnd - valueStart)
        value := Trim(value)
        ; Remove quotes if present
        if (SubStr(value, 1, 1) == '"' && SubStr(value, -1) == '"')
            value := SubStr(value, 2, StrLen(value) - 2)
        return value
    }
    
    return ""
}

; Build list of settings to track from configuration file
BuildSettingsToTrack() {
    settingsList := []
    
    try {
        ; Read the test configuration file
        iniContent := FileRead(iniFile)
        
        ; Parse each line for setting definitions
        Loop Parse, iniContent, "`n", "`r" {
            line := Trim(A_LoopField)
            ; Skip empty lines and comments
            if (line == "" || SubStr(line, 1, 1) == "#")
                continue
                
            ; Look for pattern: settingName = values|...
            equalsPos := InStr(line, "=")
            if (equalsPos) {
                settingName := Trim(SubStr(line, 1, equalsPos - 1))
                ; Only add non-empty setting names
                if (settingName != "")
                    settingsList.Push(settingName)
            }
        }
                 
    } catch as e {
        LogWithTimestamp("WARNING: Could not read test config, using default settings list")
    }
    
    return settingsList
}

ResetToOriginalValues() {
    global originalLua, optionsLua, logFile
    
    LogWithTimestamp("DEBUG: Starting reset to original values...")
    LogWithTimestamp("DEBUG: Original content length: " StrLen(originalLua))
    
    ; Get list of settings to track
    settingsToTrack := BuildSettingsToTrack()
    LogWithTimestamp("DEBUG: Found " settingsToTrack.Length " settings to track")
    
    try {
        FileDelete optionsLua
        FileAppend originalLua, optionsLua
        Sleep 500  ; Small delay to ensure file is written
        LogWithTimestamp("DEBUG: Original file restored successfully")
        
        ; Log original values that were restored
        for settingName in settingsToTrack {
            restoredValue := ExtractSettingValue(originalLua, settingName)
            if (restoredValue != "") {
                LogWithTimestamp("Restored --> " . settingName . " to: " . restoredValue)
            } else {
                LogWithTimestamp("WARNING: Could not verify restoration of " . settingName)
            }
        }
        LogWithTimestamp("All settings reseted to original state prior to test")
        
        ; Verify the file was actually written correctly
        verifyContent := FileRead(optionsLua)
        if (StrLen(verifyContent) == StrLen(originalLua)) {
            LogWithTimestamp("DEBUG: File size verification passed")
        } else {
            LogWithTimestamp("DEBUG: WARNING - File size mismatch! Original: " StrLen(originalLua) ", Current: " StrLen(verifyContent))
        }
            
    } catch as e {
        LogWithTimestamp("ERROR: Failed to reset options.lua: " e.Message)
        MsgBox "Failed to reset options.lua: " e.Message, "Reset Error", 16
        ExitApp
    }

}

SetConfigValue(setting, value) {
    global optionsLua, logFile
    
    LogWithTimestamp("Setting for test --> " setting " = " value)
    LogWithTimestamp("DEBUG: Reading options.lua file...")
    
    try {
        content := FileRead(optionsLua)
        LogWithTimestamp("DEBUG: File read successfully, content length: " StrLen(content))
    } catch as e {
        LogWithTimestamp("ERROR: Failed to read options.lua: " e.Message)
        ExitApp
    }

    ; Use simple string replacement for DCS settings - more reliable than regex
    ; Find the line with the setting
    searchString := '["' . setting . '"] = '
    LogWithTimestamp("DEBUG: Searching for pattern: " searchString)
    
    ; Find position
    pos := InStr(content, searchString)
    LogWithTimestamp("DEBUG: Pattern found at position: " pos)
    
    if (pos = 0) {
        LogWithTimestamp("ERROR: Failed to find setting: " setting)
        LogWithTimestamp("Searching for: " searchString)
        LogWithTimestamp("Content preview: " SubStr(content, 1, 500) "...")
        MsgBox "Failed to update setting: " setting "`n`nExpected format:`n[`"" setting "`"] = value,`n", "Config Error", 16
        ExitApp
    }
    
    ; Find the end of the line (look for comma after the position)
    ; Start searching for comma after the "=" part
    startSearch := pos + StrLen(searchString)
    commaPos := InStr(content, ",", false, startSearch)
    LogWithTimestamp("DEBUG: Comma found at position: " commaPos " (searching from: " startSearch ")")
    
    if (commaPos = 0) {
        LogWithTimestamp("ERROR: Failed to find end of setting line")
        ExitApp
    }
    
    ; Extract current value and replace it
    oldLine := SubStr(content, pos, commaPos - pos + 1)
    newLine := searchString . value . ","
    
    LogWithTimestamp("DEBUG: Old line: " oldLine)
    LogWithTimestamp("DEBUG: New line: " newLine)
    
    ; Show context around the setting for debugging
    contextStart := Max(1, pos - 100)
    contextEnd := Min(StrLen(content), commaPos + 100)
    contextContent := SubStr(content, contextStart, contextEnd - contextStart + 1)
    ;LogWithTimestamp("DEBUG: Context around setting: " contextContent)
    
    newContent := StrReplace(content, oldLine, newLine)
    LogWithTimestamp("DEBUG: String replacement completed")
    
    ; Verify the replacement worked
    newPos := InStr(newContent, newLine)
    if (newPos > 0) {
        LogWithTimestamp("DEBUG: Verification - New line found at position: " newPos)
    } else {
        LogWithTimestamp("DEBUG: WARNING - New line not found after replacement!")
    }

    try {
        FileDelete optionsLua
        FileAppend newContent, optionsLua
        LogWithTimestamp("DEBUG: File written successfully")
        
        ; Save a backup copy for debugging (test-specific version)
        backupFileName := StrReplace(optionsLua, ".lua", "_test_" . setting . "_" . value . ".lua")
        try {
            FileAppend newContent, backupFileName
            LogWithTimestamp("DEBUG: Test backup saved to: " . backupFileName)
        } catch as e {
            LogWithTimestamp("WARNING: Failed to save test backup: " . e.Message)
        }
        
        ; Read back and verify the written content
        verifyContent := FileRead(optionsLua)
        verifyPos := InStr(verifyContent, newLine)
        if (verifyPos > 0) {
            LogWithTimestamp("DEBUG: File verification - Setting confirmed written at position: " verifyPos)
        } else {
            LogWithTimestamp("DEBUG: ERROR - File verification failed! Setting not found after write")
        }
        
    } catch as e {
        LogWithTimestamp("ERROR: Failed to write options.lua: " e.Message)
        MsgBox "Failed to write options.lua: " e.Message, "Config Error", 16
        ExitApp
    }
}

RunBenchmark(setting, value, restartType) {
    global WaitBeforeRecord, WaitRecordLength, WaitCapFrameXWrite, WaitMissionRestart, MaxRetries, DryRun
       
    ; In DryRun mode, skip DCS interaction
    if (DryRun) {
        LogWithTimestamp("DRY RUN: Simulating benchmark sequence...")
        LogWithTimestamp("DRY RUN: Would " (WaitBeforeRecord/1000) "s wait  before recording")
        LogWithTimestamp("DRY RUN: Would " (WaitRecordLength/1000) "s while recording")
        LogWithTimestamp("DRY RUN: Would " (WaitCapFrameXWrite/1000) "s wait for file write")
        LogWithTimestamp("DRY RUN: Would " (WaitMissionRestart/1000) "s wait for mission restart and reload")
        return true
    }
    
    ; Ensure DCS window is active
    Loop MaxRetries {
        try {
            LogWithTimestamp("Activating DCS window for benchmark (attempt " A_Index "/" MaxRetries ")...")
            if (!WinExist("ahk_exe DCS.exe")) {
                LogWithTimestamp("ERROR: DCS is not running!")
                return false
            }
            
            WinActivate "ahk_exe DCS.exe"
            WinWaitActive "ahk_exe DCS.exe", , 10
            break
        } catch as e {
            LogWithTimestamp("ERROR activating DCS window (attempt " A_Index "): " e.Message)
            if (A_Index = MaxRetries) {
                LogWithTimestamp("ERROR: Failed to activate DCS window after " MaxRetries " attempts")
                return false
            }
            Sleep 2000
        }
    }

    try {
        LogWithTimestamp("Benchmark sequence started...")
        Send "{Esc}"
        ;LogWithTimestamp("restartType..." restartType)
        
        LogWithTimestamp("Mission started...")
        if (restartType = "None") {
            ; Graphics refresh required (RestartRequired=None)
            LogWithTimestamp("Restart Required: None. Refreshing graphic settings")
            
            ; Try graphics refresh first
            refreshSuccess := OpenCloseGraphicsSettings()
            if (refreshSuccess) {
                ; Verify the setting actually changed
                refreshSuccess := VerifySettingChanged(setting, value)
            }
        } else if (restartType = "DCS") {
            ; For DCS restart settings, verify the setting is already applied
            LogWithTimestamp("Restart Required: DCS. Verifying setting applied during startup")
            VerifySettingChanged(setting, value)
        }

        LogWithTimestamp((WaitBeforeRecord/1000) "s waiting before recording...")

        Sleep WaitBeforeRecord
        Send "{ScrollLock}"
        LogWithTimestamp("RECORD KEY pressed record STARTED, waiting " (WaitRecordLength/1000) "s")

        Sleep (DryRun ? 1000 : WaitRecordLength)
        Send "{ScrollLock}"
        LogWithTimestamp("RECORD KEY pressed record STOPPED, waiting " (WaitCapFrameXWrite/1000) "s for file write")    

        Sleep WaitCapFrameXWrite
        UpdateCapFrameXComment(setting, value)
        LogWithTimestamp("CapFrameX comment updated: " setting "=" value)
        
        LogWithTimestamp("Mission restarted")
        Send "{LShift down}"
        Sleep 50
        Send "r"
        Sleep 50
        Send "{LShift up}"
        
        LogWithTimestamp("Waiting " (WaitMissionRestart/1000) "s for DCS to reload mission")
        Sleep WaitMissionRestart
        LogWithTimestamp("Mission reload wait completed")
        
        return true
        
    } catch as e {
        LogWithTimestamp("ERROR during benchmark: " e.Message)
        return false
    }
}

UpdateCapFrameXComment(setting, value) {
    global capframexFolder
    
    commentText := setting "=" value
    LogWithTimestamp("Updating CapFrameX comment to: " commentText)
    
    ; Find the most recent CapFrameX-*.json file
    newestFile := ""
    newestTime := 0
    
    try {
        Loop Files, capframexFolder "\CapFrameX-*.json" {
            fileTime := FileGetTime(A_LoopFileFullPath, "M")
            if (fileTime > newestTime) {
                newestTime := fileTime
                newestFile := A_LoopFileFullPath
            }
        }
    } catch as e {
        LogWithTimestamp("ERROR: Failed to search CapFrameX folder: " e.Message)
        return
    }
    
    if (newestFile = "") {
        LogWithTimestamp("WARNING: No CapFrameX JSON files found in " capframexFolder)
        return
    }
    
    LogWithTimestamp("Found newest CapFrameX file: " newestFile)
    
    ; Read and update the JSON file
    try {
        content := FileRead(newestFile)
        
        ; Replace comment field (handles both null and existing string values)
        ; Pattern matches: "Comment":null or "Comment":"any text"
        pattern := '"Comment":\s*(?:null|"[^"]*")'
        replacement := '"Comment":"' commentText '"'
        
        newContent := RegExReplace(content, pattern, replacement)
        
        if (newContent = content) {
            LogWithTimestamp("WARNING: Comment field not found in JSON file")
            return
        }
        
        ; Write back the updated content
        FileDelete newestFile
        FileAppend newContent, newestFile
        LogWithTimestamp("Updated --> CapFrameX comment")
        
    } catch as e {
        LogWithTimestamp("ERROR: Failed to update CapFrameX comment: " e.Message)
    }
}

PregQuote(str) {
    static metachars := Map(
        "\", "\\",  "^", "\^",  "$", "\$",  "(", "\(",  ")", "\)",
        "[", "\[",  "]", "\]",  "{", "\{",  "}", "\}",  ".", "\.",
        "?", "\?",  "*", "\*",  "+", "\+"
    )
    result := str
    for char, esc in metachars
        result := StrReplace(result, char, esc, true)
    return result
}

; ==============================
; IMPLEMENTATION NOTES
; ==============================
; NEW FEATURES ADDED:
; ✓ append timestamp to the begining of all log lines
; ✓ insert a blank line in log before === DCS BATCH BENCHMARK START === to standardlize
; ✓ put all wait times for setting Wait1, Wait2, Wait3
; ✓ insert a play mission... start redord delay
; ✓ insert a record lenght var
; ✓ display the waiting times in log
; ✓ update comment on Capframex file
; ✓ close and reopen capframex in the end
; ✓ Inline metadata parsing (RestartRequired=DCS/Windows/None)
; ✓ DCS restart capability with error handling
; ✓ Checkpoint system for state persistence 
; ✓ Enhanced error handling and retry logic
; ✓ Improved logging with restart information
; ✓ Per-setting restart isolation
; ✓ Resume capability after interruption
; ✓ add calculations of total expected time based on number of tests and waiting time, logs at start aend of each remaining tests and with estimated time remaining. check current log to estimate completed tests
; ✓ add logging of current vs original values when resetting settings for debugging purposes
; ✓ add logging of all changes made to settings
; ✓ Pre-restart setting modification to prevent DCS file caching issues
; ✓ saves a tested version of options.lua for each test setting/value for debugging purposes
;
; ; TODO MUST HAVE:
; check feasibility of using only PowerShell for everything instead of AHK
;
; TODO FOR WINDOWS RESTART:
; - Implement Windows restart automation
; - Add registry editing capability
; - Windows service management
; - Auto-resume after Windows reboot
;
; NICE TO HAVE (TODO FOR FUTURE IMPROVEMENTS):
; validate link sources x setting relevance
; check apps instalation paths dynamically
; check DCS, mission load, CapFrameX writing, MissionReload time, and other times possible dynamically
; group # width=2560 # height=1440 tests, these settings are related to each other and should be run together
; add a UserPreferedValue option to restore certain settings to user preferred values instead of original
; add a CurrentValue option to inform/restore current value

