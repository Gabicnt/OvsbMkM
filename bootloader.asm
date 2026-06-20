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
    mov al, 32          ; n?mero de setores
    mov ch, 0           ; cilindro
    mov cl, 2           ; setor inicial
    mov dh, 0           ; cabe?a
    mov bx, 0x1000      ; destino (segmento)
    mov es, bx
    xor bx, bx          ; offset 0
    int 0x13
    jc error

    ; Pular para o kernel (0x1000:0000)
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

err_msg: db "Erro ao carregar kernel!", 0

times 510-($-file=boot.img) db 0
dw 0xAA55
