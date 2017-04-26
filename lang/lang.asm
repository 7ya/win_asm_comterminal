; Author:            7ya
; Update date:       26.04.2017
; Contact:           7ya@protonmail.com
; Internet address:  https://github.com/7ya/win_asm_comterminal
; License:           GPL-3.0
;**********************************************************************************************************************************************************
__UNICODE__ equ 1
include \masm32\include\masm32rt.inc

read_lng       proto :DWORD, :DWORD
get_str        proto :DWORD, :DWORD, :DWORD, :DWORD
list_lng       proto :DWORD, :DWORD
CreateLngMenu  proto :DWORD, :DWORD
free_lng       proto

get_folder1    proto :DWORD
load_str       proto :DWORD
get_lng_addr   proto :DWORD

.data
    hend       dd 0h
    lng_f      dd 0h
    mem_addr   dd 0h
    mem_addr_2 dd 0h
    g_mem      dd 0h
    z_mem      dd 0h
    list_addr  dd 0h
    min_str    dd 4056
    end_mem    dd 4056
    lng_num    dd 0h

.data?
    hMenu1     dd ?
    rzv        dd ?
    sizz       dd ?
    loc_buf_1  TCHAR 2048 dup (?)
    temp_str   TCHAR 1024 dup (?)
    hLng       TCHAR 64 dup (?)
    Name_lng   TCHAR 64 dup (?)

.code
;**********************************************************************************************************************************************************
read_lng proc uses ebx ecx edx file_lng:DWORD, siz:DWORD
LOCAL lrgi:LARGE_INTEGER
.if mem_addr_2== 0h
    ;--------------------------Если имя файла не задано, то используется полное имя исполняемого модуля с добавлением приставки ".lng"
    .if file_lng== 0h
        lea ebx, loc_buf_1
        mov word ptr[ebx], 00000h
    .else
        invoke lstrcpy, addr loc_buf_1, file_lng
    .endif
    invoke get_folder1, addr loc_buf_1
    invoke CreateFile, eax, GENERIC_READ, FILE_SHARE_READ, 0h, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0h  ;  FILE_ATTRIBUTE_HIDDEN
    .if eax== INVALID_HANDLE_VALUE
        mov lng_f, 0h
    .else
        mov hend, eax
        invoke GetFileSizeEx, hend, addr lrgi
        .if lrgi.LowPart> 0h && lrgi.HighPart== 0h
            mov ecx, lrgi.LowPart
            add ecx, 64
            invoke LocalAlloc, 040h, ecx
            mov mem_addr, eax
            mov list_addr, eax
            invoke ReadFile, hend, mem_addr, lrgi.LowPart, addr rzv, 0h
            mov eax, lrgi.LowPart
            .if rzv== eax
                mov lng_f, 01h
            .else
                mov lng_f, 0h
            .endif
        .else
            mov lng_f, 0h
        .endif
        invoke CloseHandle, hend
        mov hend, 0h
    .endif
    mrm sizz, siz
    invoke LocalAlloc, 040h, siz
    mov mem_addr_2, eax
    mov z_mem, eax
.else
    return -1
.endif
return lng_f
read_lng endp
;**********************************************************************************************************************************************************
get_str proc uses ebx ecx edx str_addr:DWORD, nnn:DWORD, lng:DWORD, hInstance:DWORD
.if mem_addr_2!= 0h
    invoke get_lng_addr, lng
    mov g_mem, eax
    .if g_mem!= 0h
        nnn_start:
        mov ecx, end_mem
        cmp ecx, min_str
        jb yyy
        invoke load_str, str_addr
        cmp eax, 0
        je yyy
            mov eax, z_mem
            sub eax, mem_addr_2
            mov ecx, sizz
            sub ecx, eax
            mov end_mem, ecx
            cmp nnn, 0h
            je @F
                dec nnn
                add str_addr, 08h
                jmp nnn_start
            @@:
        return 1
    .else
        nnn_start2:
        mov ecx, end_mem
        cmp ecx, min_str
        jb yyy
            mov ebx, str_addr
            mov eax, dword ptr[ebx+4]
            invoke LoadString, hInstance, eax, z_mem, min_str
            mov ebx, str_addr
            mov eax, z_mem
            mov dword ptr[ebx], eax
            
            invoke lstrlen, z_mem
            shl eax, 1
            add eax, 02h
            add z_mem, eax
            
            mov eax, z_mem
            sub eax, mem_addr_2
            mov ecx, sizz
            sub ecx, eax
            mov end_mem, ecx
            cmp nnn, 0h
            je @F
                dec nnn
                add str_addr, 08h
                jmp nnn_start2
            @@:
        return 1
    .endif
    yyy:
    return 0
