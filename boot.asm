bits 16
org 0x7C00
s:
xor ax,ax
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0x7C00
mov ax,3
int 0x10
mov si,w
call p
.l:
mov si,prompt
call p
mov di,b
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
mov al,13
call put
mov al,10
call put
cmp byte [b],0
je .l
mov si,b
mov di,cmd_h
call sc
jnc .dh
mov di,cmd_c
call sc
jnc .dc
mov di,cmd_e
mov cx,5
call sn
jnc .de
mov di,cmd_a
call sc
jnc .da
mov di,cmd_s
call sc
jnc .ds
mov si,err
call p
jmp .l
.dh: mov si,mh
call p
jmp .l
.dc: mov ax,3
int 0x10
jmp .l
.de: mov si,b
add si,5
cmp byte [si],' '
jne .dp
inc si
.dp: call p
jmp .l
.da: mov si,ma
call p
jmp .l
.ds: mov si,ms
call p
cli
hlt
put:
mov ah,0x0E
mov bh,0
int 0x10
ret
p:
lodsb
test al,al
jz .d
call put
jmp p
.d: ret
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
.ok: clc
pop di
pop si
ret
.no: stc
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
.ok2: clc
pop cx
pop di
pop si
ret
.no2: stc
pop cx
pop di
pop si
ret
w: db 13,10,"MkM v0.6.1",13,10,0
prompt: db "> ",0
mh: db "help, clear, echo, about, shutdown",13,10,0
ma: db "MkM Microkernel macOS",13,10,0
ms: db "Desligando...",13,10,0
err: db "?",13,10,0
cmd_h: db "help",0
cmd_c: db "clear",0
cmd_e: db "echo ",0
cmd_a: db "about",0
cmd_s: db "shutdown",0
b: times 64 db 0
times 510-($-file=boot.img) db 0
dw 0xAA55
