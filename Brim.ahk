#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On
#Singleinstance, Force
#Include %A_ScriptDir%\SupportScripts\GetNumberOfLines.ahk
OnExit, ExitLabel

 ;##############################################################################################
;make Gui movable
OnMessage(0x201, "WM_LBUTTONDOWn") ; Nötig fürs Guis ohne Caption.
WM_LBUTTONDOWN()
{
	MouseGetPos, , OutputVarY,
	if (A_Gui="Main" and OutputVarY>180)
		{
			;If (A_GuiControl = "") ; Klick auf den Hintergrund der GUI
				PostMessage, 0xA1, 2, 0 ; sehr sehr alter Trick von SKAN: 0xA1 = WM_NCLBUTTONDOWN
		}
}

;###########################################################################################
;create Custom Tray Icon/Menu
Menu, Tray, NoStandard
Menu, Tray, Add, Restore, Restore
Menu, Tray, Add, Rescan, Rescan
Menu, Tray, Add, Show, Show
Menu, Tray, add, Exit, GuiClose
Menu, Tray, Default, Show
Menu, Tray, Click, 1
Menu, tray, Icon , %A_ScriptDir%\Images\icon.ico

;Make Tray Menu Dark
uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
DllCall(SetPreferredAppMode, "int", 1) ; Dark
DllCall(FlushMenuThemes)

;get current Settings
RunWait, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /stab Config\MultiMonitorToolTab.txt, , Hide

;get monitor Count
monitorCount := GetNumberOfLines("Config\MultiMonitorToolTab.txt")-1

if !FileExist(A_ScriptDir . "\Config\Brim.ini")
{
	msgbox, Achtung! Sie starten Brim zum ersten Mal, daher ist es wichtig, dass sie alle Monitore in ihrer Idealkonfiguration eingerichtet und eingeschaltet haben bevor sie auf OK klicken. `n`n(Dieser Text kann auch erscheinen, falls sie Brim zurückgesetzt haben, oder das Program beim letzten mal nicht ordentlich geschlossen wurde.)
}

loop %monitorCount% {
	FileReadLine, line, Config\MultiMonitorToolTab.txt, % A_Index + 1
	RegExMatch(line, "(\d+) X (\d+)\t([\d-]+), ([\d-]+)\t([\d-]+), ([\d-]+)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t(\d+)\t(\d+)\t([^\t\n]*)\t(\d+) X (\d+)\t[^\t\n]*(\d)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)", SubPart)
	monitor%Subpart15% := {}
	monitor%Subpart15%.MonitorID := Subpart19
	;monitor%Subpart15%.BitsPerPixel := Subpart10
	monitor%Subpart15%.Width := Subpart1
	monitor%Subpart15%.Height := Subpart2
	;monitor%Subpart15%.DisplayFrequency := Subpart11
	monitor%Subpart15%.DisplayOrientation := Subpart12
	
	if monitor%Subpart15%.DisplayOrientation = "90 Degrees"
		monitor%Subpart15%.DisplayOrientation := 1
	else if monitor%Subpart15%.DisplayOrientation = "180 Degrees"
		monitor%Subpart15%.DisplayOrientation := 2
	else if monitor%Subpart15%.DisplayOrientation = "270 Degrees"
		monitor%Subpart15%.DisplayOrientation := 3
	else
		monitor%Subpart15%.DisplayOrientation := 0
	
	monitor%Subpart15%.PositionX := Subpart3
	monitor%Subpart15%.PositionY := Subpart4
	monitor%Subpart15%.MonitorName := Subpart22
	monitor%Subpart15%.Primary := Subpart9
	monitor%Subpart15%.Active := Subpart7
	
	;set default value in case no ini equivalent exists
	monitor%Subpart15%.Power := 1
	monitor%Subpart15%.Opaque := 1
	monitor%Subpart15%.Brightness := 50
}