.endif
return -1
get_str endp
;**********************************************************************************************************************************************************
load_str proc str_addr:DWORD
LOCAL loc_1:DWORD
LOCAL loc_str[64]:TCHAR, loc_str2[64]:TCHAR
    mov ebx, str_addr
    mov ecx, dword ptr[ebx+4]
    invoke lstrcpy, addr loc_str, ustr$(ecx)
    mov ebx, g_mem
    lea edx, loc_str2
;=============================
sstart:
    ;-----
    call corr
    cmp eax, 0
    je www
    ;-----
    cmp ax, 0030h
    jae @F
        add ebx, 02h
        jmp sstart ;-------------------------------- не число, поиск дальше
    @@:
    cmp ax, 0039h
    jbe @F
        add ebx, 02h
        jmp sstart ;-------------------------------- не число, поиск дальше
    @@:
;=============================число найдено, ищем конец строки- идентификатора
ssstart:
    ;-----
    call corr
    cmp eax, 0
    je www
    ;-----
    cmp ax, 0030h
    jb rrr
    cmp ax, 0039h
    ja rrr ;-------------------------------- не число, значит конец строки
        mov word ptr[edx], ax
        add ebx, 02h
        add edx, 02h
        jmp ssstart
    rrr:
    mov word ptr[edx], 0h ;-------------------------------- выбран идентификатор для сравнения
    mov loc_1, ebx
;=============================
    invoke lstrcmp, addr loc_str2, addr loc_str
    .if eax== 0h ;--------------------------------------- идентификатор найден, читаем строку
        mov ebx, loc_1
        add ebx, 02h
        wqe:
            ;-----
            call corr
            cmp eax, 0
            je www
            ;-----
            cmp ax, 0022h ;--- "
            je @F
                add ebx, 02h
                jmp wqe
            @@:

        ;---------------------если первая кавычка нашлась, читаем строку до последней кавычки
        add ebx, 02h
        mov edx, z_mem
        mov esi, edx ;----запоминаем в esi адрес начала строки
        wwqe:
            ;-----
            call corr
            cmp eax, 0
            je www
            ;-----
            cmp eax, 0030005ch ;--- \0   заменить на 0
            jne @F
                mov word ptr[edx], 0
                add ebx, 04h
                add edx, 02h
                jmp wwqe
            @@:
            cmp eax, 006e005ch ;--- \n   заменить на перевод строки
            jne @F
                mov dword ptr[edx], 000a000dh
                add ebx, 04h
                add edx, 04h
                jmp wwqe
            @@:
            cmp eax, 0022005ch ;--- \"   заменить на "
            jne @F
                mov word ptr[edx], 0022h ;--- "
                add ebx, 04h
                add edx, 02h
                jmp wwqe
            @@:
            cmp ax, 0022h ;--- "   ----------------последняя кавычка
            je @F
                mov word ptr[edx], ax
                add ebx, 02h
                add edx, 02h
                jmp wwqe
            @@:
            mov word ptr[edx], 0h
            add edx, 02h
            mov z_mem, edx

            mov ebx, str_addr
            mov dword ptr[ebx], esi ;------ помещаем адрес найденной строки
            return 1
    .else ;------------------------------------идентификатор не найден, ищем дальше
        mov ebx, loc_1
        add ebx, 02h
        
        sssstart:
            ;-----
            call corr
            cmp eax, 0
            je www
            ;-----
            cmp eax, 000a000dh ;------------------ищем следующую строку
            je @F
                add ebx, 02h
                jmp sssstart
            @@:
            lea edx, loc_str2
            add ebx, 04h
            jmp sstart
    .endif
