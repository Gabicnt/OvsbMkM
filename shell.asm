; ============================================================================
; MkM - Shell (programa de user space)
; ============================================================================
bits 16
org 0x20000

_start:
    ; Syscall: print welcome
    mov si, msg_welcome
    int 0x80

main_loop:
    mov si, msg_prompt
    int 0x80
    
    mov di, buffer
    xor cx, cx
    
.read:
    ; Syscall: read key
    int 0x81
    cmp al, 13
    je .execute
    cmp al, 8
    jne .normal
    jcxz .read
    dec cx
    mov al, 8
    call putc
    mov al, ' '
    call putc
    mov al, 8
    call putc
    jmp .read
.normal:
    cmp cx, 254
    jae .read
    mov bx, cx
    mov [di+bx], al
    inc cx
    call putc
    jmp .read

.execute:
    mov bx, cx
    mov byte [di+bx], 0
    mov si, crlf
    int 0x80
    
    cmp byte [buffer], 0
    je main_loop
    
    ; ===== HELP =====
    mov si, buffer
    mov di, cmd_help
    call strcmp
    jc .try_clear
    mov si, msg_help
    int 0x80
    jmp main_loop

.try_clear:
    mov si, buffer
    mov di, cmd_clear
    call strcmp
    jc .try_echo
    int 0x82        ; syscall clear
    jmp main_loop

.try_echo:
    mov si, buffer
    mov di, cmd_echo
    mov cx, 5
    call strncmp
    jc .try_about
    mov si, buffer
    add si, 5
    cmp byte [si], ' '
    jne .echo_print
    inc si
.echo_print:
    int 0x80
    mov si, crlf
    int 0x80
    jmp main_loop

.try_about:
    mov si, buffer
    mov di, cmd_about
    call strcmp
    jc .try_uname
    mov si, msg_about
    int 0x80
    jmp main_loop

.try_uname:
    mov si, buffer
    mov di, cmd_uname
    call strcmp
    jc .try_shutdown
    mov si, msg_uname
    int 0x80
    jmp main_loop

.try_shutdown:
    mov si, buffer
    mov di, cmd_shutdown
    call strcmp
    jc .not_found
    mov si, msg_shutdown
    int 0x80
    int 0x83        ; syscall shutdown

.not_found:
    mov si, msg_error1
    int 0x80
    mov si, buffer
    int 0x80
    mov si, msg_error2
    int 0x80
    jmp main_loop

putc:
    push si
    mov byte [tmp], al
    mov si, tmp
    int 0x80
    mov byte [tmp], 0
    pop si
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

msg_welcome: db "Shell MkM v0.4.0",13,10,"Digite 'help'",13,10,0
msg_prompt:  db "> ",0
crlf:        db 13,10,0
msg_help:    db "help, clear, echo, about, uname, shutdown",13,10,0
msg_about:   db "MkM - Microkernel macOS x86-64",13,10,0
msg_uname:   db "MkM 0.4.0",13,10,0
msg_shutdown: db "Desligando...",13,10,0
msg_error1:  db "Comando '",0
msg_error2:  db "' nao encontrado",13,10,0
cmd_help:     db "help",0
cmd_clear:    db "clear",0
cmd_echo:     db "echo ",0
cmd_about:    db "about",0
cmd_uname:    db "uname",0
cmd_shutdown: db "shutdown",0
buffer: times 256 db 0
tmp: db 0, 0
