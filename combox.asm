;**********************************************************************************************************************************************************
port_proc proc
LOCAL msg1:MSG
    mov wc.lpfnWndProc, offset WndProcP
    invoke LoadCursor, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov wc.lpszClassName, offset ClassNameS
    mov wc.style, CS_HREDRAW or CS_VREDRAW; or CS_NOCLOSE
    invoke RegisterClassEx, addr wc
    invoke crtwindow, s_Port, 0, hWin, addr ClassNameS, 0, 0, 260, 200, WS_SYSMENU, WS_EX_CONTEXTHELP, 0, 0, 0, 0, hInstance
    mov hWS, eax
    invoke window_center, hWS
    invoke ShowWindow, hWS, SW_SHOWNORMAL
    invoke SetForegroundWindow, hWS
    invoke EnableWindow, hWin, 0
    @@:
        invoke GetMessage, addr msg1, 0, 0, 0
        or eax, eax
        je @F
        cmp msg1.message, PM_QUIT
        je @F
        invoke tab_focus, addr msg1, hWS
        cmp eax, 1
        je @B
        invoke TranslateMessage, addr msg1
        invoke DispatchMessage, addr msg1
        jmp @B
    @@:
    invoke EnableWindow, hWin, 1
    invoke SetForegroundWindow, hWin
    invoke SetFocus, h(offset id_edit_exp)
    invoke DestroyWindow, hWS
    mov hWS, 0
return msg1.wParam
port_proc endp
;**********************************************************************************************************************************************************
openCOM proc com_str:DWORD, pBaudRate:DWORD, pByteSize:DWORD, pParity:DWORD, pStopBits:DWORD
LOCAL hPar:DWORD
LOCAL com:DCB, cto:COMMTIMEOUTS
    invoke CreateFile, com_str, GENERIC_READ or GENERIC_WRITE, 0, 0, OPEN_EXISTING, 0, 0
    .if eax== INVALID_HANDLE_VALUE
        invoke MessageBox, hWS, s_PortIsAbsentOrBusy, s_COMTerminal, MB_OK or MB_ICONINFORMATION
        return 0
    .endif
    mov hPar, eax
    invoke GetCommState, hPar, addr com
    mrm com.BaudRate, pBaudRate
    mov eax, pByteSize
    mov com.ByteSize, al
    mov eax, pParity
    mov com.Parity, al
    mov eax, pStopBits
    mov com.StopBits, al
    mov cto.WriteTotalTimeoutConstant, 1000
    mov cto.ReadIntervalTimeout, MAXDWORD
    mov cto.ReadTotalTimeoutMultiplier, 0
    mov cto.WriteTotalTimeoutMultiplier, 0
    mov cto.ReadTotalTimeoutConstant, 0
    invoke SetCommTimeouts, hPar, addr cto
    invoke SetCommState, hPar, addr com
