; ============================================================================
; MkM - Bootloader (Setor 1)
; Carrega 32 setores (16 KB) do kernel e salta para 0x1000:0000
; ============================================================================
bits 16
org 0x7C00

boot:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Carregar setores 2-33 (16 KB) para 0x1000:0000
    mov ah, 0x02       ; BIOS read sectors
    mov al, 32          ; 32 setores = 16 KB
    mov ch, 0           ; cilindro 0
    mov cl, 2           ; setor inicial 2
    mov dh, 0           ; cabe?a 0
    mov bx, 0x1000      ; segmento destino 0x1000
    mov es, bx
    xor bx, bx          ; offset 0
    int 0x13
    jc error

    ; Saltar para o kernel
    jmp 0x1000:0x0000

error:
    mov si, err_msg
    call print
    cli
    hlt

print:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

err_msg: db "Boot error", 0

times 510-($-$$) db 0
dw 0xAA55
