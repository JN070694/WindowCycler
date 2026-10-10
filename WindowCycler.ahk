#Requires AutoHotkey v2.0
#SingleInstance Force
SetWinDelay(-1)

; ============================================================
; CONFIG — edit these to match your actual windows.
; Use the "Window Spy" tool (comes with AutoHotkey) to find the
; exact title or exe name: right-click the AHK tray icon > Window Spy,
; then click into each window to see its "ahk_exe" / title.
; ============================================================
localFullScreen  := "ahk_exe vlc.exe"       ; Local
remoteFullScreen := "ahk_exe chrome.exe"    ; Remote
paneATitle       := "ahk_exe msedge.exe"
paneBTitle       := "ahk_exe firefox.exe"
discordTitle     := "ahk_exe Discord.exe"
elementTitle     := "ahk_exe Element.exe"

; ============================================================
; Startup prompt: Select environment (2x2 grid).
; Rows = Local / Remote. Columns = Discord (blue) / Element (green).
; Standard Windows buttons, each inside a thick colored frame.
; ============================================================
ready := false
choiceEnv := ""
choiceApp := ""

blue  := "0078D7"
green := "0DBD8B"

g := Gui("+AlwaysOnTop", "WindowCycler: Startup")
g.SetFont("s10")
g.Add("Text", "x20 y20 w300 Center", "Select environment:")

g.Add("Text", "x20 y58 w145 h34 Background" blue)
g.Add("Button", "x23 y61 w139 h28", "Local Discord").OnEvent("Click", Pick.Bind("Local", "Discord"))
g.Add("Text", "x175 y58 w145 h34 Background" green)
g.Add("Button", "x178 y61 w139 h28", "Local Element").OnEvent("Click", Pick.Bind("Local", "Element"))

g.Add("Text", "x20 y102 w145 h34 Background" blue)
g.Add("Button", "x23 y105 w139 h28", "Remote Discord").OnEvent("Click", Pick.Bind("Remote", "Discord"))
g.Add("Text", "x175 y102 w145 h34 Background" green)
g.Add("Button", "x178 y105 w139 h28", "Remote Element").OnEvent("Click", Pick.Bind("Remote", "Element"))

g.OnEvent("Close", (*) => ExitApp())
g.OnEvent("Escape", (*) => ExitApp())
g.Show("w340 h156")
WinWaitClose("ahk_id " g.Hwnd)

Pick(env, app, *) {
    global choiceEnv, choiceApp
    choiceEnv := env
    choiceApp := app
    g.Destroy()
}

fullScreenTitle := (choiceEnv = "Local") ? localFullScreen : remoteFullScreen
thirdTitle := (choiceApp = "Discord") ? discordTitle : elementTitle
A_IconTip := "WindowCycler (" choiceEnv ", " choiceApp ")"
ready := true

; ============================================================
; Toggle: ScrollLock cycles through 3 states in order:
;   1) VLC (Local) or Chrome (Remote), maximized
;   2) Edge (left half) + Firefox (right half), side by side
;   3) Discord or Element, maximized
; ...then back to 1.
; ============================================================
cycleState := 1

ScrollLock:: {
    global cycleState

    if (!ready)
        return

    if (cycleState = 1) {
        MaximizeWindow(fullScreenTitle)
        cycleState := 2
    } else if (cycleState = 2) {
        SnapWindow(paneATitle, "left")
        SnapWindow(paneBTitle, "right")
        cycleState := 3
    } else {
        MaximizeWindow(thirdTitle)
        cycleState := 1
    }
}

; ============================================================
; Snip & Sketch (Win+Shift+S) bound to PrintScreen key.
; Change "PrintScreen" below to any key you'd rather use.
; ============================================================
PrintScreen:: {
    Send("#+s")
}

; ============================================================
; Snap a window to the left or right half of the primary monitor's
; work area (above the taskbar). Only restores the window if it is
; minimized or maximized. Compensates for the invisible resize borders
; on Windows 10/11 so the two halves meet cleanly.
; ============================================================
SnapWindow(winTitle, side) {
    hwnd := FindWindow(winTitle)
    if !hwnd
        return
    target := "ahk_id " hwnd

    if (WinGetMinMax(target) != 0)
        WinRestore(target)

    MonitorGetWorkArea(MonitorGetPrimary(), &L, &T, &R, &B)
    half := (R - L) // 2
    x := (side = "left") ? L : L + half
    w := (side = "left") ? half : R - x
    h := B - T

    outer := Buffer(16)
    inner := Buffer(16)
    bl := br := bt := bb := 0
    DllCall("GetWindowRect", "ptr", hwnd, "ptr", outer)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 9, "ptr", inner, "uint", 16) = 0) {
        bl := NumGet(inner, 0, "int") - NumGet(outer, 0, "int")
        bt := NumGet(inner, 4, "int") - NumGet(outer, 4, "int")
        br := NumGet(outer, 8, "int") - NumGet(inner, 8, "int")
        bb := NumGet(outer, 12, "int") - NumGet(inner, 12, "int")
    }

    WinMove(x - bl, T - bt, w + bl + br, h + bt + bb, target)
    WinActivate(target)
}

; ============================================================
; Bring a window forward and maximize it (restores it first if minimized).
; ============================================================
MaximizeWindow(winTitle) {
    hwnd := FindWindow(winTitle)
    if !hwnd
        return
    target := "ahk_id " hwnd
    WinActivate(target)
    if (WinGetMinMax(target) != 1)
        WinMaximize(target)
}

; ============================================================
; Find a window, or show a short tooltip if it isn't open.
; ============================================================
FindWindow(winTitle) {
    hwnd := WinExist(winTitle)
    if !hwnd {
        ToolTip(winTitle " not found")
        SetTimer(ToolTip, -2500)
    }
    return hwnd
}
