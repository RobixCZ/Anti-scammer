#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

chaosActive := false
shakyActive := false
saved := Map()
bsodGui := ""
avGui := ""
notepadList := []

; ================= RAlt sada =================

; --- RAlt + Z = chaos myš/klávesnice ---
RAlt & z:: {
    global chaosActive
    chaosActive := !chaosActive
    SetTimer(Chaos, chaosActive ? 50 : 0)
    Info(chaosActive ? "Chaos: ZAPNUTO" : "Chaos: VYPNUTO")
}

; --- RAlt + J = zavřít všechny aplikace ---
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
    Info("Zavřeno aplikací: " saved.Count)
}

; --- RAlt + O = znovu otevřít ---
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
    Info("Otevřeno aplikací: " n)
}

; --- RAlt + U = minimalizovat vše ---
RAlt & u:: {
    WinMinimizeAll()
    Info("Vše minimalizováno")
}

; --- RAlt + K = poplašný zvuk / hláška ---
RAlt & k:: {
    SoundBeep(1000, 300)
    SoundBeep(600, 300)
    SoundBeep(1000, 300)
    try {
        tts := ComObject("SAPI.SpVoice")
        tts.Speak("Warning. Unauthorized access detected.")
    }
    Info("Poplach spuštěn")
}

; --- RAlt + T = roztřesený kurzor ---
RAlt & t:: {
    global shakyActive
    shakyActive := !shakyActive
    SetTimer(ShakyMouse, shakyActive ? 30 : 0)
    Info(shakyActive ? "Třesoucí kurzor: ZAPNUTO" : "Třesoucí kurzor: VYPNUTO")
}

; ================= Ctrl+Alt sada =================

; --- Ctrl+Alt+P = fake antivirus scan zaseknutý na 99% ---
^!p:: {
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
    Info("Fake scan spuštěn")
}

; --- Ctrl+Alt+N = 15 prázdných Poznámkových bloků ---
^!n:: {
    global notepadList
    Loop 15 {
        Run("notepad.exe",, , &pid)
        notepadList.Push(pid)
    }
    Info("Otevřeno 15 Poznámkových bloků")
}

; --- Ctrl+Alt+B = fake modrá obrazovka (Esc zavře) ---
^!b:: {
    global bsodGui
    try bsodGui.Destroy()
    bsodGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    bsodGui.BackColor := "0078D7"
    bsodGui.SetFont("s24 cWhite", "Segoe UI")
    bsodGui.Add("Text", "w700 x100 y150", ":(")
    bsodGui.SetFont("s14 cWhite", "Segoe UI")
    bsodGui.Add("Text", "w700 x100 y220", "Your PC ran into a problem and needs to restart.`n`nWe're just collecting some error info, and then we'll restart for you.")
    bsodGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
    Info("")
}
#HotIf WinActive("ahk_id " . (bsodGui ? bsodGui.Hwnd : 0))
Escape:: {
    global bsodGui
    try bsodGui.Destroy()
}
#HotIf

; --- Ctrl+Alt+V = obrazovka vzhůru nohama ---
^!v:: {
    FlipScreen(180)
    Info("Obrazovka otočena")
}

; --- Ctrl+Alt+R = RESET všeho ---
^!r:: {
    global chaosActive, shakyActive, bsodGui, avGui, notepadList
    chaosActive := false
    shakyActive := false
    SetTimer(Chaos, 0)
    SetTimer(ShakyMouse, 0)
    try bsodGui.Destroy()
    try avGui.Destroy()
    for pid in notepadList {
        try ProcessClose(pid)
    }
    notepadList := []
    FlipScreen(0)
    Info("Vše resetováno do normálu")
}

; ================= Funkce =================

Chaos() {
    MouseMove(Random(0, A_ScreenWidth - 1), Random(0, A_ScreenHeight - 1), 0)
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
    ; angle: 0 = normálně, 180 = vzhůru nohama
    hdc := DllCall("CreateDC", "Str", "DISPLAY", "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr")
    w := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 118)
    h := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 117)
    DllCall("DeleteDC", "Ptr", hdc)

    VarSetStrCapacity(&dm, 220)
    NumPut("UShort", 220, dm, 36)      ; dmSize
    DllCall("EnumDisplaySettingsW", "Ptr", 0, "UInt", -1, "Ptr", StrPtr(dm))

    orient := (angle = 180) ? 2 : 0    ; 2 = DMDO_180, 0 = DMDO_DEFAULT
    NumPut("UInt", orient, dm, 44)     ; dmDisplayOrientation (union s dmPosition)

    if (orient = 2) {
        NumPut("UInt", h, dm, 108)     ; swap width/height pro 90/270, 180 nechává stejné
        NumPut("UInt", w, dm, 112)
    } else {
        NumPut("UInt", w, dm, 108)
        NumPut("UInt", h, dm, 112)
    }

    DllCall("ChangeDisplaySettingsW", "Ptr", StrPtr(dm), "UInt", 0)
}

Info(text) {
    if (text = "")
        return
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
}