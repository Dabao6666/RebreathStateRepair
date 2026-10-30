Scriptname RebreathAutoRepairAlias extends ReferenceAlias

; RebreathAutoRepair v0.1.0
; Silent reset events only. No PlayIdle, Cast, or Elden Rim spell is invoked.

Int _runSerial = 0
Bool _receivedPlayerLoadEvent = False
Bool _traceEnabled = True

Event OnInit()
    ; Fallback for the first load after installing this plugin on an existing save.
    If !_receivedPlayerLoadEvent
        StartRepairCycle(True)
    EndIf
EndEvent

Event OnPlayerLoadGame()
    _receivedPlayerLoadEvent = True
    StartRepairCycle(False)
EndEvent

Function StartRepairCycle(Bool abUseFirstInstallFallback)
    Int mySerial = 0
    String iniPath = "Data/SKSE/Plugins/RebreathAutoRepair.ini"
    Bool enabled = True
    Float initFallbackDelay = 10.0
    Actor playerRef = None
    Bool waitFor3D = True
    Float maxWaitFor3D = 60.0
    Float pollInterval = 0.25
    Float waitedFor3D = 0.0
    Float delayAfter3D = 5.0
    Float rewaited = 0.0
    Bool doIdleStop = True
    Bool doStaggerStop = True
    Bool doMcoDodgeStop = False
    Bool doIdleCombatStart = False
    Int repairAttempts = 2
    Float retryInterval = 3.0
    Int attempt = 0

    _runSerial += 1
    mySerial = _runSerial

    enabled = PapyrusIniManipulator.PullBoolFromIni(iniPath, "General", "Enabled", True)
    _traceEnabled = PapyrusIniManipulator.PullBoolFromIni(iniPath, "Logging", "EnableTrace", True)

    If !enabled
        TraceLog("Disabled in INI; no action taken.")
        Return
    EndIf

    initFallbackDelay = PapyrusIniManipulator.PullFloatFromIni(iniPath, "General", "InitFallbackDelay", 10.0)
    If initFallbackDelay < 0.0
        initFallbackDelay = 0.0
    ElseIf initFallbackDelay > 60.0
        initFallbackDelay = 60.0
    EndIf

    If abUseFirstInstallFallback
        TraceLog("Alias OnInit fallback started.")
        If initFallbackDelay > 0.0
            Utility.Wait(initFallbackDelay)
        EndIf
        If mySerial != _runSerial || _receivedPlayerLoadEvent
            TraceLog("Init fallback cancelled; a player-load event took over.")
            Return
        EndIf
    EndIf

    playerRef = GetReference() as Actor
    If playerRef == None
        playerRef = Game.GetPlayer()
    EndIf
    If playerRef == None
        TraceLog("ERROR: Player reference unavailable; repair aborted.")
        Return
    EndIf

    waitFor3D = PapyrusIniManipulator.PullBoolFromIni(iniPath, "General", "WaitFor3D", True)
    maxWaitFor3D = PapyrusIniManipulator.PullFloatFromIni(iniPath, "General", "MaxWaitFor3D", 60.0)
    pollInterval = PapyrusIniManipulator.PullFloatFromIni(iniPath, "General", "PollInterval", 0.25)

    If maxWaitFor3D < 0.0
        maxWaitFor3D = 0.0
    ElseIf maxWaitFor3D > 180.0
        maxWaitFor3D = 180.0
    EndIf
    If pollInterval < 0.10
        pollInterval = 0.10
    ElseIf pollInterval > 1.0
        pollInterval = 1.0
    EndIf

    If waitFor3D
        waitedFor3D = 0.0
        While !playerRef.Is3DLoaded() && waitedFor3D < maxWaitFor3D
            If mySerial != _runSerial
                TraceLog("3D wait cancelled by a newer load event.")
                Return
            EndIf
            Utility.Wait(pollInterval)
            waitedFor3D += pollInterval
        EndWhile
        If !playerRef.Is3DLoaded()
            TraceLog("ERROR: Player 3D did not become ready; repair skipped.")
            Return
        EndIf
    ElseIf !playerRef.Is3DLoaded()
        TraceLog("ERROR: WaitFor3D is disabled but player 3D is not loaded.")
        Return
    EndIf

    delayAfter3D = PapyrusIniManipulator.PullFloatFromIni(iniPath, "General", "DelayAfter3D", 5.0)
    If delayAfter3D < 0.0
        delayAfter3D = 0.0
    ElseIf delayAfter3D > 120.0
        delayAfter3D = 120.0
    EndIf

    TraceLog("Player 3D ready; waiting DelayAfter3D=" + delayAfter3D)
    If delayAfter3D > 0.0
        Utility.Wait(delayAfter3D)
    EndIf
    If mySerial != _runSerial
        TraceLog("Post-3D delay cancelled by a newer load event.")
        Return
    EndIf

    If !playerRef.Is3DLoaded()
        TraceLog("Player 3D unloaded during delay; waiting again.")
        rewaited = 0.0
        While !playerRef.Is3DLoaded() && rewaited < maxWaitFor3D
            If mySerial != _runSerial
                Return
            EndIf
            Utility.Wait(pollInterval)
            rewaited += pollInterval
        EndWhile
        If !playerRef.Is3DLoaded()
            TraceLog("ERROR: Player 3D did not reload; repair skipped.")
            Return
        EndIf
    EndIf

    doIdleStop = PapyrusIniManipulator.PullBoolFromIni(iniPath, "Events", "IdleStop", True)
    doStaggerStop = PapyrusIniManipulator.PullBoolFromIni(iniPath, "Events", "StaggerStop", True)
    doMcoDodgeStop = PapyrusIniManipulator.PullBoolFromIni(iniPath, "Events", "MCODodgeStop", False)
    doIdleCombatStart = PapyrusIniManipulator.PullBoolFromIni(iniPath, "Events", "IdleCombatStart", False)

    repairAttempts = PapyrusIniManipulator.PullIntFromIni(iniPath, "General", "RepairAttempts", 2)
    If repairAttempts < 1
        repairAttempts = 1
    ElseIf repairAttempts > 5
        repairAttempts = 5
    EndIf
    retryInterval = PapyrusIniManipulator.PullFloatFromIni(iniPath, "General", "RetryInterval", 3.0)
    If retryInterval < 1.5
        retryInterval = 1.5
    ElseIf retryInterval > 30.0
        retryInterval = 30.0
    EndIf

    TraceLog("Beginning silent reset sequence. Attempts=" + repairAttempts)
    attempt = 0
    While attempt < repairAttempts
        If mySerial != _runSerial
            TraceLog("Repair sequence cancelled by a newer load event.")
            Return
        EndIf
        If playerRef.Is3DLoaded()
            If doIdleStop
                Debug.SendAnimationEvent(playerRef, "IdleStop")
                TraceLog("Sent event: IdleStop")
            EndIf
            If doStaggerStop
                Debug.SendAnimationEvent(playerRef, "staggerStop")
                TraceLog("Sent event: staggerStop")
            EndIf
            If doMcoDodgeStop
                Debug.SendAnimationEvent(playerRef, "MCO_DodgeStop")
                TraceLog("Sent event: MCO_DodgeStop")
            EndIf
            If doIdleCombatStart
                Debug.SendAnimationEvent(playerRef, "IdleCombatStart")
                TraceLog("Sent event: IdleCombatStart")
            EndIf
        Else
            TraceLog("Player 3D unloaded at attempt time; this attempt skipped.")
        EndIf

        attempt += 1
        If attempt < repairAttempts
            Utility.Wait(retryInterval)
        EndIf
    EndWhile

    ; Mirrors the original effect's 1.5-second guard window without writing Elden Rim globals.
    Utility.Wait(1.5)
    If mySerial == _runSerial
        TraceLog("Finished. No Taunt, PlayIdle, or spell was invoked.")
    EndIf
EndFunction

Function TraceLog(String message)
    If _traceEnabled
        Debug.Trace("[RebreathAutoRepair] " + message, 0)
    EndIf
EndFunction
