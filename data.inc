__UNICODE__ equ 1
include \masm32\include\masm32rt.inc

includelib setti\setti.lib
includelib lang\lang.lib
includelib ex_api\ex_api.lib
      
include \masm32\include\msdmo.inc
include \masm32\include\setupapi.inc
includelib \masm32\lib\msdmo.lib
includelib \masm32\lib\setupapi.lib

openCOM          proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
EditExpProc      proto :DWORD, :DWORD, :DWORD, :DWORD
Font_Dialog      proto :DWORD, :DWORD, :DWORD
save_log         proto :DWORD, :DWORD, :DWORD
get_folder       proto :DWORD, :DWORD
remov            proto :DWORD, :DWORD
utoa             proto :DWORD, :DWORD
GetTime          proto :DWORD
include          lib.inc

;macro
    xparam MACRO n_const, ident
        mov ebx, ident
        mov ecx, n_const
        shl ecx, 16
        or ecx, ebx
        EXITM <ecx>
    ENDM

;struct
    SP_DEVINFO_DATA STRUCT
        cbSize      dd ?
        ClassGuid   db 16 dup (?)
        DevInst     dd ?
        Reserved    dd ?
    SP_DEVINFO_DATA ENDS

.const
    STR_A                   equ 0
    STR_W                   equ -1
    STR_ITALIC              equ 010000h
    STR_UNDERLINE           equ 0100h
    STR_STRIKEOUT           equ 01h
    PM_QUIT                 equ WM_USER + 160

.data
    UC COMTerminal_Class,    "COMTerminal_Class", 0
    UC ClassNameS,           "COMTerminal_ClassS", 0
    UC ClassNameR,           "COMTerminal_ClassR", 0
    UC extension,            ".log", 0
    UC en,                   "00000409", 0
    UC static,               "static", 0
    UC edit,                 "edit", 0
    UC button,               "button", 0
    UC updown,               "msctls_updown32", 0
    UC combobox,             "combobox", 0
    UC VerdanaFont,          "Verdana", 0

    x_com           dd 0
    rb_len          dd 0
    wb_len          dd 0
    maximize_f      dd 0
    msg_f           dd 0
    fLng            dd 1
    x_pos           dd 830
    y_pos           dd 450
    f_BaudRate      dd 0
    f_ByteSize      dd 0
    f_StopBits      dd 0
    f_Parity        dd 0
    f_COM           dd 0
    f_charset       dd 1
    inv_f           dd 0
    
    s_Translation                   dd 0, 10000   ; �������
    s_RestartProgram                dd 0, 10010   ; ������������� ���������
    s_About                         dd 0, 10020   ; � ���������
    s_Save                          dd 0, 10030   ; ���������
    s_View                          dd 0, 10040   ; ���
    s_Font                          dd 0, 10045   ; �����
    s_Port                          dd 0, 10050   ; ����
    s_Clear                         dd 0, 10060   ; ��������
    s_Connect                       dd 0, 10070   ; ���������
    s_Disconnect                    dd 0, 10075   ; �����������
    s_PortsNotDetected              dd 0, 10080   ; ����� �� ����������
    s_DetectedPorts                 dd 0, 10090   ; ������������ �����
    s_Log                           dd 0, 10100   ; ���
    s_COMTerminal                   dd 0, 10110   ; COMTerminal
    s_PortIsAbsentOrBusy            dd 0, 10120   ; ���� ����������� ��� �����
    s_ReplaceFile                   dd 0, 10130   ; ���� � ��������� ������ ��� ����������. ��������?
    s_TextFile                      dd 0, 10140   ; ��������� ���� (txt)\0*.txt*\0
    s_StopExit                      dd 0, 10150   ; ���������� � ������ �� �������.\n������� � �����?
    s_COM_port                      dd 0, 10160   ; COM ����:
    s_Parity                        dd 0, 10170   ; ׸������:
    s_Data_bits                     dd 0, 10180   ; ���� ������:
    s_Stop_bits                     dd 0, 10190   ; �������� ����:
    s_Baud_rate                     dd 0, 10200   ; ��������:
    s_Commands                      dd 0, 10210   ; �������
    s_Charset                       dd 0, 10220   ; ���������

    id_edit_imp             dd 3050, 0, 0
    id_edit_exp             dd 3045, 0, 0
    
    id_static_com_port      dd 3200, 0, -1
    id_updown_com_port      dd 3195, 0, -1
    id_static_parity        dd 3194, 0, -1
    id_static_data_bits     dd 3193, 0, -1
    id_static_stop_bits     dd 3192, 0, -1
    id_static_baud_rate     dd 3191, 0, -1
    id_edit_com_port        dd 3190, 0, 0
    id_combobox_parity      dd 3189, 0, 0
    id_combobox_data_bits   dd 3188, 0, 0
    id_combobox_stop_bits   dd 3187, 0, 0
    id_combobox_baud_rate   dd 3186, 0, 0
    id_button_Connect       dd 3185, 0, 0

    sigword                 dw 0feffh
.data?
    hInstance       dd ?
    CommandLine     dd ?
    hWin            dd ?
    hParam          dd ?
    hEditExpProc    dd ?
    read_buff1      dd ?
    read_buff2      dd ?
    mega_buff       dd ?
    mega_buff2      dd ?
    hMenu           dd ?
    hMenu1          dd ?
    hMenu2          dd ?
    hMenu3          dd ?
    hMenu4          dd ?
    hWS             dd ?
    hWR             dd ?
    const_x         dd ?
    ini_f           dd ?
    hFile           dd ?

    TimeBuffer      TCHAR 256 dup (?)
    temp_str        TCHAR 2048 dup (?)
    use_dir         TCHAR 2048 dup (?)
    com_buf1        TCHAR 64 dup (?)
    com_buf2        TCHAR 64 dup (?)
    dev_nam         TCHAR 2048 dup (?)
    
    did             SP_DEVINFO_DATA <>
    wc              WNDCLASSEX <>
    msg             MSG <>
    iccex           INITCOMMONCONTROLSEX <>
    ofn             OPENFILENAME <>
    wfd             WIN32_FIND_DATA <>
    font_struct     LOGFONT <>
    font_struct2    LOGFONT <>
    mii             MENUITEMINFO <>
    lrgi            LARGE_INTEGER <>

