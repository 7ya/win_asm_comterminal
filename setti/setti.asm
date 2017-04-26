; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_comterminal
; License:           GPL-3.0
;**********************************************************************************************************************************************************
include \masm32\include\masm32rt.inc

ini_ini       proto :DWORD, :DWORD
get_data      proto :DWORD, :DWORD
set_data      proto :DWORD, :DWORD, :DWORD
write_ini     proto

get_folder2   proto :DWORD

.data
    hend      dd 0h
    ini_f     dd 0h
    mem_addr  dd 0h

.data?
    mem_siz   dd ?  ;Ќе менее 8 байт(минимальна€ запись), переполнение не обрабатываетс€. –азмер одной записи ~ размер имени + размер данных + 30 байт
    s_mem     dd ?
    g_mem     dd ?
    rzv       dd ?
    loc_buf_1 TCHAR 2048 dup (?)

.code
;**********************************************************************************************************************************************************
ini_ini proc uses ebx ecx edx name_ini:DWORD, siz:DWORD
LOCAL lrgi:LARGE_INTEGER
.if mem_addr== 0h
    mrm mem_siz, siz
    invoke LocalAlloc, 040h, mem_siz
    mov mem_addr, eax
    mov s_mem, eax
    mov g_mem, eax
    ;--------------------------≈сли им€ файла не задано, то используетс€ полное им€ исполн€емого модул€ с добавлением приставки ".ini".
    .if name_ini== 0h
        lea ebx, loc_buf_1
        mov word ptr[ebx], 00000h
    .else
        invoke lstrcpyW, addr loc_buf_1, name_ini
    .endif
    invoke get_folder2, addr loc_buf_1

    invoke CreateFileW, eax, GENERIC_READ, FILE_SHARE_READ, 0h, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0h  ;  FILE_ATTRIBUTE_HIDDEN
    .if eax== INVALID_HANDLE_VALUE
        mov ini_f, 0h
    .else
        mov hend, eax
        invoke GetFileSizeEx, hend, addr lrgi
        mov ecx, mem_siz
        .if lrgi.LowPart<= ecx && lrgi.LowPart>= 08h && lrgi.HighPart== 0h
            invoke ReadFile, hend, mem_addr, lrgi.LowPart, addr rzv, 0h
            mov eax, lrgi.LowPart
            .if rzv== eax
                mov ini_f, 01h
            .else
                mov ini_f, 0h
            .endif
        .else
            mov ini_f, 0h
        .endif
        invoke CloseHandle, hend
        mov hend, 0h
    .endif
;--------------------------1- файл был прочитан, 0- файл небыл прочитан, -1 - повторный вызов возможен только после вызова write_ini
.else
    return -1
.endif
return ini_f
ini_ini endp
;**********************************************************************************************************************************************************
get_data proc uses ebx ecx edx data_name:DWORD, dat:DWORD
LOCAL loc_m:DWORD, loc_g:DWORD
.if mem_addr!= 0h
    .if data_name!= 0h
        mrm loc_g, mem_addr
        sear:
        invoke lstrcmp, loc_g, data_name
        .if eax== 0h
            mrm g_mem, loc_g
            jmp gett
        .else
            mov ebx, loc_g
            @@:
            inc ebx
            cmp dword ptr[ebx], 0aaddffffh
            jne @B
            cmp dword ptr[ebx+4], 00a0dffffh
            jne @B
            add ebx, 8
            ;---
            mov ecx, ebx
            sub ecx, mem_addr
            cmp ecx, rzv
            jae ennd
            ;---
            mov loc_g, ebx
            jmp sear
        .endif
    .endif

    mov ecx, g_mem
    sub ecx, mem_addr
    cmp ecx, rzv
    jae ennd
    
    gett:
    mov ebx, g_mem
    mov al, byte ptr[ebx]
    .if al!= 0h
        invoke lstrlen, g_mem
        inc eax
        add g_mem, eax
    .endif
    
    inc g_mem
    mov ebx, g_mem
    mov al, byte ptr[ebx]
    .if al== 041h ;A
        add g_mem, 02h
        invoke lstrcpy, dat, g_mem
        invoke lstrlen, g_mem
        add g_mem, eax
        add g_mem, 9
        ret
    .elseif al== 057h ;W
        add g_mem, 02h
        invoke lstrcpyW, dat, g_mem
        invoke lstrlenW, g_mem
        shl eax, 1
        add g_mem, eax
        add g_mem, 10
        ret
    .else
        invoke lstrlen, g_mem
        inc eax
        mov loc_m, eax
        invoke atodw, g_mem
        mov ecx, eax
        mov ebx, loc_m
        add g_mem, ebx
        mov esi, g_mem
        mov edi, dat
        rep movsb
        add g_mem, eax
        add g_mem, 8
        ret
    .endif
