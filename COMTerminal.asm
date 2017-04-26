; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_comterminal
; License:           GPL-3.0
;**********************************************************************************************************************************************************
include data.inc
.code
start:
;**********************************************************************************************************************************************************
    invoke GetModuleHandle, 0
    mov hInstance, eax
    invoke ini_ini, uc$("COMTerminal.ini"), 1024
    mov ini_f, eax
    cmp ini_f, 1
    jne @F
        invoke get_data, 0, addr fLng
        invoke get_data, 0, addr x_pos
        invoke get_data, 0, addr y_pos
    @@:
    invoke read_lng, uc$("COMTerminal.lng"), 262144
    invoke get_str, addr s_Translation, 24, fLng, hInstance

    invoke GetCommandLine
    mov CommandLine, eax

    mov iccex.dwSize, sizeof INITCOMMONCONTROLSEX
    mov iccex.dwICC, ICC_WIN95_CLASSES
    invoke InitCommonControlsEx, addr iccex

    invoke LocalAlloc, 040h, 131072
    mov read_buff1, eax
    invoke LocalAlloc, 040h, 131072
    mov read_buff2, eax
    invoke LocalAlloc, 040h, 131072
    mov mega_buff, eax
    invoke LocalAlloc, 040h, 131072
    mov mega_buff2, eax
    invoke RetFontHEx, offset VerdanaFont, 11, 700, 0, offset font_struct

    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, 0;CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset COMTerminalProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 20
    mrm wc.hInstance, hInstance
    invoke LoadIcon, hInstance, 900
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov wc.hbrBackground, COLOR_BTNFACE+1
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset COMTerminal_Class
    invoke RegisterClassEx, addr wc
    invoke crtwindow, s_COMTerminal, 0, 0, addr COMTerminal_Class, 0, 0, x_pos, y_pos, WS_OVERLAPPEDWINDOW, 0, 0, 0, 0, 0, hInstance
    mov hWin, eax
    cmp ini_f, 1
    jne @F
        call read_setting
    @@:
    invoke window_center, hWin
    .if maximize_f== 0
        invoke ShowWindow, hWin, SW_SHOWNORMAL
    .elseif maximize_f== 1
        invoke ShowWindow, hWin, SW_SHOWMAXIMIZED
    .endif

    start_msg:
        invoke GetMessage, addr msg, 0, 0, 0
        or eax, eax
        je end_msg
        invoke tab_focus, addr msg, hWin
        cmp eax, 1
        je start_msg
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
        jmp start_msg
    end_msg:
    invoke ExitProcess, msg.wParam
