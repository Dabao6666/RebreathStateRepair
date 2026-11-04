Scriptname RebreathAutoRepairAlias extends ReferenceAlias

; Rebreath Auto Repair v0.2.0
; Save-load cleanup for SCSI Magic of Tamriel + original Elden Rim Rebreath reset.
; This patch does not cast spells, play Taunt, alter races, or write mod globals.

Int _runSerial = 0
Bool _receivedPlayerLoadEvent = False
Bool _busy = False
Bool _autoPending = False
Int _manualHotkey = 24
Float _postLoadFadeGrace = 3.0
Float _gameplayDelay = 1.5
Float _pollInterval = 0.25
Float _maxGameplayWait = 180.0

Event OnInit()
    RegisterDiagnosticsAndHotkey()
    TraceLog("Initialized. Manual test hotkey is O (scan code 24).")
    If !_receivedPlayerLoadEvent
        StartAutomaticCycle(True)
    EndIf
EndEvent

Event OnPlayerLoadGame()
    _receivedPlayerLoadEvent = True
    RegisterDiagnosticsAndHotkey()
    TraceLog("OnPlayerLoadGame received. Waiting for post-load gameplay state.")
    StartAutomaticCycle(False)
EndEvent

Event OnMenuOpen(String menuName)
    If menuName == "Loading Menu"
        TraceLog("Loading Menu opened; countdown paused.")
    EndIf
EndEvent

Event OnMenuClose(String menuName)
    If menuName == "Loading Menu"
        TraceLog("Loading Menu closed; waiting for Player 3D and fade grace.")
    EndIf
EndEvent

Event OnKeyDown(Int keyCode)
    Actor playerRef
    Int mySerial
    If keyCode != _manualHotkey
        Return
    EndIf
    If _busy && _autoPending
        _runSerial += 1
        _autoPending = False
        _busy = False
        TraceLog("O cancelled pending automatic trigger; manual test takes over.")
    ElseIf _busy
        Debug.Notification("Rebreath Auto Repair: a repair sequence is already running.")
        Return
    EndIf
    playerRef = GetReference() as Actor
    If playerRef == None
        playerRef = Game.GetPlayer()
    EndIf
    If playerRef == None
        Debug.Notification("Rebreath Auto Repair: player reference unavailable.")
        TraceLog("ERROR: O received but player reference is None.")
        Return
    EndIf
    If !IsGameplayReady(playerRef)
        Debug.Notification("Rebreath Auto Repair: wait until the loading screen has closed.")
        TraceLog("O received before gameplay readiness; no events sent.")
        Return
    EndIf
    _runSerial += 1
    mySerial = _runSerial
    _busy = True
    _autoPending = False
    Debug.Notification("Rebreath Auto Repair: O received; clearing SCSI states and sending original events.")
    TraceLog("Manual O test started.")
    ExecuteRepairSequence(playerRef, mySerial, "manual O")
EndEvent

Function RegisterDiagnosticsAndHotkey()
    UnregisterForAllKeys()
    RegisterForKey(_manualHotkey)
    UnregisterForAllMenus()
    RegisterForMenu("Loading Menu")
    TraceLog("Registered O hotkey (DIK_O 24) and Loading Menu diagnostics.")
EndFunction

Function StartAutomaticCycle(Bool useFirstInstallFallback)
    Int mySerial
    Actor playerRef
    Float graceElapsed
    Float countdownElapsed
    _runSerial += 1
    mySerial = _runSerial
    _busy = True
    _autoPending = True
    If useFirstInstallFallback
        Utility.Wait(1.0)
        If mySerial != _runSerial || _receivedPlayerLoadEvent
            TraceLog("OnInit fallback cancelled; player-load event took over.")
            Return
        EndIf
    EndIf
    playerRef = GetReference() as Actor
    If playerRef == None
        playerRef = Game.GetPlayer()
    EndIf
    If playerRef == None
        _autoPending = False
        _busy = False
        TraceLog("ERROR: Player unavailable; automatic repair aborted.")
        Return
    EndIf
    TraceLog("Waiting for Player 3D, Loading Menu closed and non-menu gameplay.")
    If !WaitForGameplay(playerRef, _maxGameplayWait, mySerial)
        If mySerial == _runSerial
            _autoPending = False
            _busy = False
            TraceLog("ERROR: Gameplay not ready before timeout; repair skipped.")
        EndIf
        Return
    EndIf
    TraceLog("Load gate passed. Starting separate 3.0-second post-load fade grace.")
    graceElapsed = 0.0
    While graceElapsed < _postLoadFadeGrace
        If mySerial != _runSerial
            Return
        EndIf
        If IsGameplayReady(playerRef)
            Utility.Wait(_pollInterval)
            graceElapsed += _pollInterval
        Else
            TraceLog("Load/menu state returned during fade grace; grace restarts.")
            graceElapsed = 0.0
            If !WaitForGameplay(playerRef, _maxGameplayWait, mySerial)
                If mySerial == _runSerial
                    _autoPending = False
                    _busy = False
                    TraceLog("ERROR: Gameplay did not return during fade grace.")
                EndIf
                Return
            EndIf
        EndIf
    EndWhile
    If mySerial != _runSerial
        Return
    EndIf
    Debug.Notification("Rebreath Auto Repair: fade grace complete; starting 1.5-second countdown.")
    TraceLog("Starting separate 1.5-second gameplay-only countdown.")
    countdownElapsed = 0.0
    While countdownElapsed < _gameplayDelay
        If mySerial != _runSerial
            Return
        EndIf
        If IsGameplayReady(playerRef)
            Utility.Wait(_pollInterval)
            countdownElapsed += _pollInterval
        Else
            TraceLog("Menu/loading interruption; preserve elapsed gameplay countdown.")
            If !WaitForGameplay(playerRef, _maxGameplayWait, mySerial)
                If mySerial == _runSerial
                    _autoPending = False
                    _busy = False
                    TraceLog("ERROR: Gameplay did not return during countdown.")
                EndIf
                Return
            EndIf
        EndIf
    EndWhile
    If mySerial != _runSerial
        Return
    EndIf
    _autoPending = False
    TraceLog("Automatic countdown complete; clearing SCSI states and dispatching original four events.")
    ExecuteRepairSequence(playerRef, mySerial, "automatic after post-load gate")