.endif
return -1
ennd:
return 0
get_data endp
;**********************************************************************************************************************************************************
set_data proc uses ebx ecx edx data_name:DWORD, dat:DWORD, data_type:DWORD
LOCAL loc_buf[64]:BYTE
.if mem_addr!= 0h
    ;--------------------------«апись имени данных. ≈сли им€ не используетс€, то данные должны читатьс€ в том-же пор€дке в котором записывались
    .if data_name!= 0h
        invoke lstrlen, data_name
        inc eax
        mov ecx, eax
        mov esi, data_name
        mov edi, s_mem
        rep movsb
        add s_mem, eax
    .endif
    ;--------------------------«апись типа данных и данных
    mov ebx, s_mem
    mov byte ptr[ebx], 0h ;--------------0 значит впереди тип данных
    inc s_mem
    .if data_type> 0h && data_type!= -1 ;n = количество байт в массиве
        invoke dwtoa, data_type, addr loc_buf
        invoke lstrlen, addr loc_buf
        inc eax
        mov ecx, eax
        lea esi, loc_buf
        mov edi, s_mem
        rep movsb
        add s_mem, eax
    
        mov esi, dat
        mov edi, s_mem
        mov ecx, data_type
        rep movsb
        mov ecx, data_type
        add s_mem, ecx
    .elseif data_type== 0h ;---------------0 = A = данные- ASCII строка
        mov ebx, s_mem
        mov word ptr[ebx], 0041h
        add s_mem, 2
    
        invoke lstrlen, dat
        inc eax
        mov ecx, eax
        mov esi, dat
        mov edi, s_mem
        rep movsb
        add s_mem, eax
    .elseif data_type== -1 ;---------------- -1 = W = данные- UNICODE строка
        mov ebx, s_mem
        mov word ptr[ebx], 0057h
        add s_mem, 2

        invoke lstrlenW, dat
        shl eax, 1
        add eax, 2
        mov ecx, eax
        mov esi, dat
        mov edi, s_mem
        rep movsb
        add s_mem, eax
    .else
        return 0
    .endif
    ;--------------------------—игнатура конца одной записи
    mov ebx, s_mem
    mov dword ptr[ebx], 0aaddffffh
    mov dword ptr[ebx+4], 00a0dffffh
    add s_mem, 8
    ;--------------------------¬озвращает общее количество записанных байт
    mov eax, s_mem
    sub eax, mem_addr
    ret
.endif
return -1
set_data endp
;**********************************************************************************************************************************************************
write_ini proc uses ebx ecx edx
.if mem_addr!= 0h
    invoke CreateFileW, addr loc_buf_1, GENERIC_WRITE, FILE_SHARE_WRITE, 0h, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0h  ;  FILE_ATTRIBUTE_HIDDEN
    .if eax== INVALID_HANDLE_VALUE
        return 0
    .else
        mov hend, eax
        mov ecx, s_mem
        sub ecx, mem_addr
        invoke WriteFile, hend, mem_addr, ecx, addr rzv, 0h
        invoke CloseHandle, hend
    .endif
    invoke LocalFree, mem_addr
    mov mem_addr, 0h
    return 1
.endif
return -1
write_ini endp
;**********************************************************************************************************************************************************
get_folder2 proc loc_buf:DWORD
LOCAL loc_1:DWORD
LOCAL name_ini[2048]:TCHAR
invoke lstrlenW, loc_buf
.if eax== 0h
    invoke GetModuleFileNameW, 0h, loc_buf, 2048
    invoke lstrcatW, loc_buf, uc$(".ini")
.else
    invoke lstrcpyW, addr name_ini, loc_buf
    invoke GetModuleFileNameW, 0h, loc_buf, 2048
    mov ebx, loc_buf
    @@:
    mov ax, word ptr[ebx]
    .if ax== 0005ch  ;\
        mov loc_1, ebx
        add loc_1, 02h
    .elseif ax== 0h
        jmp @F
    .endif
    add ebx, 02h
    jmp @B
    @@:
    mov ebx, loc_1
    mov word ptr[ebx], 0h
    invoke lstrcatW, loc_buf, addr name_ini
.endif
return loc_buf
get_folder2 endp
;**********************************************************************************************************************************************************
end