;###########################################################################################
;Get Dpi Scaling
loop %monitorCount% {
	RunWait, %ComSpec% /c ExternalTools\SetDpi.exe value %A_Index% > Config\Dpi%A_Index%.txt, , Hide
	FileRead, Dpi, Config\Dpi%A_Index%.txt
	monitor%A_Index%.Dpi := Dpi
}
;msgbox % monitor1.Dpi " " monitor2.Dpi " " monitor3.Dpi

;###########################################################################################
;Override missing Values with last Values
loop %monitorCount% {
	ID:=monitor%A_Index%.MonitorID
	IniRead, PositionX, %A_ScriptDir%\Config\Brim.ini, %ID%, PositionX
	if (PositionX = "ERROR") {
		;msgbox, %ID%
		continue
	}
	IniRead, PositionX, %A_ScriptDir%\Config\Brim.ini, %ID%, PositionX, 0
	IniRead, PositionY, %A_ScriptDir%\Config\Brim.ini, %ID%, PositionY, 0
	IniRead, DisplayOrientation, %A_ScriptDir%\Config\Brim.ini, %ID%, DisplayOrientation, 0
	IniRead, Dpi, %A_ScriptDir%\Config\Brim.ini, %ID%, Dpi, 100
	IniRead, Power, %A_ScriptDir%\Config\Brim.ini, %ID%, Power, 1
	IniRead, Opaque, %A_ScriptDir%\Config\Brim.ini, %ID%, Opaque, 1
	IniRead, Brightness, %A_ScriptDir%\Config\Brim.ini, %ID%, Brightness, 50
	;msgbox, %PositionX% %PositionY% %DisplayOrientation% %Dpi% %Power% %Opaque% %Brightness%
	monitor%A_Index%.PositionX := PositionX
	monitor%A_Index%.PositionY := PositionY
	monitor%A_Index%.DisplayOrientation := DisplayOrientation
	monitor%A_Index%.Dpi := Dpi
	monitor%A_Index%.Power := Power
	monitor%A_Index%.Opaque := Opaque
	monitor%A_Index%.Brightness := Brightness
}

;###########################################################################################
;Create Dimm Guis for used Monitors
loop % monitorCount {
	;msgbox, % monitor%A_Index%.PositionX " " monitor%A_Index%.PositionY " " monitor%A_Index%.DisplayOrientation
	Gui, %A_Index%: New, , %A_Index%Overlay5832994
 	Gui, %A_Index%: Color, 0x000000 ; Color to black
	Gui, %A_Index%: -SysMenu +ToolWindow +LastFound +AlwaysOnTop -Caption +E0x20 ; Click through GUI always on top
	WinSet, Transparent, 0 ; Set transparency
	Width := monitor%A_Index%.Width / (monitor%A_Index%.Dpi / 100)
	Height := monitor%A_Index%.Height  / (monitor%A_Index%.Dpi / 100)
	Gui, %A_Index%:Show, % "x" . monitor%A_Index%.PositionX . " y" . monitor%A_Index%.PositionY . " w" . Width . " h" . Height
	Gui, %A_Index%:Hide
}

;###########################################################################################
;create main Gui
Gui, Main:New, HwndBrim, Brim
Gui, Main:Margin , 15, 15
GuiColor := "0x191919"
GuiElementsColor := "0x191919"
Gui, Main:Font, s10 q4, ;Segoe UI
Gui, Main:Color, %GuiColor%, %GuiElementsColor%

loop % monitorCount {
	if (monitor%A_Index%.Primary = "Yes")
		Checked:="Checked"
	else
		Checked:=""
	if (monitor%A_Index%.Active = "Yes")
		Disabled:=""
	else
		Disabled:="Disabled"
	if (A_Index=1)
		Gui, Main:Add, Radio, x20 y26 w15 h15 vPrimary%A_Index% gPrimary %Checked% %Disabled%
	else
		Gui, Main:Add, Radio, x20 y+25 w15 h15 vPrimary%A_Index% gPrimary %Checked% %Disabled%
}

