; ============================================================================
; MkM - Disco completo (bootloader + kernel + shell)
; ============================================================================
bits 16

; =========== SETOR 1: BOOTLOADER ===========
org 0x7C00

boot:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Carregar setores 2-33 (16 KB) para 0x1000:0000
    mov ah, 0x02
    mov al, 32
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    int 0x13
    jc boot_error

    ; Pular para o kernel
    jmp 0x1000:0x0000

boot_error:
    mov si, boot_err_msg
    call boot_print
    cli
    hlt

boot_print:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp boot_print
.done:
    ret

boot_err_msg: db "Boot error", 0

; Padding manual at? 510 bytes
times 510-($-$$) db 0
dw 0xAA55

; =========== SETOR 2+: KERNEL ===========
kernel:
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    mov ax, 3
    int 0x10

    mov si, msg_welcome
    call sprint

main_loop:
    mov si, crlf
    call sprint
    mov si, msg_prompt
    call sprint

    mov di, buffer
    xor cx, cx

.read:
    xor ah, ah
    int 0x16
    cmp al, 13
    je .execute
    cmp al, 8
    jne .normal
    jcxz .read
    dec cx
    mov al, 8
    call sputc
    mov al, ' '
    call sputc
    mov al, 8
    call sputc
    jmp .read
.normal:
    cmp cx, 254
    jae .read
    mov bx, cx
    mov [di+bx], al
    inc cx
    call sputc
    jmp .read

.execute:
    mov bx, cx
    mov byte [di+bx], 0
    mov si, crlf
    call sprint

    cmp byte [buffer], 0
    je main_loop

    mov si, buffer
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
msg_welcome: db "MkM v0.8.0",13,10,"Digite 'help'",13,10,0
msg_prompt:  db "MkM> ",0
crlf:        db 13,10,0
msg_help:    db "help, clear, echo, about, shutdown",13,10,0
msg_about:   db "ovsbMicroKernelMac - Microkernel macOS",13,10,0
msg_shutdown: db "Desligando...",13,10,0
msg_error1:  db "Comando '",0
msg_error2:  db "' nao encontrado",13,10,0

cmd_help:     db "help",0
cmd_clear:    db "clear",0
cmd_echo:     db "echo ",0
cmd_about:    db "about",0
cmd_shutdown: db "shutdown",0

buffer: times 256 db 0
tmp: db 0, 0

; Padding para 16 KB (32 setores)
times 16384-($-$$) db 0