;**********************************************************************************************************************************************************
COMTerminalProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL car1:DWORD, car2:DWORD, loc_m:DWORD, scr_pos:DWORD
LOCAL poi:POINT, rec:RECT
.IF uMsg== WM_COMMAND
    mov eax, wParam
    ror eax, 16
    .IF ax== BN_CLICKED
        shr eax, 16
        .IF eax== 2401 ;сохранить лог
            invoke save_log, hWnd, s_Save, s_TextFile
            invoke SetFocus, h(offset id_edit_exp)
        .ELSEIF eax== 2402 ;очистить поле
            invoke SendMessage, h(offset id_edit_imp), WM_SETTEXT, 0, uc$(0)
            invoke SetFocus, h(offset id_edit_exp)
        .ELSEIF eax== 2400 ;порт
            call port_proc
        .ELSEIF eax== 2403 ;О программе
            call about
            invoke SetFocus, h(offset id_edit_exp)
        .ELSEIF eax== 2404 ;Шрифт
            lea esi, font_struct
            lea edi, font_struct2
            mov ecx, sizeof LOGFONT
            rep movsb
            invoke Font_Dialog, hWnd, offset font_struct, CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT or CF_FORCEFONTEXIST
            .if eax== IDOK
                invoke CreateFontIndirect, offset font_struct
                mov ebx, eax
                invoke SendMessage, h(offset id_edit_exp), WM_SETFONT, ebx, 1
                invoke SendMessage, h(offset id_edit_imp), WM_SETFONT, ebx, 1
            .else
                lea esi, font_struct2
                lea edi, font_struct
                mov ecx, sizeof LOGFONT
                rep movsb
            .endif
            invoke SetFocus, h(offset id_edit_exp)
        .ELSEIF eax== 2407 ;поменять поля
            .if inv_f== 0
                mov inv_f, 1
                mov esi, h(offset id_edit_imp)
            .else
                mov inv_f, 0
                mov esi, h(offset id_edit_exp)
            .endif
            invoke GetWindowRect, esi, addr rec
            mov eax, rec.right
            sub eax, rec.left
            add eax, 5
            invoke MoveWindow, hWR, eax, 0, 5, 3000, 1
            invoke GetClientRect, hWnd, addr rec
            mov eax, rec.right
            mov ebx, rec.bottom
            ror ebx, 16
            mov bx, ax
            invoke SendMessage, hWnd, WM_SIZE, 9, ebx
            invoke InvalidateRect, hWnd, 0, 1
        .ELSEIF eax== 2405 ;unicode
            invoke CheckMenuItem, hMenu4, 2405, MF_BYCOMMAND or MF_CHECKED
            invoke CheckMenuItem, hMenu4, 2406, MF_BYCOMMAND or MF_UNCHECKED
            mov f_charset, 0
        .ELSEIF eax== 2406 ;ascii
            invoke CheckMenuItem, hMenu4, 2406, MF_BYCOMMAND or MF_CHECKED
            invoke CheckMenuItem, hMenu4, 2405, MF_BYCOMMAND or MF_UNCHECKED
            mov f_charset, 1
        .ELSEIF eax>= 5001 && eax< 5100   ;Смена языка
            sub eax, 5000
            mov fLng, eax
            invoke get_str, addr s_RestartProgram, 0, fLng, 0
            invoke MessageBox, hWnd, s_RestartProgram, s_COMTerminal, MB_OK
        .ELSEIF eax>= 2500 && eax< 2900   ;Выбор команд
            mov ebx, eax
            mov mii.cbSize, sizeof MENUITEMINFO
            mov mii.fType, MFT_STRING
            mov mii.fMask, MIIM_TYPE
            mov mii.dwTypeData, 0
            invoke GetMenuItemInfo, hMenu3, ebx, 0, offset mii
            inc mii.cch
            mov mii.dwTypeData, offset temp_str
            invoke GetMenuItemInfo, hMenu3, ebx, 0, offset mii
            invoke lstrcpy, offset use_dir, uc$("commands\")
            invoke lstrcat, offset use_dir, offset temp_str
            invoke get_folder, offset temp_str, offset use_dir
            invoke CreateFile, offset temp_str, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
            .if eax== INVALID_HANDLE_VALUE
            .else
                mov ebx, eax
                invoke GetFileSizeEx, ebx, offset lrgi
                .if lrgi.LowPart> 0 && lrgi.HighPart== 0
                    invoke ReadFile, ebx, offset use_dir, lrgi.LowPart, addr loc_m, 0
                    lea ecx, use_dir
                    add ecx, loc_m
                    mov word ptr[ecx], 0
                    invoke SendMessage, h(offset id_edit_exp), WM_SETTEXT, 0, offset use_dir[2]
                .endif
                invoke CloseHandle, ebx
            .endif
            invoke SetFocus, h(offset id_edit_exp)
        .ENDIF
    .ENDIF

.ELSEIF uMsg== WM_CREATE
    invoke CreateMenu
    mov hMenu, eax
    invoke CreateLngMenu, hMenu, fLng
    invoke CreatePopupMenu
    mov hMenu1, eax
    invoke CreatePopupMenu
    mov hMenu2, eax
    invoke CreatePopupMenu
    mov hMenu4, eax
    mov esi, 2500
    @@:
    call find_txt
    .if eax!= 0
        mov ebx, eax
        .if esi== 2500
            invoke CreatePopupMenu
            mov hMenu3, eax
            invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu3, s_Commands
            invoke AppendMenu, hMenu3, MF_STRING, esi, ebx
            inc esi
            jmp @B
        .endif
        invoke AppendMenu, hMenu3, MF_STRING, esi, ebx
        inc esi
        jmp @B
    .endif
    invoke AppendMenu, hMenu, MF_STRING, 2400, s_Port
    invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu4, s_Charset
    invoke AppendMenu, hMenu4, MF_STRING, 2405, uc$("UNICODE")
    invoke AppendMenu, hMenu4, MF_STRING, 2406, uc$("ASCII")
    invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu1, s_Log
    invoke AppendMenu, hMenu1, MF_STRING, 2402, s_Clear
    invoke AppendMenu, hMenu1, MF_SEPARATOR, 0, 0
    invoke AppendMenu, hMenu1, MF_STRING, 2401, s_Save
    invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu2, s_View
    invoke AppendMenu, hMenu2, MF_STRING, 2404, s_Font
    invoke AppendMenu, hMenu2, MF_STRING, 2407, uc$(021cch) ; 021c4h, 021c6h
    invoke AppendMenu, hMenu, MF_STRING, 2403, s_About
    invoke SetMenu, hWnd, hMenu
    invoke CheckMenuItem, hMenu4, 2406, MF_BYCOMMAND or MF_CHECKED

    invoke crtwindow, 0, offset id_edit_imp, hWnd, offset edit, 420, 5, 410, 470, 0503008C4h, 000000200h, offset VerdanaFont, 11, 700, 0, hInstance
    invoke SendMessage, h(offset id_edit_imp), EM_SETHANDLE, mega_buff, 0
    invoke SendMessage, h(offset id_edit_imp), EM_SETLIMITTEXT, 65536, 0
    invoke crtwindow, 0, offset id_edit_exp, hWnd, offset edit, 5, 5, 410, 470, 0503000C4h, 000000200h or WS_EX_LEFTSCROLLBAR, offset VerdanaFont, 11, 700, 0, hInstance
    invoke SendMessage, h(offset id_edit_exp), EM_SETHANDLE, mega_buff2, 0
    invoke SendMessage, h(offset id_edit_exp), EM_SETLIMITTEXT, 65536, 0
    invoke SetWindowLong, h(offset id_edit_exp), GWL_WNDPROC, addr EditExpProc
    mov hEditExpProc, eax
    
    invoke LoadKeyboardLayout, addr en, KLF_ACTIVATE
    
    mov wc.lpfnWndProc, offset WndProcR
    mov wc.lpszClassName, offset ClassNameR
    mov wc.style, CS_NOCLOSE or CS_HREDRAW or CS_VREDRAW
    invoke LoadCursor, 0, IDC_SIZEWE
    mov wc.hCursor, eax
    invoke RegisterClassEx, addr wc
    invoke CreateWindowEx, 0, addr ClassNameR, 0, WS_CHILD or WS_VISIBLE, 415, 0, 5, 3000, hWnd, 0, hInstance, 0
    mov hWR, eax

.ELSEIF uMsg== WM_TIMER
    mov eax, wParam
    .if ax== 2302 && x_com!= 0
        invoke ReadFile, x_com, read_buff2, 65536, addr rb_len, 0
        .if rb_len> 0 && eax!= 0
            invoke SendMessage, h(offset id_edit_imp), EM_GETSEL, addr car1, addr car2
            invoke GetScrollPos, h(offset id_edit_imp), SB_VERT
            mov scr_pos, eax
            mov eax, read_buff2
            add eax, rb_len
            mov word ptr[eax], 0
            .if f_charset== 0
                invoke lstrcpy, read_buff1, read_buff2
            .else
                invoke MultiByteToWideChar, CP_ACP, 0, read_buff2, -1, read_buff1, MAX_PATH
            .endif
            invoke SendMessage, h(offset id_edit_imp), WM_GETTEXT, 65536, read_buff2
            invoke lstrlen, read_buff1
            add car1, eax
            add car2, eax
            invoke lstrcat, read_buff1, read_buff2
            invoke SendMessage, h(offset id_edit_imp), WM_SETTEXT, 0, read_buff1
            invoke SendMessage, h(offset id_edit_imp), EM_LINESCROLL, 0, scr_pos
            mov eax, car2
            .if car1!= eax
                invoke SendMessage, h(offset id_edit_imp), EM_SETSEL, car1, car2
                invoke SendMessage, h(offset id_edit_imp), EM_SCROLLCARET, 0, 0
            .endif
        .endif
    .endif
    
.ELSEIF uMsg== WM_SIZE
    .if wParam== SIZE_MAXIMIZED
        mov maximize_f, 1
    .elseif wParam== SIZE_RESTORED
        mov maximize_f, 0
    .endif
    .if inv_f== 0
        mov esi, h(offset id_edit_exp)
        mov edi, h(offset id_edit_imp)
    .else
        mov edi, h(offset id_edit_exp)
        mov esi, h(offset id_edit_imp)
    .endif
    mov eax, lParam
    movzx ebx, ax
    mov poi.x, ebx
    ror eax, 16
    movzx ebx, ax
    mov poi.y, ebx
    invoke GetWindowRect, esi, addr rec
    mov eax, rec.right
    sub eax, rec.left
    mov rec.right, eax
    mov ebx, poi.y
    sub ebx, 10
    invoke MoveWindow, esi, 5, 5, rec.right, ebx, 1

    add rec.right, 10
    mov eax, rec.right
    sub poi.x, eax
    sub poi.x, 5
    mov ebx, poi.y
    sub ebx, 10
    invoke MoveWindow, edi, rec.right, 5, poi.x, ebx, 1

.ELSEIF uMsg== WM_ENDSESSION
    .if x_com!= 0
        invoke MessageBox, hWnd, s_StopExit, s_COMTerminal, MB_OKCANCEL or MB_ICONEXCLAMATION
        .if eax== IDOK
            invoke CloseHandle, x_com
        .elseif eax== IDCANCEL
            return 0
        .endif
    .endif
    call writ_setting
    invoke ShowWindow, hWnd, SW_HIDE
    invoke free_lng
    invoke LocalFree, read_buff1
    invoke LocalFree, read_buff2
    invoke LocalFree, mega_buff
    invoke LocalFree, mega_buff2
    invoke PostQuitMessage, 0
    
.ELSEIF uMsg== WM_CLOSE
    invoke PostMessage, hWnd, WM_ENDSESSION, 0, 0
.ELSEIF uMsg== WM_QUERYENDSESSION
    return 1
.ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
COMTerminalProc endp
;**********************************************************************************************************************************************************
save_log proc hParent:DWORD, lpTitle:DWORD, lpFilter:DWORD
LOCAL hend:DWORD, wrlen:DWORD, loc_buf:DWORD, l_str:DWORD
m_canc:
    invoke GetTime, offset TimeBuffer
    invoke lstrcpy, offset temp_str, s_COMTerminal
    invoke lstrcat, offset temp_str, uc$("_")
    invoke lstrcat, offset temp_str, offset TimeBuffer
    invoke get_folder, offset use_dir, offset temp_str
    mov ofn.lStructSize, sizeof OPENFILENAME
    mrm ofn.hWndOwner, hParent
    mrm ofn.hInstance, hInstance
    mrm ofn.lpstrFilter, lpFilter
    mov ofn.lpstrFile, offset use_dir
    mov ofn.nMaxFile, sizeof use_dir
    mrm ofn.lpstrTitle, lpTitle
    mov ofn.Flags, OFN_EXPLORER or OFN_LONGNAMES
    invoke GetSaveFileName, offset ofn
    .if eax!= 0
        invoke lstrcat, offset use_dir, offset extension
        invoke CreateFile, addr use_dir, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
        .if eax!= INVALID_HANDLE_VALUE
            invoke CloseHandle, eax
            invoke MessageBox, hParent, s_ReplaceFile, s_COMTerminal, MB_YESNO or MB_ICONEXCLAMATION
            .if eax== IDYES
                jmp start_save
            .else
                jmp m_canc
            .endif
        .endif
        start_save:
        invoke LocalAlloc, 040h, 131072
        mov loc_buf, eax
        invoke SendMessage, h(offset id_edit_imp), WM_GETTEXT, 65536, loc_buf
        invoke lstrlen, loc_buf
        shl eax, 1 ;*2
        mov l_str, eax
        invoke CreateFile, offset use_dir, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
        mov hend, eax
        invoke WriteFile, hend, offset sigword, 2, addr wrlen, 0
        invoke WriteFile, hend, loc_buf, l_str, addr wrlen, 0
        invoke CloseHandle, hend
        invoke LocalFree, loc_buf
    .endif
ret
save_log endp
;**********************************************************************************************************************************************************
EditExpProc proc hEdit:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg== WM_CHAR
        mov eax, wParam
        .if al== VK_TAB
            return 0
        .elseif al== VK_RETURN
            call write_com
            return 0
        .endif
    .elseif uMsg== WM_KEYUP
        mov eax, wParam
        .if al== VK_UP || al== VK_DOWN
            call ed_eng
            return 0
        .endif
    .elseif uMsg== WM_LBUTTONUP
        call ed_eng
    .elseif uMsg== WM_LBUTTONDBLCLK
        call write_com
        return 0
    .endif
    invoke CallWindowProc, hEditExpProc, hEdit, uMsg, wParam, lParam
    ret
EditExpProc endp
;**********************************************************************************************************************************************************
write_com proc
LOCAL car1:DWORD, car2:DWORD, a_str:DWORD, scr_pos:DWORD, l_str:DWORD
    invoke GetScrollPos, h(offset id_edit_exp), SB_VERT
    mov scr_pos, eax
    invoke SendMessage, h(offset id_edit_exp), EM_GETSEL, addr car1, addr car2
    invoke SendMessage, h(offset id_edit_exp), WM_GETTEXT, 65536, read_buff2
    mov ecx, car1
    .if ecx== car2
        jmp ddf
    .endif
    mov ebx, read_buff2
    mov esi, car1
    shl esi, 1 ;*2
    add ebx, esi
    mov word ptr[ebx], 0
    mov ebx, read_buff2
    mov esi, car2
    shl esi, 1 ;*2
    add ebx, esi
    mov ax, word ptr[ebx]
    .if ax!= 0
        add ebx, 4
        mov ax, word ptr[ebx]
        .if ax!= 0
            invoke lstrcat, read_buff2, ebx
        .endif
    .endif
    invoke SendMessage, h(offset id_edit_exp), WM_SETTEXT, 0, read_buff2
ddf:
    mov ebx, read_buff2
    mov a_str, ebx
wr_m1:
    mov ax, word ptr[ebx]
    .if ax== 000dh || ax== 0000h
        mov word ptr[ebx], 0
        jmp wr_m2
    .endif
    add ebx, 2
    jmp wr_m1
wr_m2:
    invoke lstrlen, a_str
    cmp eax, 0
    je @F
    mov ebx, eax
    .if f_charset== 0
        shl ebx, 1 ;*2
        add ebx, 4
        mov l_str, ebx
        invoke lstrcat, a_str, SADD(13,0,10,0,0,0)
        mov edi, a_str
    .else
        add ebx, 2
        mov l_str, ebx
        invoke utoa, a_str, read_buff1
        invoke lstrcatA, read_buff1, SADD(13,10)
        mov edi, read_buff1
    .endif
    invoke WriteFile, x_com, edi, l_str, addr wb_len, 0
    invoke lstrcpy, read_buff1, SADD(13,0,10,0,0,0)
    invoke SendMessage, h(offset id_edit_exp), WM_GETTEXT, 65536, read_buff2
    invoke lstrcat, read_buff1, read_buff2
    invoke SendMessage, h(offset id_edit_exp), WM_SETTEXT, 0, read_buff1
    invoke SendMessage, h(offset id_edit_exp), EM_LINESCROLL, 0, scr_pos
@@:
ret
write_com endp
;**********************************************************************************************************************************************************
ed_eng proc
LOCAL car1:DWORD, car2:DWORD, scr_pos:DWORD, a_str:DWORD, len1str:DWORD
        invoke SendMessage, h(offset id_edit_exp), EM_LINEINDEX, -1, 0
        mov car1, eax
        .if car1== 0
            ret
        .endif
        mov car2, eax
        invoke GetScrollPos, h(offset id_edit_exp), SB_VERT
        mov scr_pos, eax
        invoke SendMessage, h(offset id_edit_exp), WM_GETTEXT, 65536, read_buff2
        mov eax, read_buff2
        mov esi, eax
        mov len1str, 0
    len1_m:
        mov cx, word ptr[esi]
        .if cx== 000dh
            mov ecx, car1
            sub ecx, len1str
            mov len1str, ecx
            jmp len2_m
        .endif
        inc len1str
        add esi, 2
        jmp len1_m
    len2_m:
        mov esi, car1
        shl esi, 1 ;*2
        add eax, esi
        mov a_str, eax
    sel_str_m1:
        mov bx, word ptr[eax]
        .if bx== 000dh || bx== 0000h
            mov word ptr[eax], 0
            jmp sel_str_m2
        .endif
        inc car2
        add eax, 2
        jmp sel_str_m1
    sel_str_m2:
        invoke SendMessage, h(offset id_edit_exp), EM_SETSEL, car1, car2

        invoke SendMessage, h(offset id_edit_exp), WM_GETTEXT, 65536, read_buff1
        mov eax, read_buff1
    sel_str_m3:
        mov bx, word ptr[eax]
        .if bx== 000dh
            jmp sel_str_m4
        .endif
        add eax, 2
        jmp sel_str_m3
    sel_str_m4:
        invoke lstrcat, a_str, eax
        invoke SendMessage, h(offset id_edit_exp), WM_SETTEXT, 0, a_str

        mov eax, car2
        sub eax, car1
        add len1str, eax
        mov ebx, len1str
        add ebx, eax
        invoke SendMessage, h(offset id_edit_exp), EM_SETSEL, len1str, ebx
        invoke SendMessage, h(offset id_edit_exp), EM_LINESCROLL, 0, scr_pos
ret
ed_eng endp
;**********************************************************************************************************************************************************
get_folder proc loc_buf:DWORD, stri:DWORD
    invoke GetModuleFileName, 0, loc_buf, 1024
    mov eax, loc_buf
    gfol_m:
    mov bx, word ptr[eax]
    .if bx== 005ch  ;\
        mov ecx, eax
        add ecx, 2
    .elseif bx== 0
        jmp gfol_m2
    .endif
    add eax, 2
    jmp gfol_m
    gfol_m2:
    mov word ptr[ecx], 0
    invoke lstrcat, loc_buf, stri
ret
get_folder endp
;**********************************************************************************************************************************************************
WndProcR proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL rec:RECT, rec2:RECT, rec3:RECT, poi:POINT
.IF uMsg== WM_LBUTTONDOWN
    invoke SetCapture, hWR
    invoke GetClientRect, hWin, addr rec
    invoke ClientToScreen, hWin, addr rec
    lea eax, rec
    add eax, 8
    invoke ClientToScreen, hWin, eax
    invoke ClipCursor, addr rec
    mov eax, lParam
    movzx ebx, ax
    mov const_x, ebx
    invoke SetTimer, hWR, 2303, 25, 0
.ELSEIF uMsg== WM_LBUTTONUP
    mov rec.left, 0
    mov rec.top, 0
    invoke GetSystemMetrics, SM_CXSCREEN
    mov rec.right, eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov rec.bottom, eax
    invoke ClipCursor, addr rec
    invoke KillTimer, hWR, 2303
    invoke ReleaseCapture
.ELSEIF uMsg== WM_TIMER
    mov eax, wParam
    .if ax== 2303
        .if inv_f== 0
            mov esi, h(offset id_edit_exp)
            mov edi, h(offset id_edit_imp)
        .else
            mov edi, h(offset id_edit_exp)
            mov esi, h(offset id_edit_imp)
        .endif
        invoke GetCursorPos, addr poi
        invoke ScreenToClient, hWin, addr poi
        mov eax, const_x
        sub poi.x, eax
        invoke GetWindowRect, hWR, addr rec
        mov eax, rec.right
        sub eax, rec.left
        mov rec.right, eax
        mov eax, rec.bottom
        sub eax, rec.top
        mov rec.bottom, eax
        invoke MoveWindow, hWR, poi.x, 0, rec.right, rec.bottom, 1
        sub poi.x, 5
        invoke GetWindowRect, esi, addr rec2
        mov eax, rec2.bottom
        sub eax, rec2.top
        mov rec2.bottom, eax
        invoke MoveWindow, esi, 5, 5, poi.x, rec2.bottom, 1
        add poi.x, 10
        invoke GetClientRect, hWin, addr rec3
        mov eax, rec3.right
        sub eax, poi.x
        sub eax, 5
        invoke MoveWindow, edi, poi.x, 5, eax, rec2.bottom, 1
    .endif
.ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
WndProcR endp
;**********************************************************************************************************************************************************
writ_setting proc
LOCAL loc_m:DWORD
LOCAL rec:RECT
    invoke set_data, 0, addr fLng, 4
    invoke GetClientRect, hWin, addr rec
    invoke set_data, 0, addr rec.right, 4
    invoke set_data, 0, addr rec.bottom, 4
    invoke set_data, 0, addr inv_f, 4
    .if inv_f== 0
        mov esi, h(offset id_edit_exp)
    .else
        mov esi, h(offset id_edit_imp)
    .endif
    invoke GetWindowRect, esi, addr rec
    mov eax, rec.right
    sub eax, rec.left
    mov rec.right, eax
    invoke set_data, 0, addr rec.right, 4
    invoke set_data, 0, addr maximize_f, 4
    invoke set_data, 0, addr font_struct, sizeof LOGFONT
    invoke set_data, 0, addr f_Parity, 4
    invoke set_data, 0, addr f_BaudRate, 4
    invoke set_data, 0, addr f_ByteSize, 4
    invoke set_data, 0, addr f_StopBits, 4
    invoke set_data, 0, addr f_COM, 4
    invoke set_data, 0, addr f_charset, 4
    invoke write_ini
ret
writ_setting endp
;**********************************************************************************************************************************************************
read_setting proc
LOCAL loc_m:DWORD
    invoke get_data, 0, addr inv_f
    invoke get_data, 0, addr loc_m
    .if inv_f== 0
        mov esi, h(offset id_edit_exp)
        mov edi, h(offset id_edit_imp)
    .else
        mov edi, h(offset id_edit_exp)
        mov esi, h(offset id_edit_imp)
    .endif
    mov ebx, y_pos
    sub ebx, 10
    invoke MoveWindow, esi, 5, 5, loc_m, ebx, 1
    mov eax, loc_m
    add eax, 5
    invoke MoveWindow, hWR, eax, 0, 5, 3000, 1
    mov eax, loc_m
    add eax, 10
    mov ebx, y_pos
    sub ebx, 10
    mov ecx, x_pos
    sub ecx, eax
    sub ecx, 5
    invoke MoveWindow, edi, eax, 5, ecx, ebx, 1
    invoke get_data, 0, addr maximize_f
    invoke get_data, 0, addr font_struct
    invoke CreateFontIndirect, addr font_struct
    mov ebx, eax
    invoke SendMessage, h(offset id_edit_exp), WM_SETFONT, ebx, 1
    invoke SendMessage, h(offset id_edit_imp), WM_SETFONT, ebx, 1
    invoke get_data, 0, addr f_Parity
    invoke get_data, 0, addr f_BaudRate
    invoke get_data, 0, addr f_ByteSize
    invoke get_data, 0, addr f_StopBits
    invoke get_data, 0, addr f_COM
    invoke get_data, 0, addr f_charset
    .if f_charset== 0
        invoke CheckMenuItem, hMenu4, 2405, MF_BYCOMMAND or MF_CHECKED
        invoke CheckMenuItem, hMenu4, 2406, MF_BYCOMMAND or MF_UNCHECKED
    .else
        invoke CheckMenuItem, hMenu4, 2405, MF_BYCOMMAND or MF_UNCHECKED
        invoke CheckMenuItem, hMenu4, 2406, MF_BYCOMMAND or MF_CHECKED
    .endif
ret
read_setting endp
;**********************************************************************************************************************************************************
about proc
    invoke lstrcpy, addr temp_str, ucc$("COMTerminal v2.2 © 2017 7ya\nContact: 7ya@protonmail.com\nhttps://github.com/7ya/win_asm_comterminal\n\n")
    invoke lstrcat, addr temp_str, s_Translation
    invoke about_box, hInstance, hWin, addr temp_str, s_COMTerminal, MB_OK, 900
ret
about endp
;**********************************************************************************************************************************************************
Font_Dialog proc hWnd:DWORD, lf:DWORD, fStyle:DWORD
LOCAL hDC:DWORD, cf:CHOOSEFONT
    invoke GetDC, hWnd
    push eax
    mov hDC, eax
    mov cf.lStructSize, sizeof CHOOSEFONT
    push hWnd
    pop cf.hWndOwner
    pop eax
    mov cf.hDC, eax
    push lf
    pop cf.lpLogFont
    mov cf.iPointSize, 0
    push fStyle
    pop cf.Flags
    mov cf.rgbColors, 0
    mov cf.lCustData, 0
    mov cf.lpfnHook, 0
    mov cf.lpTemplateName, 0
    mov cf.hInstance, 0
    mov cf.lpszStyle, 0
    mov cf.nFontType, 0
    mov cf.Alignment, 0
    mov cf.nSizeMin, 0
    mov cf.nSizeMax, 0
    invoke ChooseFont, addr cf
    push eax
    invoke ReleaseDC, hWnd, hDC
    pop eax
ret
Font_Dialog endp
;**********************************************************************************************************************************************************
find_txt proc
.if hFile== 0
    invoke get_folder, offset temp_str, uc$("commands")
    invoke FindFirstFile, offset temp_str, addr wfd
    .if eax== INVALID_HANDLE_VALUE
        invoke CreateDirectory, offset temp_str, 0
        return 0
    .else
        invoke FindClose, eax
        invoke lstrcat, offset temp_str, uc$("\*.txt")
        invoke FindFirstFile, offset temp_str, offset wfd
        .if eax== INVALID_HANDLE_VALUE
            return 0
        .else
            mov hFile, eax
            return offset wfd.cFileName
        .endif
    .endif
.else
    invoke FindNextFile, hFile, addr wfd
    .if eax== 0
        invoke FindClose, hFile
        return 0
    .else
        return offset wfd.cFileName
    .endif
.endif
return 0
find_txt endp
;**********************************************************************************************************************************************************
utoa proc uses ebx unicode_str:DWORD, ascii_str:DWORD
    mov ebx, unicode_str
    mov ecx, ascii_str
@@:
    mov ax, word ptr[ebx]
    cmp ax, 0
    je @F
    mov byte ptr[ecx], al
    inc ecx
    add ebx, 2
    jmp @B
@@:
    mov byte ptr[ecx], 0
return ascii_str
utoa endp
;**********************************************************************************************************************************************************
GetTime proc time_buf:DWORD
LOCAL stmt:SYSTEMTIME
    invoke GetLocalTime, addr stmt
    movzx ebx, stmt.wDay
    invoke lstrcpy, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("-")
    movzx ebx, stmt.wMonth
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("-")
    movzx ebx, stmt.wYear
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("_")
    movzx ebx, stmt.wHour
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("h-")
    movzx ebx, stmt.wMinute
    invoke lstrcat, time_buf, ustr$(ebx)
    invoke lstrcat, time_buf, uc$("m")
return time_buf
GetTime endp
;**********************************************************************************************************************************************************
include combox.asm
;**********************************************************************************************************************************************************
end start

