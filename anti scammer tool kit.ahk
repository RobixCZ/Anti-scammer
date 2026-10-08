#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

chaosActive := false
shakyActive := false
mouseLocked := false
saved := Map()
bsodGui := ""
avGui := ""
notepadList := []

; ================= RAlt set =================

RAlt & z:: {
    global chaosActive
    chaosActive := !chaosActive
    SetTimer(Chaos, chaosActive ? 50 : 0)
}

RAlt & j:: {
    global saved
    saved := Map()
    skip := "explorer.exe,applicationframehost.exe,textinputhost.exe,systemsettings.exe,searchhost.exe,startmenuexperiencehost.exe,shellexperiencehost.exe"
    myPid := ProcessExist()
    for hwnd in WinGetList() {
        try {
            if !(WinGetStyle(hwnd) & 0x10000000)
                continue
            if (WinGetExStyle(hwnd) & 0x80)
                continue
            if (WinGetTitle(hwnd) = "")
                continue
            if (WinGetPID(hwnd) = myPid)
                continue
            name := StrLower(WinGetProcessName(hwnd))
            if InStr(skip, name)
                continue
            path := WinGetProcessPath(hwnd)
            if (path != "")
                saved[path] := true
            WinClose(hwnd)
        }
    }
}

RAlt & o:: {
    global saved
    for path in saved {
        try Run(path)
    }
    saved := Map()
}

RAlt & u:: {
    WinMinimizeAll()
}

RAlt & k:: {
    SoundBeep(1000, 300)
    SoundBeep(600, 300)
    SoundBeep(1000, 300)
    try {
        tts := ComObject("SAPI.SpVoice")
        tts.Speak("Warning. Unauthorized access detected.")
    }
}

RAlt & t:: {
    global shakyActive
    shakyActive := !shakyActive
    SetTimer(ShakyMouse, shakyActive ? 30 : 0)
}

; --- RAlt + L = fully lock/unlock the mouse (clicks, scroll, movement) ---
RAlt & l:: {
    global mouseLocked
    mouseLocked := !mouseLocked
    BlockInput(mouseLocked ? "Mouse" : "Default")
}

; ================= Ctrl+Alt set (forced LEFT Ctrl + LEFT Alt) =================

<^<!p:: {
    global avGui
    try avGui.Destroy()
    avGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Scan")
    avGui.BackColor := "000000"
    avGui.SetFont("s14 cLime", "Consolas")
    avGui.Add("Text", "w500 h30 Center", "SYSTEM SECURITY SCAN IN PROGRESS...")
    bar := avGui.Add("Progress", "w460 h30 x20 y60 cRed Background222222", 0)
    txt := avGui.Add("Text", "w460 x20 y100 Center", "Scanning files... 0%")
    avGui.Show("w500 h140 Center")

    pct := 0
    scanTimer := 0
    scanTimer := () => (
        pct := pct + Random(1, 6),
        pct > 99 ? pct := 99 : 0,
        bar.Value := pct,
        txt.Text := "Scanning files... " pct "%" (pct = 99 ? "  [THREATS FOUND: " Random(3,9) "]" : ""),
        pct >= 99 ? SetTimer(scanTimer, 0) : 0
    )
    SetTimer(scanTimer, 150)
}

<^<!n:: {
    global notepadList
    Loop 15 {
        Run("notepad.exe",, , &pid)
        notepadList.Push(pid)
    }
}

<^<!b:: {
    global bsodGui
    try bsodGui.Destroy()
    bsodGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    bsodGui.BackColor := "0078D7"
    bsodGui.SetFont("s24 cWhite", "Segoe UI")
    bsodGui.Add("Text", "w700 x100 y150", ":(")
    bsodGui.SetFont("s14 cWhite", "Segoe UI")
    bsodGui.Add("Text", "w700 x100 y220", "Your PC ran into a problem and needs to restart.`n`nWe're just collecting some error info, and then we'll restart for you.")
    bsodGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
}
#HotIf WinActive("ahk_id " . (bsodGui ? bsodGui.Hwnd : 0))
Escape:: {
    global bsodGui
    try bsodGui.Destroy()
}
#HotIf

<^<!v:: {
    FlipScreen(180)
}

<^<!r:: {
    global chaosActive, shakyActive, mouseLocked, bsodGui, avGui, notepadList
    chaosActive := false
    shakyActive := false
    SetTimer(Chaos, 0)
    SetTimer(ShakyMouse, 0)
    if (mouseLocked) {
        BlockInput("Default")
        mouseLocked := false
    }
    try bsodGui.Destroy()
    try avGui.Destroy()
    for pid in notepadList {
        try ProcessClose(pid)
    }
    notepadList := []
    FlipScreen(0)
}

; ================= Functions =================

Chaos() {
    vx := SysGet(76)
    vy := SysGet(77)
    vw := SysGet(78)
    vh := SysGet(79)

    MouseMove(vx + Random(0, vw - 1), vy + Random(0, vh - 1), 0)
    if Mod(Random(0, 9), 3) = 0
        Click
    if Mod(Random(0, 9), 5) = 0
        Send(Chr(Random(65, 90)))
}

ShakyMouse() {
    MouseGetPos(&cx, &cy)
    MouseMove(cx + Random(-15, 15), cy + Random(-15, 15), 0, "R")
}

FlipScreen(angle) {
    dm := Buffer(220, 0)
    NumPut("UShort", 220, dm, 36)

    DllCall("EnumDisplaySettingsW", "Ptr", 0, "UInt", -1, "Ptr", dm)

    orient := (angle = 180) ? 2 : 0
    w := NumGet(dm, 108, "UInt")
    h := NumGet(dm, 112, "UInt")
    NumPut("UInt", orient, dm, 44)

    if (orient = 2) {
        NumPut("UInt", h, dm, 108)
        NumPut("UInt", w, dm, 112)
    } else {
        NumPut("UInt", w, dm, 108)
        NumPut("UInt", h, dm, 112)
    }

    DllCall("ChangeDisplaySettingsW", "Ptr", dm, "UInt", 0)
}
