; Mouse Movement to Mouse Wheel 3.0
; http://ahkscript.org/
; Uses the AHKHID library by TheGood: http://www.autohotkey.com/board/topic/38015-ahkhid-an-ahk-implementation-of-the-hid-functions/
; This script converts normal mouse movement into mouse wheel movement.
; Specifically written for use with the Logitech Trackman Marble.
#SingleInstance Force
#include <AHKHID>

FileInstall mouse2wheel.ini, mouse2wheel.ini

; Configuration vars here
global XButton1ActsAsWheel ; If 1, XButton1 can be used for scrolling.
global XButton2ActsAsWheel ; If 1, XButton2 can be used for scrolling.
global XButton1ActsAsMMB ; If 1, XButton1 acts as an MMB if not used for scrolling. Otherwise, it acts as itself.
global XButton2ActsAsMMB ; If 1, XButton2 acts as an MMB if not used for scrolling. Otherwise, it acts as itself.
global HorizontalEnabled ; Set to 1 to enable horizontal scrolling.
global InvisibleCursor ; Set to 1 to hide the cursor during scroll.
global ActivateWindowOnScroll ; Set to 1 to activate windows under the cursor when scrolling.
global WheelSpeed ; Higher values mean lower wheel speed.

; Read them from ini:
IniRead XButton1ActsAsWheel, mouse2wheel.ini, General, XButton1 Enables Scroll, 1
IniRead XButton2ActsAsWheel, mouse2wheel.ini, General, XButton2 Enables Scroll, 1
IniRead XButton1ActsAsMMB, mouse2wheel.ini, General, XButton1 Acts As Middle Button, 1
IniRead XButton2ActsAsMMB, mouse2wheel.ini, General, XButton2 Acts As Middle Button, 0
IniRead HorizontalEnabled, mouse2wheel.ini, General, Allow Horizontal Scrolling, 0
IniRead InvisibleCursor, mouse2wheel.ini, General, Hide Cursor When Scrolling, 0
IniRead ActivateWindowOnScroll, mouse2wheel.ini, General, Activate Window Under Cursor When Scrolling, 1
IniRead WheelSpeed, mouse2wheel.ini, General, Wheel Speed, 10

; Initialize some stuff:
SetIcon()
SetWinDelay, 2
CoordMode, Mouse, Screen
if WheelSpeed < 1
    WheelSpeed := 1
global CursorHidden = 0
; We don't need a GUI really, but we need a handle for the HID stuff.
Gui +LastFound -Resize -MaximizeBox -MinimizeBox
hGui:=WinExist()
OnMessage(0x00FF, "MonitorMouse")

global Menunames := Object()
global Menulabels := Object()
global Menuvars := Object()

menu, tray, NoStandard
menu, tray, add, XButton1 enables scroll, ToggleXButton1Scroll
menu, tray, add, XButton2 enables scroll, ToggleXButton2Scroll
menu, tray, add, XButton1 acts as middle button, ToggleXButton1MMB
menu, tray, add, XButton2 acts as middle button, ToggleXButton2MMB
menu, tray, add, Allow horizontal scrolling, AllowHorizontal
menu, tray, add, Hide cursor when scrolling, CursorHide
menu, tray, add, Activate window under cursor when scrolling, ActivateOnScroll
menu, tray, add, Suspend hotkeys (Shift+ScrollLock), ScriptSuspend
menu, tray, add, Reload, ScriptReload
menu, tray, add, Exit, ScriptExit
MenuUpdate("XButton1 enables scroll", "XButton1ActsAsWheel")
MenuUpdate("XButton2 enables scroll", "XButton2ActsAsWheel")
MenuUpdate("XButton1 acts as middle button", "XButton1ActsAsMMB")
MenuUpdate("XButton2 acts as middle button", "XButton2ActsAsMMB")
MenuUpdate("Allow horizontal scrolling", "HorizontalEnabled")
MenuUpdate("Hide cursor when scrolling", "InvisibleCursor")
MenuUpdate("Activate window under cursor when scrolling", "ActivateWindowOnScroll")
return

; Menus
ToggleXButton1Scroll:
    MenuToggle("XButton1 enables scroll", "XButton1ActsAsWheel")
return
ToggleXButton2Scroll:
    MenuToggle("XButton2 enables scroll", "XButton2ActsAsWheel")
return
ToggleXButton1MMB:
    MenuToggle("XButton1 acts as middle button", "XButton1ActsAsMMB")
return
ToggleXButton2MMB:
    MenuToggle("XButton2 acts as middle button", "XButton2ActsAsMMB")
return
AllowHorizontal:
    MenuToggle("Allow horizontal scrolling", "HorizontalEnabled")
return
CursorHide:
    MenuToggle("Hide cursor when scrolling", "InvisibleCursor")
return
ActivateOnScroll:
    MenuToggle("Activate window under cursor when scrolling", "ActivateWindowOnScroll")
return
ScriptReload:
    Reload
return
ScriptExit:
    ; Write current settings to ini.
    IniWrite %XButton1ActsAsWheel%, mouse2wheel.ini, General, XButton1 Enables Scroll
    IniWrite %XButton2ActsAsWheel%, mouse2wheel.ini, General, XButton2 Enables Scroll
    IniWrite %XButton1ActsAsMMB%, mouse2wheel.ini, General, XButton1 Acts As Middle Button
    IniWrite %XButton2ActsAsMMB%, mouse2wheel.ini, General, XButton2 Acts As Middle Button
    IniWrite %HorizontalEnabled%, mouse2wheel.ini, General, Allow Horizontal Scrolling
    IniWrite %InvisibleCursor%, mouse2wheel.ini, General, Hide Cursor When Scrolling
    IniWrite %ActivateWindowOnScroll%, mouse2wheel.ini, General, Activate window under cursor when scrolling
    IniWrite %WheelSpeed%, mouse2wheel.ini, General, Wheel Speed
    ExitApp