loop % monitorCount {

	
	if (monitor%A_Index%.Active = "Yes") {
		Checked:="Checked"
		Disabled:=""
	}
	else {
		Checked:=""
		Disabled:="Disabled"
	}
	if (monitor%A_Index%.Power = 1)
		CheckedPower:="Checked"
	else
		CheckedPower:=""
		
		
	if (A_Index=1)
		Gui, Main:Add, CheckBox, %Checked% x40 y25 w15 h18 vActive%A_Index% gActive,
	else
		Gui, Main:Add, CheckBox, %Checked% x40 y+22 w15 hp vActive%A_Index% gActive,
	Gui, Main:Add, CheckBox, %Disabled% %CheckedPower% x+5 wp hp vPower%A_Index% gPower,
	Gui, Main:Add, CheckBox, %Disabled% Checked x+5 wp hp vOpaque%A_Index% gOpaque,
	Gui, Main:Add, Text, x+3 y+-18 w83 h18 cFFFFFF, % monitor%A_Index%.MonitorName
	Gui, Main:Add, Slider, %Disabled% vBrightness%A_Index% gChangeBrightness x+0 y+-20 w200 h25 Range-50-100 NoTicks Page20 Line10 AltSubmit Tooltip, % monitor%A_Index%.Brightness
	Gui, Main:Add, Text, vinfo%A_Index% x+4 y+-23 w20 h18 cFFFFFF -E0x200 right, % monitor%A_Index%.Brightness
}

Gui, Main:Add, Picture, x37 y+25 w9 h13 gActivateAll, %A_ScriptDir%\Images\checkbox_jes.png
Gui, Main:Add, Picture, x+0 w9 h13 gActivateNone, %A_ScriptDir%\Images\checkbox_no.png
Gui, Main:Add, Picture, x+2 w9 h13 gPowerAll, %A_ScriptDir%\Images\checkbox_jes.png
Gui, Main:Add, Picture, x+0 w9 h13 gPowerNone, %A_ScriptDir%\Images\checkbox_no.png
Gui, Main:Add, Picture, x+2 w9 h13 gOpaqueAll, %A_ScriptDir%\Images\checkbox_jes.png
Gui, Main:Add, Picture, x+0 w9 h13 gOpaqueNone, %A_ScriptDir%\Images\checkbox_no.png

Gui, Main:Add, Text, x+3 y+-14 w83 h18 cFFFFFF,  All Monitors
Gui, Main:Add, Slider, vBrigthnessAll gBrigthnessAll x+0 y+-20 w200 h25 Range-50-100 NoTicks Page20 Line10 AltSubmit Tooltip, 50		;AltSubmit Not enough Performance
Gui, Main:Add, Text, vinfoAll x+4 y+-23 w20 h18 cFFFFFF -E0x200 right, 50
Gui, Main:Add, Picture, vminimizeToTray gminimizeToTray x100 y+25 w150 h16, %A_ScriptDir%\Images\arrow_down.png

Gui, Main:-Caption +ToolWindow +AlwaysOnTop +LastFound
Gui, Main:Color, 1A1A1A
Gui, Main:Show, x1676 y8140
WinGetPos X, Y, Width, Height, ahk_id %Brim%
GuiControl, move, minimizeToTray, % "x" (Width-150)/2
WinSet, Region,0-0 w%Width% h%Height% R15-15

width9:=Width-9
width17:=Width-17
height9:=Height-9
height17:=Height-17

