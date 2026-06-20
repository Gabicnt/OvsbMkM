bits 32
section .multiboot
align 4
    dd 0x1BADB002
    dd 0x03
    dd -(0x1BADB002 + 0x03)

section .text
global _start
extern kmain

_start:
    mov esp, stack_top
    push ebx
    push eax
    call kmain
    cli
    hlt

section .bss
align 16
stack_bottom: resb 16384
stack_top:
