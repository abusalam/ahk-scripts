#Requires AutoHotkey v2.0

#Include ".env.example"
#Include "*i .env"

^+a::KeepSystemAwake ; Ctrl + Shift + A
^+c::CopyMouseCoords ; Ctrl + Shift + C
^+s::SystemMenu.Show
^+t::ToggleOnTop("HotKey") ; Ctrl+Shift+T
^+w::CheckWebinar ; Ctrl + Shift + H
^+x::TestingAHK ; Ctrl + Shift + X
^+z::ShowCoords() ; Ctrl + Shift + Z


TestingAHK() {
	ClickOnScreen(WebinarPlayButton)
	TrayTip TestVarFromEnv?, "Environment", "Mute"
}

; Global Variables
OutputVarWin 	:= WinExist("A")
AoT_Windows 	:= Map()

; Names for the tray menu items:
k_MenuItemToggleOnTop := "&Always On Top`tCtrl+Shift+T"
k_MenuItemWebinar 		:= "Check &Webinar`tCtrl+Shift+H"
k_MenuItemCopyCoords 	:= "Copy &Coords`tCtrl+Shift+C"
k_MenuItemKeepAwake 	:= "&Keep Awake`tCtrl+Shift+A"
s_MenuItemOpen 				:= "&Open"

; Create the popup menu by adding some items to it.
SystemMenu := Menu()
SystemMenu.AddStandard()

MenuHandler(ItemName, ItemPos, MyMenu) {
    MsgBox("You selected " ItemName)
}

KeepSystemAwake(*) {
	global KeyToKeepSystemAwake
	static TimerStarted := false
	CheckInterval := IsInteger(A_Clipboard) ? (Integer(A_Clipboard) * 1000) : WebinarCheckInterval ; Time in miliseconds

	if(TimerStarted) {
		if(A_TimeIdle > IdleWaitTime) {
			Send KeyToKeepSystemAwake
			ShowToolTip("KeepSystemAwake: Checking again in " CheckInterval " ms.")
		} else {
			TimerStarted := false
			SetTimer , 0  ; i.e. the timer turns itself off here.
			TrayTip "Cancelled!", "KeepSystemAwake", "Mute"
		}
	} else {
		SetTimer(KeepSystemAwake, CheckInterval)
		TimerStarted := true
		TrayTip "Started!", "KeepSystemAwake", "Mute"
		ShowToolTip("KeepSystemAwake: Checking again in " CheckInterval " ms.")
	}
}

ToggleOnTop(ItemName, *){
	
	global OutputVarWin
	global AoT_Windows
	
	if(ItemName=="HotKey") {
		CoordMode "Mouse", "Screen"
		MouseGetPos &OutputVarX, &OutputVarY, &OutputVarWin
	}

	Try {
		WinSetAlwaysOnTop(-1, OutputVarWin)

		if(AoT_Windows.Has(OutputVarWin)) {
			DeletedWindow := AoT_Windows.Delete(OutputVarWin)
			TrayTip("Off: " OutputVarWin, DeletedWindow, "Mute")
			ShowToolTip("Off: " DeletedWindow) 
		} else {
			AoT_Windows[OutputVarWin] :=  WinGetTitle(OutputVarWin)
			TrayTip("AoT: " OutputVarWin, AoT_Windows[OutputVarWin], "Mute")
			ShowToolTip("AoT: " AoT_Windows[OutputVarWin])
		}

	} Catch as e {
		ShowToolTip(OutputVarWin ":" A_LineNumber ":" e.Message)
	}
}

RemoveAoT(ItemName, ItemPos, *) {
	global OutputVarWin
	global AoT_Windows

	TargetWindow := 0
	for key, value in AoT_Windows {
		if(ItemPos == A_Index) {
			TargetWindow := key
			OutputVarWin := TargetWindow
			Break
		}
	}
	if(TargetWindow) {
		ToggleOnTop(TargetWindow)
	}
}