Gui, Main:Add, Picture, x0 y0 w8 h8, %A_ScriptDir%\Images\topleft.png
Gui, Main:Add, Picture, x8 y0 w%width17% h8, %A_ScriptDir%\Images\top.png
Gui, Main:Add, Picture, x%width9% y0 w8 h8, %A_ScriptDir%\Images\topright.png
Gui, Main:Add, Picture, x%width9% y8 w8 h%height17%, %A_ScriptDir%\Images\right.png
Gui, Main:Add, Picture, x%width9% y%height9% w8 h8, %A_ScriptDir%\Images\botright.png
Gui, Main:Add, Picture, x8 y%height9% w%width17% h8, %A_ScriptDir%\Images\bot.png
Gui, Main:Add, Picture, x0 y%height9% w8 h8, %A_ScriptDir%\Images\botleft.png
Gui, Main:Add, Picture, x0 y8 w8 h%height17%, %A_ScriptDir%\Images\left.png

MaxX := A_ScreenWidth - Width + 1 - 10  ; This will put the Gui to the right
MaxY := A_ScreenHeight - Height - 46 - 11 ; This will put the Gui above the taskbar

WinMove ahk_id %Brim%, , %MaxX%, %MaxY%
FileDelete, %A_ScriptDir%\Config\Brim.ini
return

Primary:
	Primary := SubStr(A_GuiControl, 8)
	Run, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /SetPrimary %Primary%, , Hide
	PrimaryX := monitor%Primary%.PositionX
	PrimaryY := monitor%Primary%.PositionY
	loop %monitorCount% {
		monitor%A_Index%.PositionX := monitor%A_Index%.PositionX - PrimaryX
		monitor%A_Index%.PositionY := monitor%A_Index%.PositionY - PrimaryY
		WinMove, %A_Index%Overlay5832994, , monitor%A_Index%.PositionX, monitor%A_Index%.PositionY
		monitor%A_Index%.Primary := "No"
	}
	monitor%Primary%.Primary := "Yes"
return

Active:
	MonitorNumber := SubStr(A_GuiControl, 7)
	GuiControlGet, Active, , %A_GuiControl%
	if (Active = 0) {
		Run, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /disable %MonitorNumber%, , Hide
		GuiControl, disable, Primary%MonitorNumber%
		GuiControl, disable, Power%MonitorNumber%
		GuiControl, disable, Opaque%MonitorNumber%
		GuiControl, disable, Brightness%MonitorNumber%
	}
	else {
		PositionX:=monitor%MonitorNumber%.PositionX
		PositionY:=monitor%MonitorNumber%.PositionY
		DisplayOrientation:=monitor%MonitorNumber%.DisplayOrientation
		Run, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /SetMonitors "Name=\\.\DISPLAY%MonitorNumber% PositionX=%PositionX% PositionY=%PositionY% DisplayOrientation=%DisplayOrientation%", ,Hide
		GuiControl, enable, Primary%MonitorNumber%
		GuiControl, enable, Power%MonitorNumber%
		GuiControl, enable, Opaque%MonitorNumber%
		GuiControl, enable, Brightness%MonitorNumber%
		WinMove, %MonitorNumber%Overlay5832994, , , , monitor%MonitorNumber%.Width, monitor%MonitorNumber%.Height
	}
return

Power:
	MonitorNumber := SubStr(A_GuiControl, 6)
	GuiControlGet, Power, , %A_GuiControl%
	ID:=monitor%MonitorNumber%.MonitorID
	if (Power = 0) {
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /TurnOff %ID%, , Hide
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %ID% D6 4, , Hide
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %ID% D6 5, , Hide
		;GuiControl, disable, Opaque%MonitorNumber%
		GuiControl, disable, Brightness%MonitorNumber%
	}
	else {
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /TurnOn %ID%, , Hide
		;GuiControl, enable, Opaque%MonitorNumber%
		GuiControl, enable, Brightness%MonitorNumber%
	}
return