return hPar
openCOM endp
;**********************************************************************************************************************************************************
WndProcP proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL index:DWORD, index2:DWORD, dat_reg:DWORD, siz_d:DWORD
LOCAL gyid[32]:BYTE
.IF uMsg== WM_COMMAND
    mov eax, wParam
    ror eax, 16
    .IF ax== CBN_SELENDOK || ax== BN_CLICKED || ax== EN_CHANGE
        shr eax, 16
        .IF eax== id_button_Connect
            .if x_com== 0
                invoke lstrcpy, addr com_buf2, ustr$(f_COM)
                invoke lstrcpy, addr com_buf1, uc$("\\.\COM")
                invoke lstrcat, addr com_buf1, addr com_buf2
                invoke SendMessage, h(offset id_combobox_parity), CB_GETITEMDATA, f_Parity, 0
                mov ebx, eax
                invoke SendMessage, h(offset id_combobox_baud_rate), CB_GETITEMDATA, f_BaudRate, 0
                mov esi, eax
                invoke SendMessage, h(offset id_combobox_data_bits), CB_GETITEMDATA, f_ByteSize, 0
                mov edi, eax
                invoke SendMessage, h(offset id_combobox_stop_bits), CB_GETITEMDATA, f_StopBits, 0
                invoke openCOM, offset com_buf1, esi, edi, ebx, eax
                .if eax!= 0
                    mov x_com, eax
                   ;invoke SendMessage, h(offset id_edit_exp), EM_SETREADONLY, 0, 0
                    invoke SetFocus, h(offset id_edit_exp)
                    invoke CreateSolidBrush, 0077ff77h
                    mov ebx, eax
                    invoke SetClassLong, hWin, GCL_HBRBACKGROUND, ebx
                    invoke InvalidateRect, hWin, 0, 1
                    invoke SetClassLong, hWR, GCL_HBRBACKGROUND, ebx
                    invoke InvalidateRect, hWR, 0, 1
                    invoke SetTimer, hWin, 2302, 200, 0
                    invoke PostMessage, hWnd, PM_QUIT, 0, 0
                .elseif eax== 0
                    invoke SetFocus, h(offset id_edit_com_port)
                    invoke SendMessage, h(offset id_edit_com_port), EM_SETSEL, 0, -1
                .endif
            .else
                invoke CloseHandle, x_com
                mov x_com, 0
               ;invoke SendMessage, h(offset id_edit_exp), EM_SETREADONLY, 1, 0
                invoke EnableWindow, h(offset id_edit_com_port), 1
                invoke EnableWindow, h(offset id_updown_com_port), 1
                invoke EnableWindow, h(offset id_combobox_parity), 1
                invoke EnableWindow, h(offset id_combobox_baud_rate), 1
                invoke EnableWindow, h(offset id_combobox_data_bits), 1
                invoke EnableWindow, h(offset id_combobox_stop_bits), 1
                invoke SetFocus, h(offset id_edit_com_port)
                invoke SendMessage, h(offset id_edit_com_port), EM_SETSEL, 0, -1
                invoke SetWindowText, h(offset id_button_Connect), s_Connect
                invoke SetClassLong, hWin, GCL_HBRBACKGROUND, COLOR_BTNFACE+1
                invoke InvalidateRect, hWin, 0, 1
                invoke SetClassLong, hWR, GCL_HBRBACKGROUND, COLOR_BTNFACE+1
                invoke InvalidateRect, hWR, 0, 1
                invoke KillTimer, hWin, 2302
            .endif
        .ELSEIF eax== id_edit_com_port
            invoke corr, offset id_edit_com_port, uc$("0"), uc$("255")
           ;invoke SendMessage, h(offset id_updown_com_port), UDM_GETPOS32, 0, 0
            mov f_COM, eax
        .ELSEIF eax== id_combobox_parity
            invoke SendMessage, h(offset id_combobox_parity), CB_GETCURSEL, 0, 0
            mov f_Parity, eax
        .ELSEIF eax== id_combobox_baud_rate
            invoke SendMessage, h(offset id_combobox_baud_rate), CB_GETCURSEL, 0, 0
            mov f_BaudRate, eax
        .ELSEIF eax== id_combobox_data_bits
            invoke SendMessage, h(offset id_combobox_data_bits), CB_GETCURSEL, 0, 0
            mov f_ByteSize, eax
        .ELSEIF eax== id_combobox_stop_bits
            invoke SendMessage, h(offset id_combobox_stop_bits), CB_GETCURSEL, 0, 0
            mov f_StopBits, eax
        .ENDIF
    .ENDIF

.ELSEIF uMsg== WM_HELP
    .if msg_f!= 0
        return 0
    .endif
    invoke DMOStrToGuid, uc$("4d36e978-e325-11ce-bfc1-08002be10318"), addr gyid
    invoke SetupDiGetClassDevs, addr gyid, 0, 0, DIGCF_PRESENT
    .if eax== INVALID_HANDLE_VALUE
        return 0
    .endif
    mov index, eax
    mov index2, 0
    invoke lstrcpy, read_buff2, s_DetectedPorts
    cl_dev_m:
    mov did.cbSize, sizeof did
    invoke SetupDiEnumDeviceInfo, index, index2, addr did
    .if eax== 0
        mov msg_f, 1
        .if index2== 0
            invoke MessageBox, hWS, s_PortsNotDetected, s_COMTerminal, MB_OK or MB_ICONINFORMATION
            jmp help_m
        .endif
        invoke MessageBox, hWS, read_buff2, s_COMTerminal, MB_OK or MB_ICONINFORMATION
        help_m:
        mov msg_f, 0
        return 0
    .endif
    invoke SetupDiGetDeviceRegistryProperty, index, addr did, SPDRP_FRIENDLYNAME, addr dat_reg, addr dev_nam, 2000, addr siz_d
    invoke lstrcat, read_buff2, addr dev_nam
    invoke lstrcat, read_buff2, ucc$("\n")
    inc index2
    jmp cl_dev_m

