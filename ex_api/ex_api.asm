; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_comterminal
; License:           GPL-3.0
;**********************************************************************************************************************************************************
__UNICODE__ equ 1
include \masm32\include\masm32rt.inc

crtwindow      proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
about_box      proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RetFontHEx     proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
corr           proto :DWORD, :DWORD, :DWORD
fltr           proto :DWORD, :DWORD, :DWORD
tab_focus      proto :DWORD, :DWORD
focus_frame    proto :DWORD, :DWORD
window_center  proto :DWORD
tab_proc       proto :DWORD

h MACRO ident
    mov edx, ident
    mov ecx, dword ptr[edx+4]
    EXITM <ecx>
ENDM

.data
    shift_f        dd 0
    b12            dd 8 ;12

.data?
    hInstance      dd ?

.code
;**********************************************************************************************************************************************************
crtwindow proc uses ebx WinName:DWORD, addrWinID:DWORD, WinHwnd:DWORD, WinClass:DWORD, WinX:DWORD, WinY:DWORD, WinW:DWORD, WinH:DWORD, WinS:DWORD, WinExS:DWORD, WinFontName:DWORD, WinFontSize:DWORD, WinFontWeight:DWORD, WinFontIUS:DWORD, hInst:DWORD
LOCAL local_hwnd:DWORD, WinID:DWORD, count:DWORD, loc_m:DWORD
LOCAL rec:RECT
    mov WinID, 0
    .if addrWinID!= 0
        invoke GetWindowLong, WinHwnd, 0
        cmp eax, 0
        jne @F
            invoke LocalAlloc, 040h, 1024
            invoke SetWindowLong, WinHwnd, 0, eax
            mrm hInstance, hInst
        @@:
        mov ebx, addrWinID
        mov eax, dword ptr[ebx]
        mov WinID, eax
    .endif
    invoke CreateWindowEx, WinExS, WinClass, WinName, WinS, WinX, WinY, WinW, WinH, WinHwnd, WinID, hInst, 0
    mov local_hwnd, eax
    .if WinID> 0
        mov ebx, addrWinID
        mov eax, local_hwnd
        mov dword ptr[ebx+4], eax
        mov eax, dword ptr[ebx+8]
        cmp eax, -1
        je @F
            mov loc_m, eax
            invoke GetWindowLong, WinHwnd, 4 ;счетчик
            mov count, eax
            invoke GetWindowLong, WinHwnd, 0
            mov edx, count
            shl edx, 3
            add eax, edx
            mov ecx, local_hwnd
            mov dword ptr[eax], ecx
            mov ecx, loc_m
            mov dword ptr[eax+4], ecx
            inc count
            invoke SetWindowLong, WinHwnd, 4, count
        @@:
        cmp WinFontName, 0
        je @F
            invoke RetFontHEx, WinFontName, WinFontSize, WinFontWeight, WinFontIUS, 0
            invoke SendMessage, local_hwnd, WM_SETFONT, eax, 1
        @@:
    .elseif WinID== 0
        ;invoke SetWindowLong, local_hwnd, 0, 0
        ;invoke SetWindowLong, local_hwnd, 4, 0      ;счетчик
        ;-----
        invoke GetClientRect, local_hwnd, addr rec
        mov ebx, WinW
        sub ebx, rec.right
        add WinW, ebx
        mov ebx, WinH
        sub ebx, rec.bottom
        add WinH, ebx
        invoke MoveWindow, local_hwnd, WinX, WinY, WinW, WinH, 1
    .endif
return local_hwnd
crtwindow endp
;**********************************************************************************************************************************************************
tab_focus proc x_msg:DWORD, hWnd:DWORD
LOCAL msg:MSG
    mov esi, x_msg
    lea edi, msg
    mov ecx, sizeof msg
    rep movsb
    .if msg.message== WM_KEYUP
        mov eax, msg.lParam
        shr eax, 31
        .if eax== 1 && msg.wParam== VK_SHIFT
            mov shift_f, 0
            return 1
        .endif
    .elseif msg.message== WM_KEYDOWN
        mov eax, msg.lParam
        shr eax, 30
        .if eax== 0 && msg.wParam== VK_SHIFT
            mov shift_f, 1
            return 1
        .elseif msg.wParam== VK_TAB
            invoke tab_proc, hWnd
            .if eax!= 0
                invoke focus_frame, eax, hWnd
                return 1
            .else
                invoke SetFocus, hWnd
            .endif
        .endif
    .endif