www:
return 0
load_str endp
;**********************************************************************************************************************************************************
corr proc uses ecx
    mov eax, ebx
    sub eax, g_mem
    cmp eax, rzv
    jae s_www
    ;-----
    mov eax, dword ptr[ebx]
    cmp eax, 003d005bh ;--- [=
    jne @F
    mov ecx, dword ptr[ebx+4]
    cmp ecx, 005d003fh ;--- ?]
    je s_www ;-------------------------------- конец строк, начало другого языка
    @@:
    ret
s_www:
return 0
corr endp
;**********************************************************************************************************************************************************
corr2 proc
    mov eax, ebx
    sub eax, mem_addr
    cmp eax, rzv
    jae ss_www
    return 1
ss_www:
return 0
corr2 endp
;**********************************************************************************************************************************************************
list_lng proc uses ebx ecx edx lng:DWORD, name_lng:DWORD
.if mem_addr_2!= 0h
    .if lng_f== 01h
        .if mem_addr!= 0h
            mov ebx, list_addr
            list_m1:
            ;-----
            call corr2
            cmp eax, 0
            je list_end
            ;-----
            mov eax, dword ptr[ebx]
            cmp eax, 003d005bh ;--- [=
            jne list_m2
            mov eax, dword ptr[ebx+4]
            cmp eax, 005d003fh ;--- ?]
            jne list_m2
                list_m3:
                ;-----
                call corr2
                cmp eax, 0
                je list_end
                ;-----
                mov ax, word ptr[ebx]
                cmp ax, 0022h ;--- "
                jne list_m4
                    add ebx, 02h
                    mov ecx, lng
                    list_m5:
                    ;-----
                    call corr2
                    cmp eax, 0
                    je list_end
                    ;-----
                    mov ax, word ptr[ebx]
                    cmp ax, 0022h ;--- "
                    jne list_m55
                        mov word ptr[ecx], 0
                        add ebx, 02h
                        list_m6:
                        ;-----
                        call corr2
                        cmp eax, 0
                        je list_end
                        ;-----
                        mov ax, word ptr[ebx]
                        cmp ax, 0022h ;--- "
                        jne list_m66
                            add ebx, 02h
                            mov ecx, name_lng
                            list_m7:
                            ;-----
                            call corr2
                            cmp eax, 0
                            je list_end
                            ;-----
                            mov eax, dword ptr[ebx]
                            cmp eax, 0022005ch ;--- \"   ------------- если найдена кавычка после левого слеша, то убираем слеш
                            jne @F
                                mov word ptr[ecx], 0022h ;--- "
                                add ecx, 02h
                                add ebx, 04h
                                jmp list_m7
                            @@:
                            mov ax, word ptr[ebx]
                            cmp ax, 0022h ;--- "
                            jne @F
                                mov word ptr[ecx], 0
                                add ebx, 02h
                                mov list_addr, ebx
                                inc lng_num
                                return lng_num
                            @@:
                            mov word ptr[ecx], ax
                            add ebx, 02h
                            add ecx, 02h
                            jmp list_m7
                        list_m66:
                        add ebx, 02h
                        jmp list_m6
                    list_m55:
                    mov word ptr[ecx], ax
                    add ebx, 02h
                    add ecx, 02h
                    jmp list_m5
                list_m4:
                add ebx, 02h
                jmp list_m3
            list_m2:
            add ebx, 02h
            jmp list_m1
              
            list_end:
            mrm list_addr, mem_addr
            mov lng_num, 0h
        .endif
    .endif
