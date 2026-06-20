bits 32
section .multiboot
align 8
header_start:
    dd 0xE85250D6
    dd 0
    dd header_end - header_start
    dd -(0xE85250D6 + 0 + (header_end - header_start))
    dw 5, 0, 20, 1024, 768, 32
    dw 0, 0, 8
header_end:

section .text
global _start
extern kmain

_start:
    mov esp, stack_top
    mov edi, eax
    mov esi, ebx
    lgdt [gdt64.pointer]
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    mov eax, pml4_table
    mov cr3, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr
    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax
    jmp gdt64.code:_start64

bits 64
_start64:
    mov ax, gdt64.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, stack_top
    call kmain
    cli
    hlt

section .data
align 16
gdt64:
    dq 0
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<53)
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

align 4096
pml4_table:
    dq pdp_table + 3
    times 511 dq 0
pdp_table:
    dq pd_table + 3
    times 511 dq 0
pd_table:
    %assign i 0
    %rep 512
        dq (i * 0x200000) + 0x83
        %assign i i+1
    %endrep

section .bss
align 16
stack_bottom: resb 16384
stack_top:
