Scriptname PapyrusIniManipulator Hidden

; Compile-time declarations for Papyrus Ini Manipulator.
; Runtime PEX and SKSE DLL must come from the installed PIM mod.
Bool Function PullBoolFromIni(String sPath, String sSection, String sKey, Bool bDefault = False) Global Native
Int Function PullIntFromIni(String sPath, String sSection, String sKey, Int iDefault = 0) Global Native
Float Function PullFloatFromIni(String sPath, String sSection, String sKey, Float fDefault = 0.0) Global Native
String Function PullStringFromIni(String sPath, String sSection, String sKey, String sDefault = "") Global Native
