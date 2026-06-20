; ============================================================================
; MkM - Kernel (Terminal Interativo)
; ============================================================================
bits 16
org 0x10000

kernel:
    ; Configurar segmentos
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    ; Modo texto 80x25
    mov ax, 3
    int 0x10

    ; Mensagem inicial
    mov si, msg_welcome
    call sprint

main_loop:
    ; Nova linha e prompt
    mov si, crlf
    call sprint
    mov si, msg_prompt
    call sprint

    ; Ler linha do teclado
    mov di, buffer
    xor cx, cx

.read_key:
    xor ah, ah
    int 0x16
    cmp al, 13          ; Enter
    je .execute
    cmp al, 8           ; Backspace
    jne .normal_key
    jcxz .read_key
    dec cx
    mov al, 8
    call sputc
    mov al, ' '
    call sputc
    mov al, 8
    call sputc
    jmp .read_key

.normal_key:
    cmp cx, 254
    jae .read_key
    mov bx, cx
    mov [di+bx], al
    inc cx
    call sputc
    jmp .read_key

.execute:
    mov bx, cx
    mov byte [di+bx], 0
    mov si, crlf
    call sprint

    ; Ignorar linha vazia
    cmp byte [buffer], 0
    je main_loop

    ; Procurar comando
    mov si, buffer

    ; help
    mov di, cmd_help
    call strcmp
    jc .try_clear
    mov si, msg_help
    call sprint
    jmp main_loop

.try_clear:
    mov di, cmd_clear
    call strcmp
    jc .try_echo
    mov ax, 3
    int 0x10
    jmp main_loop

.try_echo:
    mov di, cmd_echo
    mov cx, 5
    call strncmp
    jc .try_about
    mov si, buffer
    add si, 5
    cmp byte [si], ' '
    jne .print_echo
    inc si
.print_echo:
    call sprint
    mov si, crlf
    call sprint
    jmp main_loop

.try_about:
    mov di, cmd_about
    call strcmp
    jc .try_shutdown
    mov si, msg_about
    call sprint
    jmp main_loop

.try_shutdown:
    mov di, cmd_shutdown
    call strcmp
    jc .not_found
    mov si, msg_shutdown
    call sprint
    cli
    hlt

.not_found:
    mov si, msg_error1
    call sprint
    mov si, buffer
    call sprint
    mov si, msg_error2
    call sprint
    jmp main_loop

; ---------- FUN??ES ----------
sputc:
    push si
    mov byte [tmp], al
    mov si, tmp
    call sprint
    mov byte [tmp], 0
    pop si
    ret

sprint:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp sprint
.done:
    ret

strcmp:
    push si
    push di
.l:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .diff
    test al, al
    jz .equal
    inc si
    inc di
    jmp .l
.equal:
    clc
    pop di
    pop si
    ret
.diff:
    stc
    pop di
    pop si
    ret

strncmp:
    push si
    push di
    push cx
.l:
    jcxz .equal
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .diff
    test al, al
    jz .equal
    inc si
    inc di
    dec cx
    jmp .l
.equal:
    clc
    pop cx
    pop di
    pop si
    ret
.diff:
    stc
    pop cx
    pop di
    pop si
    ret

; ---------- DADOS ----------
msg_welcome:   db "MkM v0.9.0",13,10,"Digite 'help' para comandos",13,10,0
msg_prompt:    db "MkM> ",0
crlf:          db 13,10,0
msg_help:      db "help, clear, echo, about, shutdown",13,10,0
msg_about:     db "ovsbMicroKernelMac - Microkernel macOS",13,10,0
msg_shutdown:  db "Desligando...",13,10,0
msg_error1:    db "Comando '",0
msg_error2:    db "' nao encontrado",13,10,0

cmd_help:      db "help",0
cmd_clear:     db "clear",0
cmd_echo:      db "echo ",0
cmd_about:     db "about",0
cmd_shutdown:  db "shutdown",0

buffer: times 256 db 0
tmp: db 0, 0

; Padding para 16 KB (16384 bytes)
times 16384-($-$$) db 0