return 0
tab_focus endp
;**********************************************************************************************************************************************************
tab_proc proc hWnd:DWORD
LOCAL hFocus:DWORD, n_c:DWORD, h_buf:DWORD, loc1:DWORD
    invoke GetWindowLong, hWnd, 0  ;начальный адрес
    mov h_buf, eax
    invoke GetWindowLong, hWnd, 4  ;счетчик
    mov n_c, eax
    invoke GetFocus
    tab_m00:
    mov ebx, h_buf
    .if shift_f== 1
        finit
        fild n_c
        fimul b12
        fistp loc1
        fwait
        sub ebx, b12
        add ebx, loc1        
    .endif
    xor edx, edx
    cmp eax, 0
    jne tab_m
    tab_m0:
        cmp edx, n_c
        jae tab_end
            mov ecx, dword ptr[ebx]
            mov hFocus, ecx
            push edx
            invoke IsWindowEnabled, hFocus
            pop edx
            cmp eax, 0
            je @F
                invoke SetFocus, hFocus
                cmp eax, 0
                je tab_end
                return hFocus
            @@:
            .if shift_f== 1
                sub ebx, b12
            .else
                add ebx, b12
            .endif
            inc edx
            jmp tab_m0
;-----
    tab_m:
        cmp edx, n_c
        jae tab_endZ
        mov ecx, dword ptr[ebx]
        cmp ecx, eax
        jne tab_m11
            .if shift_f== 1
                sub ebx, b12
            .else
                add ebx, b12
            .endif
            inc edx
            tab_m1:
                cmp edx, n_c
                jae tab_endZ
                    mov ecx, dword ptr[ebx]
                    mov hFocus, ecx
                    push edx
                    invoke IsWindowEnabled, hFocus
                    pop edx
                    cmp eax, 0
                    je @F
                        invoke SetFocus, hFocus
                        cmp eax, 0
                        je tab_endZ
                        return hFocus
                    @@:
                    .if shift_f== 1
                        sub ebx, b12
                    .else
                        add ebx, b12
                    .endif
                    inc edx
                    jmp tab_m1
        tab_m11:
        .if shift_f== 1
            sub ebx, b12
        .else
            add ebx, b12
        .endif
        inc edx
        jmp tab_m
    tab_endZ:
    xor eax, eax
    jmp tab_m00
tab_end:
return 0
tab_proc endp
;**********************************************************************************************************************************************************
focus_proc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL loc_m:DWORD
.if uMsg== WM_TIMER
    invoke GetWindowLong, hWnd, 0
    mov loc_m, eax
    cmp loc_m, 10
    ja @F
        invoke PostMessage, hWnd, WM_CLOSE, 0, 0
    @@:
    invoke SetLayeredWindowAttributes, hWnd, 0, loc_m, LWA_ALPHA
    sub loc_m, 2
    invoke SetWindowLong, hWnd, 0, loc_m

.elseif uMsg== WM_CLOSE
    invoke DestroyWindow, hWnd

.else
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.endif
return 0
focus_proc endp
;**********************************************************************************************************************************************************
focus_frame proc focus_control:DWORD, hWnd:DWORD
LOCAL hhh:DWORD
LOCAL wc:WNDCLASSEX, rec:RECT
    mrm wc.hInstance, hInstance
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, 0
    mov wc.lpfnWndProc, offset focus_proc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 12
    mov wc.hIcon, 0
    mov wc.hIconSm, 0
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    invoke CreateSolidBrush, 0ff0000h
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, 0
    mrm wc.lpszClassName, uc$("focus_frame")
    invoke RegisterClassEx, addr wc
    
    invoke GetWindowRect, focus_control, addr rec
    mov eax, rec.right
    sub eax, rec.left
    mov rec.right, eax
    mov eax, rec.bottom
    sub eax, rec.top
    mov rec.bottom, eax
    invoke CreateWindowEx, WS_EX_LAYERED or WS_EX_TOPMOST or WS_EX_TOOLWINDOW, wc.lpszClassName, 0, WS_POPUP or WS_DISABLED, 0, 0, 0, 0, hWnd, 0, hInstance, 0
    mov hhh, eax
    invoke SetWindowLong, hhh, 0, 120
    invoke SetWindowPos, hhh, HWND_TOP, rec.left, rec.top, rec.right, rec.bottom, SWP_NOACTIVATE or SWP_SHOWWINDOW
    invoke SetTimer, hhh, 2000, 1, 0