Opaque:
	MonitorNumber := SubStr(A_GuiControl, 7)
	GuiControlGet, Opaque, , %A_GuiControl%
	if (Opaque = 0) {
		Gui, %MonitorNumber%: Show
		WinSet, Transparent, 255, %MonitorNumber%Overlay5832994
		Gui, Main:Show
		GuiControl, disable, Brightness%MonitorNumber%
	}
	else {
		GuiControlGet, Brightness, , % Brightness%MonitorNumber%
		if (Brightness < 0) {
			Brightness := Brightness * -4
			WinSet, Transparent, %Brightness%, %MonitorNumber%Overlay5832994
		}
		else
			Gui, %MonitorNumber%: Hide
		GuiControl, enable, Brightness%MonitorNumber%
	}
return

ChangeBrightness:
	if (A_GuiEvent=5) {
		sleep 50
	}
	MonitorNumber := SubStr(A_GuiControl, 11)
	GuiControlGet, Brightness, , %A_GuiControl%
	GuiControl, Text, info%MonitorNumber%, %Brightness%
	MonitorID := monitor%MonitorNumber%.MonitorID
	if (Brightness < 0) {
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %MonitorID% 10 0, , Hide
		Gui, %MonitorNumber%: Show
		Brightness := Brightness * -4
		WinSet, Transparent, %Brightness%, %MonitorNumber%Overlay5832994
	}
	else {
		Gui, %MonitorNumber%: Hide
		Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %MonitorID% 10 %Brightness%, , Hide
	}
return

ActivateAll:
	Instruction:=""
	loop %monitorCount% {
		GuiControlGet, Active, , Active%A_Index%
		if (Active = 0) {
			PositionX:=monitor%A_Index%.PositionX
			PositionY:=monitor%A_Index%.PositionY
			DisplayOrientation:=monitor%A_Index%.DisplayOrientation
			Instruction := Instruction . """Name=\\.\DISPLAY" . A_Index . " PositionX=" . PositionX . " PositionY=" . PositionY . " DisplayOrientation=" . DisplayOrientation . """ "
			RunWait, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /enable %A_Index%, ,Hide
			GuiControl, , Active%A_Index%, 1
			GuiControl, enable, Primary%A_Index%
			GuiControl, enable, Power%A_Index%
			GuiControl, enable, Opaque%A_Index%
			GuiControl, enable, Brightness%A_Index%
			WinMove, %A_Index%Overlay5832994, , , , monitor%A_Index%.Width, monitor%A_Index%.Height
		}
	}
	;msgbox %Instruction%
	RunWait, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /SetMonitors %Instruction%, ,Hide
return

;DeactivateAll would have been smarter
ActivateNone:
	loop %monitorCount% {
		if (monitor%A_Index%.Primary="No") {
			Run, %ComSpec% /c ExternalTools\MultiMonitorTool.exe /disable %A_Index%, , Hide
			GuiControl, , Active%A_Index%, 0
			GuiControl, disable, Power%A_Index%
			GuiControl, disable, Opaque%A_Index%
			GuiControl, disable, Brightness%A_Index%
		}
	}
return

PowerAll:
	loop %monitorCount% {
		GuiControlGet, Enabled, Enabled, Power%A_Index%
		if (Enabled=1) {
			GuiControl, , Power%A_Index%, 1
			;GuiControl, enable, Opaque%A_Index%
			GuiControl, enable, Brightness%A_Index%
			ID:=monitor%A_Index%.MonitorID
			Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /TurnOn %ID%, , Hide
		}
	}
return

PowerNone:
	loop %monitorCount% {
		GuiControlGet, Enabled, Enabled, Power%A_Index%
		if (Enabled=1) {
			GuiControl, , Power%A_Index%, 0
			;GuiControl, disable, Opaque%A_Index%
			GuiControl, disable, Brightness%A_Index%
			ID:=monitor%A_Index%.MonitorID
			Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /TurnOff %ID%, , Hide
			Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %ID% D6 4, , Hide
			Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %ID% D6 5, , Hide
		}
	}
	MouseGetPos, OutputVarX, OutputVarY
	loop {
		MouseGetPos, OutputVarX2, OutputVarY2
		if (OutputVarX2!=OutputVarX or OutputVarY2!=OutputVarY)
			Goto, PowerAll
		else
			sleep 1000
	}