ShowCoords(){
	global OutputVarWin
	global AoT_Windows

	AoT_WindowsMenu := Menu()

	for key, value in AoT_Windows {
		AoT_WindowsMenu.Add(key " " value, RemoveAoT)
	}

	CoordMode("Mouse", "Screen")
	MouseGetPos(&xpos, &ypos, &OutputVarWin)
	Coords := xpos ", " ypos
	c_Menu := Menu()
	c_Menu.Add(Coords, CopyMenuName)
	c_Menu.Add(OutputVarWin ": " WinGetTitle(OutputVarWin), CopyMenuName)
	c_Menu.Add()
	if(AoT_Windows.Count) {
		c_Menu.Add(k_MenuItemToggleOnTop, AoT_WindowsMenu)
	} else {
		c_Menu.Add(k_MenuItemToggleOnTop, ToggleOnTop)
	}
	c_Menu.Add(k_MenuItemWebinar, CheckWebinar)
	c_Menu.Add(k_MenuItemCopyCoords, CopyMouseCoords)
	c_Menu.Add(k_MenuItemKeepAwake, KeepSystemAwake)
	c_Menu.Add()  ; Add a separator line.
	c_Menu.Add(A_ComputerName, SystemMenu)
	; c_Menu.Add()  ; Add a separator line below the submenu.
	; c_Menu.Add(FormatTime(A_Now,"MMM dd HH:mm:ss tt"), MenuHandler)
	Try {
		CopyText := A_Clipboard ? SubStr(A_Clipboard, 1, 150) : "Empty Clipboard"
	} Catch as e {
		CopyText := "Clipboard N/A"
	}
	c_Menu.Add(CopyText, CopyContent)
	c_Menu.Default := A_ComputerName
	c_Menu.Show()
}

CopyMenuName(Item, *) {
	A_Clipboard := Item
	ClipWait
	TrayTip(A_Clipboard, "Copied!", "Mute")
}

CheckWebinar(*) {

	CheckInterval := IsInteger(A_Clipboard) ? (Integer(A_Clipboard) * 1000) : WebinarCheckInterval ; Time in miliseconds
	WebinarTime := 810 ; 810 Minutes means 13:30 PM

	static TimerStarted := false
	RemainingTime := DateDiff(DateAdd(A_Year "" A_Mon "" A_DD, WebinarTime, "Minutes"), A_Now, "Minutes")

	if(RemainingTime <= 0) {
		if(TimerStarted) {
			TrayTip "Started!", "NIC Webinar", "Mute"
			ClickOnScreen(WebinarFullscreenButton) ; Webinar Fullscreen Button
			SetTimer , 0  ; i.e. the timer turns itself off here.
		}
		TrayTip "Ended!", "NIC Webinar", "Mute"
		return
	} else if(!TimerStarted) {
		SetTimer(CheckWebinar, CheckInterval)
		TimerStarted := true
	}
	if(A_TimeIdle > IdleWaitTime) {
		TrayTip(RemainingTime " minutes remaining to start", "NIC Webinar", "Mute")
		RefreshWebinar
	}
	ShowToolTip("Checking again in " CheckInterval " ms.")
}

CopyMouseCoords(*) {
	CoordMode "Mouse", "Screen"
	MouseGetPos &xpos, &ypos
	A_Clipboard := xpos ", " ypos
	ClipWait
	TrayTip A_Clipboard, "Coordinates Copied!", "Mute"
}

CopyContent(MenuItem, *) {
	A_Clipboard := MenuItem
	ClipWait
	TrayTip A_Clipboard, "Copied!", "Mute"
}

RefreshWebinar() {
	ClickOnScreen(WebinarBrowserRefreshButton) ; Browser Refresh Button
	Sleep WaitForBrowserRefresh
	ClickOnScreen(WebinarPlayButton) ; Play Webinar Button
}

ClickOnScreen(coord, doClick := true) {
	CoordMode "Mouse", "Screen"
	DllCall("SetCursorPos", "int", coord[1], "int", coord[2])
	if(doClick) {
		Sleep 100
		Click
	}
}

ShowToolTip(Message) {
	ToolTip(Message)
	SetTimer(() => ToolTip(), -5000)
}