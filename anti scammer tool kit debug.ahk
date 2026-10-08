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
    Info(chaosActive ? "Chaos: ON" : "Chaos: OFF")
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
    Info("Apps closed: " saved.Count)
}

RAlt & o:: {
    global saved
    n := 0
    for path in saved {
        try {
            Run(path)
            n++
        }
    }
    saved := Map()
    Info("Apps reopened: " n)
}

RAlt & u:: {
    WinMinimizeAll()
    Info("All windows minimized")
}

RAlt & k:: {
    SoundBeep(1000, 300)
    SoundBeep(600, 300)
    SoundBeep(1000, 300)
    try {
        tts := ComObject("SAPI.SpVoice")
        tts.Speak("Warning. Unauthorized access detected.")
    }
    Info("Alarm triggered")
}

RAlt & t:: {
    global shakyActive
    shakyActive := !shakyActive
    SetTimer(ShakyMouse, shakyActive ? 30 : 0)
    Info(shakyActive ? "Shaky cursor: ON" : "Shaky cursor: OFF")
}

; --- RAlt + L = fully lock/unlock the mouse (clicks, scroll, movement) ---
RAlt & l:: {
    global mouseLocked
    mouseLocked := !mouseLocked
    BlockInput(mouseLocked ? "Mouse" : "Default")
    Info(mouseLocked ? "Mouse: LOCKED" : "Mouse: UNLOCKED")
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
    Info("Fake scan started")
}

<^<!n:: {
    global notepadList
    Loop 15 {
        Run("notepad.exe",, , &pid)
        notepadList.Push(pid)
    }
    Info("Opened 15 Notepad windows")
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
    Info("Fake BSOD started")
}
#HotIf WinActive("ahk_id " . (bsodGui ? bsodGui.Hwnd : 0))
Escape:: {
    global bsodGui
    try bsodGui.Destroy()
}
#HotIf

<^<!v:: {
    FlipScreen(180)
    Info("Screen flipped")
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
    Info("Everything reset to normal")
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

Info(text) {
    if (text = "")
        return
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
}