return

OpaqueAll:
	loop %monitorCount% {
		GuiControlGet, Enabled, Enabled, Opaque%A_Index%
		if (Enabled=1) {
			GuiControl, , Opaque%A_Index%, 1
			GuiControl, enable, Brightness%A_Index%
			GuiControlGet, Brightness, , % Brightness%A_Index%
			if (Brightness < 0) {
				Brightness := Brightness * -4
				WinSet, Transparent, %Brightness%, %A_Index%Overlay5832994
			}
			else
				Gui, %A_Index%: Hide
		}
	}
return

OpaqueNone:
	loop %monitorCount% {
		GuiControlGet, Enabled, Enabled, Opaque%A_Index%
		if (Enabled=1) {
			GuiControl, , Opaque%A_Index%, 0
			GuiControl, disable, Brightness%A_Index%
			Gui, %A_Index%: Show
			WinSet, Transparent, 255, %A_Index%Overlay5832994
		}
	}
	Gui, Main:Show
return

BrigthnessAll:
	if (A_GuiEvent=5) {
		sleep 50
	}
	GuiControlGet, Brightness, , %A_GuiControl%
	GuiControl, Text, infoAll, %Brightness%
	
	loop %monitorCount% {
		GuiControlGet, Enabled, Enabled, Brightness%A_Index%
		if (Enabled=1) {
			MonitorID := monitor%A_Index%.MonitorID
			GuiControl, , Brightness%A_Index%, %Brightness%
			GuiControl, Text, info%A_Index%, %Brightness%
			if (Brightness < 0) {
				Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %MonitorID% 10 0, , Hide
				Gui, %A_Index%: Show
				NewBrightness := Brightness * -4
				WinSet, Transparent, %NewBrightness%, %A_Index%Overlay5832994
			}
			else {
				Gui, %A_Index%: Hide
				Run, %ComSpec% /c ExternalTools\ControlMyMonitor.exe /SetValue %MonitorID% 10 %Brightness%, , Hide
			}
		}
	}
return

minimizeToTray:
	Gui, Hide
return

GuiClose:
	ExitApp
Return

Show:
	Gui, Main:Show
Return

Rescan:
	EnvSet, MainScript, %Brim%
	run %A_ScriptDir%\SupportScripts\Reset.ahk
	;reload
Return

Restore:
	Gui, Main:Show
	WinMove Brim, ,%MaxX%, %MaxY%
Return

~LButton::
	MouseGetPos,,, hWinUM
	if (hWinUM != Brim)
		Gui, Main:Hide
return

ExitLabel:
	Gui, Main:Submit
	loop %monitorCount% {
		Section := monitor%A_Index%.MonitorID
		IniWrite, % monitor%A_Index%.PositionX, %A_ScriptDir%\Config\Brim.ini, %Section%, PositionX
		IniWrite, % monitor%A_Index%.PositionY, %A_ScriptDir%\Config\Brim.ini, %Section%, PositionY
		IniWrite, % monitor%A_Index%.DisplayOrientation, %A_ScriptDir%\Config\Brim.ini, %Section%, DisplayOrientation
		
		IniWrite, % monitor%A_Index%.Dpi, %A_ScriptDir%\Config\Brim.ini, %Section%, Dpi
		IniWrite, % Power%A_Index%, %A_ScriptDir%\Config\Brim.ini, %Section%, Power
		IniWrite, % Opaque%A_Index%, %A_ScriptDir%\Config\Brim.ini, %Section%, Opaque
		IniWrite, % Brightness%A_Index%, %A_ScriptDir%\Config\Brim.ini, %Section%, Brightness
	}
	ExitApp
return 