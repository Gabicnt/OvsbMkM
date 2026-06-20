bits 16
org 0x7C00
_start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7C00
    mov ax,3
    int 0x10
    mov si,m1
    call p
.l:
    mov si,nl
    call p
    mov si,pr
    call p
    mov di,bf
    xor cx,cx
.r:
    xor ah,ah
    int 0x16
    cmp al,13
    je .e
    cmp al,8
    jne .c
    jcxz .r
    dec cx
    mov al,8
    call put
    mov al,' '
    call put
    mov al,8
    call put
    jmp .r
.c:
    cmp cx,63
    jae .r
    mov bx,cx
    mov [di+bx],al
    inc cx
    call put
    jmp .r
.e:
    mov bx,cx
    mov byte [di+bx],0
    mov si,nl
    call p
    cmp byte [bf],0
    je .l
    mov si,bf
    mov di,ch
    call sc
    jc .t1
    mov si,mh
    call p
    jmp .l
.t1:
    mov si,bf
    mov di,cc
    call sc
    jc .t2
    mov ax,3
    int 0x10
    jmp .l
.t2:
    mov si,bf
    mov di,ca
    call sc
    jc .t3
    mov si,ma
    call p
    jmp .l
.t3:
    mov si,bf
    mov di,ce
    mov cx,5
    call sn
    jc .t4
    mov si,bf
    add si,5
    cmp byte [si],' '
    jne .sk
    inc si
.sk:
    call p
    mov si,nl
    call p
    jmp .l
.t4:
    mov si,bf
    mov di,cs
    call sc
    jc .nf
    mov si,ms
    call p
    cli
    hlt
.nf:
    mov si,mu
    call p
    jmp .l

put:
    mov ah,0x0E
    int 0x10
    ret

p:
    lodsb
    test al,al
    jz .d
    call put
    jmp p
.d:
    ret

sc:
    push si
    push di
.l2:
    mov al,[si]
    mov ah,[di]
    cmp al,ah
    jne .no
    test al,al
    jz .ok
    inc si
    inc di
    jmp .l2
.ok:
    clc
    pop di
    pop si
    ret
.no:
    stc
    pop di
    pop si
    ret

sn:
    push si
    push di
    push cx
.l3:
    jcxz .ok2
    mov al,[si]
    mov ah,[di]
    cmp al,ah
    jne .no2
    test al,al
    jz .ok2
    inc si
    inc di
    dec cx
    jmp .l3
.ok2:
    clc
    pop cx
    pop di
    pop si
    ret
.no2:
    stc
    pop cx
    pop di
    pop si
    ret

m1: db "MkM v0.2.0",13,10,0
pr: db "> ",0
nl: db 13,10,0
mh: db "help, clear, echo, about, shutdown",13,10,0
ma: db "MkM Microkernel macOS",13,10,0
ms: db "Desligando...",13,10,0
mu: db "Comando nao encontrado",13,10,0
ch: db "help",0
cc: db "clear",0
ca: db "about",0
ce: db "echo ",0
cs: db "shutdown",0
bf: times 64 db 0
    times 510-($-$$) db 0
    dw 0xAA55
