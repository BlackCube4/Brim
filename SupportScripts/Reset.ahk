#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#NoTrayIcon
DetectHiddenWindows, On

EnvGet, MainScript, MainScript
WinGet, MainScriptPID, PID, ahk_id %MainScript%
ParentDir:=RegExReplace(A_ScriptDir,"\\[^\\]+$")
Process, Close, %MainScriptPID%
FileDelete, %ParentDir%\Config\Brim.ini
run %ParentDir%\Brim.ahk
return