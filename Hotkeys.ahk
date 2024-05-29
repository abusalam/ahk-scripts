#Requires AutoHotkey v2.0

#Include ".env.example"
#Include "*i .env"

global OutputVarWin := WinExist("A")

; Names for the tray menu items:
k_MenuItemWebinar := "CheckWebinar (Ctrl+Shift+H)"
k_MenuItemCopyCoords := "CopyMouseCoords (Ctrl+Shift+C)"
k_MenuItemToggleOnTop := "ToggleOnTop (Ctrl+Shift+T)"
s_MenuItemOpen := "&Open"

; Create the popup menu by adding some items to it.
SystemMenu := Menu()
SystemMenu.AddStandard()

MenuHandler(Item, *) {
    MsgBox("You selected " Item)
}

^+z::ShowCoords()
^+x::TestingAHK ;Ctrl + Shift + x
^+w::CheckWebinar ;Ctrl + Shift + h
^+c::CopyMouseCoords ;Ctrl + Shift + c
^+t::ToggleOnTop ;Ctrl+Shift+T

TestingAHK() {
	ClickOnScreen(WebinarPlayButton)
	TrayTip TestVarFromEnv?, "AoT Window", "Mute"
}

ToggleOnTop(*){
	; CoordMode "Mouse", "Screen"
	; MouseGetPos &OutputVarX, &OutputVarY, &OutputVarWin
	Try {
		WinSetAlwaysOnTop(-1, OutputVarWin)
		TrayTip OutputVarWin, WinGetTitle(OutputVarWin), "Mute"
	} Catch as e {
		TrayTip e.Message, "AoT Window", "Mute"
	}
}

ShowCoords(){
	CoordMode "Mouse", "Screen"
	MouseGetPos &xpos, &ypos, &OutputVarWin
	Coords := xpos ", " ypos
	c_Menu := Menu()
	c_Menu.Add(Coords, CopyMenuName)
	c_Menu.Add(WinGetTitle(OutputVarWin), CopyMenuName)
	c_Menu.Add()
	c_Menu.Add(k_MenuItemToggleOnTop, ToggleOnTop)
	c_Menu.Add(k_MenuItemWebinar, CheckWebinar)
	c_Menu.Add(k_MenuItemCopyCoords, CopyMouseCoords)
	c_Menu.Add()  ; Add a separator line.
	c_Menu.Add(A_ComputerName, SystemMenu)
	c_Menu.Add()  ; Add a separator line below the submenu.
	c_Menu.Add(FormatTime(A_Now,"MMM dd HH:mm:ss tt"), MenuHandler)
	Try {
		CopyText := A_Clipboard ? SubStr(A_Clipboard, 1, 50) : "Empty Clipboard"
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
	TrayTip A_Clipboard, "Copied!", "Mute"
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
		SetTimer CheckWebinar, CheckInterval
		TimerStarted := true
	}
	if(A_TimeIdle > IdleWaitTime) {
		TrayTip RemainingTime " minutes remaining to start", "NIC Webinar", "Mute"
		RefreshWebinar
	}
	ToolTip "Checking again in " CheckInterval " ms."
	SetTimer () => ToolTip(), -5000
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

ClickOnScreen(coord) {
	CoordMode "Mouse", "Screen"
	DllCall("SetCursorPos", "int", coord[1], "int", coord[2])
	Sleep 100
	Click
}