.endif
return 0
list_lng endp
;**********************************************************************************************************************************************************
free_lng proc uses ebx ecx edx
.if mem_addr_2!= 0h
    invoke LocalFree, mem_addr_2
    mov mem_addr_2, 0h
    invoke LocalFree, mem_addr
    mov mem_addr, 0h
    mov list_addr, 0h
    mov g_mem, 0h
    mov z_mem, 0h
    return 1
.endif
return -1
free_lng endp
;**********************************************************************************************************************************************************
get_folder1 proc loc_buf:DWORD
LOCAL loc_1:DWORD
LOCAL file_lng[2048]:TCHAR
invoke lstrlen, loc_buf
.if eax== 0h
    invoke GetModuleFileName, 0h, loc_buf, 2048
    invoke lstrcat, loc_buf, uc$(".lng")
.else
    invoke lstrcpy, addr file_lng, loc_buf
    invoke GetModuleFileName, 0h, loc_buf, 2048
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
    invoke lstrcat, loc_buf, addr file_lng
.endif
return loc_buf
get_folder1 endp
;**********************************************************************************************************************************************************
get_lng_addr proc lng:DWORD
            cmp lng, 0h
            je zzzz
            ;--------------------------------------Получение указателя на набор строк заданного языка
            xor edx, edx
            mov ebx, mem_addr
            beginning:
                mov ecx, ebx
                sub ecx, mem_addr
                cmp ecx, rzv
                jae zzzz
                mov eax, dword ptr[ebx]
                cmp eax, 003d005bh ;--- [=
                jne zzz
                mov eax, dword ptr[ebx+4]
                cmp eax, 005d003fh ;--- ?]
                jne zzz
                inc edx
                cmp edx, lng
                jne zzz
                    add ebx, 08h
                    @@:
                    mov ecx, ebx
                    sub ecx, mem_addr
                    cmp ecx, rzv
                    jae zzzz
                    ;------
                    add ebx, 02h
                    mov eax, dword ptr[ebx]
                    cmp eax, 000a000dh ;--- перевод строки
                    jne @B
                    add ebx, 04h
                    return ebx
                zzz:
                add ebx, 02h
                jmp beginning
            zzzz:
return 0h
get_lng_addr endp
;**********************************************************************************************************************************************************
CreateLngMenu proc uses ebx hMenu:DWORD, fLng:DWORD
LOCAL loc_m:DWORD
mov loc_m, 5000
startlist:
    invoke list_lng, addr hLng, addr Name_lng
    cmp eax, 0
    je endlist
    cmp eax, 1
    jne @F
        invoke CreatePopupMenu
        mov hMenu1, eax
        invoke AppendMenu, hMenu, MF_POPUP or MF_STRING, hMenu1, uc$("Language")
    @@:
        lea ebx, hLng
        mov eax, dword ptr[ebx]
        cmp eax, 002d002dh  ;--- --
        jne @F
            invoke AppendMenu, hMenu1, MF_SEPARATOR, 0, 0
            jmp startlist
        @@:
        inc loc_m
        invoke AppendMenu, hMenu1, MF_STRING, loc_m, addr Name_lng
        mov ebx, loc_m
        sub ebx, 5000
        cmp ebx, fLng
        jne @F
            invoke CheckMenuItem, hMenu1, loc_m, MF_BYCOMMAND or MF_CHECKED
            invoke EnableMenuItem, hMenu1, loc_m, MF_BYCOMMAND or MF_GRAYED or MF_DISABLED
        @@:
        lea ebx, hLng
        mov eax, dword ptr[ebx]
        cmp eax, 00780078h  ;--- xx
        jne @F
            invoke EnableMenuItem, hMenu1, loc_m, MF_BYCOMMAND or MF_GRAYED or MF_DISABLED
        @@:
    jmp startlist
endlist:
return hMenu1
CreateLngMenu endp
;**********************************************************************************************************************************************************
end