return hhh
focus_frame endp
;**********************************************************************************************************************************************************
RetFontHEx proc uses ebx WinFontName:DWORD, WinFontSize:DWORD, WinFontWeight:DWORD, WinFontIUS:DWORD, lf:DWORD
LOCAL log_f:LOGFONT
    .if lf== 0
        lea ebx, log_f
    .else
        mov ebx, lf
    .endif
    neg WinFontSize
    mrm [ebx.LOGFONT.lfHeight], WinFontSize
    mov [ebx.LOGFONT.lfWidth], 0
    mov [ebx.LOGFONT.lfEscapement], 0
    mov [ebx.LOGFONT.lfOrientation], 0
    mrm [ebx.LOGFONT.lfWeight], WinFontWeight
    mov eax, WinFontIUS
    mov [ebx.LOGFONT.lfUnderline], ah
    mov [ebx.LOGFONT.lfStrikeOut], al
    ror eax, 16
    mov [ebx.LOGFONT.lfItalic], al
    mov [ebx.LOGFONT.lfCharSet], 1
    mov [ebx.LOGFONT.lfOutPrecision], 0
    mov [ebx.LOGFONT.lfClipPrecision], 0
    mov [ebx.LOGFONT.lfQuality], 0
    mov [ebx.LOGFONT.lfPitchAndFamily], 0
    lea eax, [ebx.LOGFONT.lfFaceName]
    invoke lstrcpy, eax, WinFontName
    invoke CreateFontIndirect, ebx
ret
RetFontHEx endp
;**********************************************************************************************************************************************************
window_center proc uses ebx hwind:DWORD
LOCAL poi:POINT, rec:RECT
    invoke GetWindowRect, hwind, addr rec
    invoke GetSystemMetrics, SM_CXSCREEN
    mov poi.x, eax
    shr poi.x, 01h      ;---  \2
    mov eax, rec.left
    sub rec.right, eax
    mov eax, rec.right
    shr eax, 01h        ;---  \2
    sub poi.x ,eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov poi.y, eax
    shr poi.y, 01h      ;---  \2
    mov eax, rec.top
    sub rec.bottom, eax
    mov eax, rec.bottom
    shr eax, 01h        ;---  \2
    sub poi.y ,eax
    invoke MoveWindow, hwind, poi.x, poi.y, rec.right, rec.bottom, 1
ret
window_center endp
;**********************************************************************************************************************************************************
about_box proc uses ebx h_instance:DWORD, hParent:DWORD, msgtxt:DWORD, caption:DWORD, mbstyle:DWORD, iconID:DWORD
LOCAL mbp:MSGBOXPARAMS
    or mbstyle, MB_USERICON
    mov mbp.cbSize, sizeof mbp
    mrm mbp.hwndOwner, hParent
    mrm mbp.hInstance, h_instance
    mrm mbp.lpszText, msgtxt
    mrm mbp.lpszCaption, caption
    mrm mbp.dwStyle, mbstyle
    mrm mbp.lpszIcon, iconID
    mov mbp.dwContextHelpId, 0
    mov mbp.lpfnMsgBoxCallback, 0
    mov mbp.dwLanguageId, 0
    invoke MessageBoxIndirect, addr mbp
ret
about_box endp
;**********************************************************************************************************************************************************
corr proc uses ebx id_ed:DWORD, min_str:DWORD, max_str:DWORD
LOCAL min_n:DWORD, max_n:DWORD, numb:DWORD
LOCAL loc_buf[128]:TCHAR
    invoke GetWindowText, h(id_ed), addr loc_buf, 128
    invoke fltr, h(id_ed), addr loc_buf, min_str
    .if eax== 1
        ret
    .endif
    mov min_n, uval(min_str)
    mov max_n, uval(max_str)
    mov ebx, uval(addr loc_buf)
    mov numb, ebx
    .if ebx> max_n
        invoke SetWindowText, h(id_ed), max_str
    .elseif ebx< min_n
        invoke SetWindowText, h(id_ed), min_str
    .endif
    invoke SetWindowText, h(id_ed), ustr$(numb)
    mov eax, numb
ret
corr endp
;**********************************************************************************************************************************************************
fltr proc uses ebx hend:DWORD, loc_buf:DWORD, min_str:DWORD
    mov eax, loc_buf
    xor ecx, ecx
    dcik:
    mov bx, word ptr [eax]
    cmp bx, 0
    je endf
    add eax, 2
    inc ecx
    cmp bx, 030h
    jb sign
    cmp bx, 039h
    ja sign
    jmp dcik
    sign:
    invoke SetWindowText, hend, min_str
    invoke SendMessage, hend, EM_SETSEL, 0, -1
    mov eax, 1
ret
    endf:
    cmp ecx, 0
    je sign
    xor eax, eax
ret
fltr endp
;**********************************************************************************************************************************************************
end