.ELSEIF uMsg== WM_CREATE
    mrm index, f_COM
    invoke crtwindow, s_COM_port, offset id_static_com_port, hWnd, offset static, 0, 5, 150, 25, 050000201h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, uc$("0"), offset id_edit_com_port, hWnd, offset edit, 155, 5, 106, 25, 050002001h, 000000200h, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, 0, offset id_updown_com_port, hWnd, offset updown, 0, 0, 20, 20, 050000037h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    mov ebx, eax
    invoke SendMessage, ebx, UDM_SETBUDDY, h(offset id_edit_com_port), 0
    invoke SendMessage, ebx, UDM_SETBASE, 10, 0
    invoke SendMessage, ebx, UDM_SETRANGE32, 0, 255
    mrm f_COM, index
    invoke SendMessage, ebx, UDM_SETPOS32, 0, f_COM
    invoke SendMessage, h(offset id_edit_com_port), EM_SETLIMITTEXT, 3, 0
    invoke crtwindow, s_Parity, offset id_static_parity, hWnd, offset static, 0, 35, 150, 25, 050000201h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, 0, offset id_combobox_parity, hWnd, offset combobox, 155, 35, 90, 110, 050200003h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    mov ebx, eax
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("none")
    invoke SendMessage, ebx, CB_SETITEMDATA, 0, NOPARITY
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("odd")
    invoke SendMessage, ebx, CB_SETITEMDATA, 1, ODDPARITY
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("even")
    invoke SendMessage, ebx, CB_SETITEMDATA, 2, EVENPARITY
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("mark")
    invoke SendMessage, ebx, CB_SETITEMDATA, 3, MARKPARITY
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("space")
    invoke SendMessage, ebx, CB_SETITEMDATA, 4, SPACEPARITY
    invoke SendMessage, ebx, CB_SETCURSEL, f_Parity, 0
    invoke crtwindow, s_Data_bits, offset id_static_data_bits, hWnd, offset static, 0, 65, 150, 25, 050000201h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, 0, offset id_combobox_data_bits, hWnd, offset combobox, 155, 65, 90, 100, 050200003h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    mov ebx, eax
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("5")
    invoke SendMessage, ebx, CB_SETITEMDATA, 0, 5
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("6")
    invoke SendMessage, ebx, CB_SETITEMDATA, 1, 6
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("7")
    invoke SendMessage, ebx, CB_SETITEMDATA, 2, 7
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("8")
    invoke SendMessage, ebx, CB_SETITEMDATA, 3, 8
    invoke SendMessage, ebx, CB_SETCURSEL, f_ByteSize, 0
    invoke crtwindow, s_Stop_bits, offset id_static_stop_bits, hWnd, offset static, 0, 95, 150, 25, 050000201h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, 0, offset id_combobox_stop_bits, hWnd, offset combobox, 155, 95, 90, 100, 050200003h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    mov ebx, eax
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("1")
    invoke SendMessage, ebx, CB_SETITEMDATA, 0, ONESTOPBIT
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("1.5")
    invoke SendMessage, ebx, CB_SETITEMDATA, 1, ONE5STOPBITS
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("2")
    invoke SendMessage, ebx, CB_SETITEMDATA, 2, TWOSTOPBITS
    invoke SendMessage, ebx, CB_SETCURSEL, f_StopBits, 0
    invoke crtwindow, s_Baud_rate, offset id_static_baud_rate, hWnd, offset static, 0, 125, 150, 25, 050000201h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    invoke crtwindow, 0, offset id_combobox_baud_rate, hWnd, offset combobox, 155, 125, 90, 100, 050200003h, 0, offset VerdanaFont, 15, 400, 0, hInstance
    mov ebx, eax
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("110")
    invoke SendMessage, ebx, CB_SETITEMDATA, 0, CBR_110
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("300")
    invoke SendMessage, ebx, CB_SETITEMDATA, 1, CBR_300
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("600")
    invoke SendMessage, ebx, CB_SETITEMDATA, 2, CBR_600
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("1200")
    invoke SendMessage, ebx, CB_SETITEMDATA, 3, CBR_1200
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("2400")
    invoke SendMessage, ebx, CB_SETITEMDATA, 4, CBR_2400
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("4800")
    invoke SendMessage, ebx, CB_SETITEMDATA, 5, CBR_4800
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("9600")
    invoke SendMessage, ebx, CB_SETITEMDATA, 6, CBR_9600
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("14400")
    invoke SendMessage, ebx, CB_SETITEMDATA, 7, CBR_14400
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("19200")
    invoke SendMessage, ebx, CB_SETITEMDATA, 8, CBR_19200
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("38400")
    invoke SendMessage, ebx, CB_SETITEMDATA, 9, CBR_38400
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("56000")
    invoke SendMessage, ebx, CB_SETITEMDATA, 10, CBR_56000
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("57600")
    invoke SendMessage, ebx, CB_SETITEMDATA, 11, CBR_57600
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("115200")
    invoke SendMessage, ebx, CB_SETITEMDATA, 12, CBR_115200
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("128000")
    invoke SendMessage, ebx, CB_SETITEMDATA, 13, CBR_128000
    invoke SendMessage, ebx, CB_ADDSTRING, 0, uc$("256000")
    invoke SendMessage, ebx, CB_SETITEMDATA, 14, CBR_256000
    invoke SendMessage, ebx, CB_SETCURSEL, f_BaudRate, 0
    invoke crtwindow, s_Connect, offset id_button_Connect, hWnd, offset button, 5, 165, 140, 30, WS_CHILD or WS_VISIBLE, 0, offset VerdanaFont, 15, 400, 0, hInstance

    .if x_com!= 0
        invoke EnableWindow, h(offset id_edit_com_port), 0
        invoke EnableWindow, h(offset id_updown_com_port), 0
        invoke EnableWindow, h(offset id_combobox_parity), 0
        invoke EnableWindow, h(offset id_combobox_baud_rate), 0
        invoke EnableWindow, h(offset id_combobox_data_bits), 0
        invoke EnableWindow, h(offset id_combobox_stop_bits), 0
        invoke SetWindowText, h(offset id_button_Connect), s_Disconnect
        invoke SetFocus, h(offset id_button_Connect)
    .endif
.ELSEIF uMsg== WM_CLOSE
    invoke PostMessage, hWnd, PM_QUIT, 0, 0
.ELSE
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
.ENDIF
return 0
WndProcP endp
;**********************************************************************************************************************************************************