; Toggles the variable associated with a menu.
MenuToggle(menuname, menuvar) {
    %menuvar% := 1 - %menuvar%
    MenuUpdate(menuname, menuvar)
}

; Sets menu status based on their underlying variables.
MenuUpdate(menuname, menuvar) {
    if (%menuvar%)
        menu, tray, Check, %menuname%
    else
        menu, tray, Uncheck, %menuname%
}

; Handles tray icon.
SetIcon() {
    if (A_IsCompiled)
        return
    if (A_IsSuspended)
        Menu, Tray, Icon, mmouse16_off.ico,, 1
    else
        Menu, Tray, Icon, mmouse16.ico,, 1
}

#If
+ScrollLock::
ScriptSuspend:
    Suspend
    MenuUpdate("Suspend hotkeys (Shift+ScrollLock)", "A_IsSuspended")
    SetIcon()
return

; Hotkeys for scroll mode.
XButton1::
    WaitKey = %A_ThisHotkey%
    Goto Body

XButton2::
    WaitKey = %A_ThisHotkey%
    Goto Body

; Main keyboard hotkeys. Both Win+Ctrl and Ctrl+Win are specified because the order in which you hit the keys matters.
#If
^LWin::
#Control::
    WaitKey = LWin ; We can't use %A_ThisHotkey% here, KeyWait doesn't like modifier symbols. Besides, we send Ctrl up below.

    ; Prevents scroll-zooming. Some programs will zoom on Ctrl+Wheel.
    ; Actually, I know why this trick works. Ctrl+Win will cause scroll-zooming, but Win+Ctrl will not.
    ; By sending a Ctrl up event, the Ctrl+Win hotkey will be interrupted but Win+Ctrl will immediately trigger
    ; as Ctrl is still being physically held down.
    Send {Control up}

Body:
    if %Waitkey%ActsasMMB
        SetButton = MButton
    else
        SetButton = %Waitkey%

    if (not %Waitkey%ActsAsWheel) {
        Send {%SetButton% down}
        KeyWait, % WaitKey
        Send {%SetButton% up}
    }
    else {
        ; Turn everything ON
        WheelUsed := 0

        ; Register the mice (page 1, use 2, keep reading even if out of focus)
        AHKHID_Register(1,2,hGui,RIDEV_INPUTSINK)
        BlockInput, MouseMove
        ; Disappear the cursor if needed.
        ; Wait for whatever key we used to initiate the scroll while the OnMessage function grabs mouse messages.
        KeyWait, % WaitKey
        BlockInput, MouseMoveOff
        AHKHID_Register(1,2,0,RIDEV_REMOVE)

        ; Restore the system cursor.
        if (CursorHidden) {
            SystemCursor("On")
            CursorHidden = 0
        }

        ; Let's preserve function of the XButtons if we only clicked them without scrolling.
        if not WheelUsed
            Send {%SetButton%}
    }
return

; OnMessage code.
MonitorMouse(wParam, lParam) {
    global
    static dx = 0, dy = 0
    Critical    ;Or otherwise you could get ERROR_INVALID_HANDLE
    
    ActivateWindowUnderCursor()

    ; Grab LastX and LastY values.
    dx += AHKHID_GetInputInfo(lParam, II_MSE_LASTX)
    dy += AHKHID_GetInputInfo(lParam, II_MSE_LASTY)

    if (not CursorHidden and InvisibleCursor) {
        SystemCursor("Off")
        CursorHidden = 1
    }

    ; Send the wheel events. Using while loops gives better results than passing the amount of notches to Click.
    ; Vertical scrolling.
    while dy >= WheelSpeed {
        Click X1, Y1, WheelDown, 1
        dy -= WheelSpeed
        WheelUsed := 1
    }
    while dy <= -WheelSpeed {
        Click X1, Y1, WheelUp, 1
        dy += WheelSpeed
        WheelUsed := 1
    }
    
    ; Horizontal scrolling.
    if (HorizontalEnabled) {
        while dx >= WheelSpeed {
            Click X1, Y1, WheelRight, 1
            dx -= WheelSpeed
            WheelUsed := 1
        }
        while dx <= -WheelSpeed {
            Click X1, Y1, WheelLeft, 1
            dx += WheelSpeed
            WheelUsed := 1
        }
    }
}

ActivateWindowUnderCursor() {
    if (not ActivateWindowOnScroll)
        return
    MouseGetPos,,,hovwin,hovcontrol
    WinGetClass, hovclass, ahk_id %hovwin%
    IfWinNotActive, ahk_id %hovwin%
        if (hovclass <> #32769) {
            WinActivate ahk_id %hovwin%
            ControlFocus %hovcontrol%, ahk_id %hovwin%
            if WaitKey = LWin
                ; Need to do this here in case we're refocusing a window.
                Send {Control up}
            return
        }
}

; The code below was taken from the hide cursor example: http://www.autohotkey.com/docs/commands/DllCall.htm#HideCursor
SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ = h                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
            b%A_Index% := DllCall("CreateCursor","uint",0, "int",0, "int",0
                , "int",32, "int",32, "uint",&AndMask, "uint",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ = b  ; use blank cursors
    else
        $ = h  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
        DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
    }
}