EndFunction

Bool Function WaitForGameplay(Actor playerRef, Float maxWait, Int mySerial)
    Float waited = 0.0
    While !IsGameplayReady(playerRef) && waited < maxWait
        If mySerial != _runSerial
            Return False
        EndIf
        Utility.Wait(_pollInterval)
        waited += _pollInterval
    EndWhile
    If mySerial != _runSerial
        Return False
    EndIf
    Return IsGameplayReady(playerRef)
EndFunction

Bool Function IsGameplayReady(Actor playerRef)
    If playerRef == None
        Return False
    EndIf
    If !playerRef.Is3DLoaded()
        Return False
    EndIf
    If Utility.IsInMenuMode()
        Return False
    EndIf
    If UI.IsMenuOpen("Loading Menu")
        Return False
    EndIf
    Return True
EndFunction

Function ExecuteRepairSequence(Actor playerRef, Int mySerial, String triggerSource)
    Float playerHealth
    If mySerial != _runSerial
        Return
    EndIf
    If !IsGameplayReady(playerRef)
        TraceLog("Sequence refused: Player 3D/gameplay not ready.")
        _busy = False
        _autoPending = False
        Return
    EndIf

    ; SCSI_MagicBlockingScript sets IsBlocking=True in OnEffectStart and clears
    ; it only in OnEffectFinish. Saving/loading can expose a stale animation var.
    ; A loaded player is no longer sustaining a ward cast, so clear this flag.
    playerHealth = playerRef.GetActorValue("Health")
    If playerHealth > 0.0
        playerRef.SetAnimationVariableBool("IsBlocking", False)
        TraceLog(triggerSource + ": cleared SCSI IsBlocking animation variable.")

        ; SCSI_AddBleedoutFX_Target pairs bleedOutStart with bleedOutStop.
        ; Only send the stop event for a living player.
        Debug.SendAnimationEvent(playerRef, "bleedOutStop")
        TraceLog(triggerSource + ": sent SCSI bleedOutStop")
    Else
        TraceLog(triggerSource + ": skipped SCSI animation cleanup because player Health <= 0.")
    EndIf

    ; Exact original event order from EldenRebreatheAttacks.pex.
    Debug.SendAnimationEvent(playerRef, "IdleStop")
    TraceLog(triggerSource + ": sent IdleStop")

    Debug.SendAnimationEvent(playerRef, "staggerStop")
    TraceLog(triggerSource + ": sent staggerStop")

    Debug.SendAnimationEvent(playerRef, "MCO_DodgeStop")
    TraceLog(triggerSource + ": sent MCO_DodgeStop")

    Debug.SendAnimationEvent(playerRef, "IdleCombatStart")
    TraceLog(triggerSource + ": sent IdleCombatStart")

    If triggerSource == "manual O"
        Debug.Notification("Rebreath Auto Repair: SCSI cleanup + 4 original events sent. Check the character now.")
    EndIf

    Utility.Wait(1.5)
    If mySerial == _runSerial
        TraceLog(triggerSource + ": SCSI cleanup and four Rebreath events dispatched; sequence finished.")
        _busy = False
        _autoPending = False
    EndIf
EndFunction

Function TraceLog(String message)
    Debug.Trace("[RebreathAutoRepair v0.2.0] " + message, 0)
EndFunction
