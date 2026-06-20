ENTRY(_start)
PHDRS
{
    headers PT_PHDR PHDRS;
    text PT_LOAD FILEHDR PHDRS;
}
SECTIONS
{
    . = 1M;
    .multiboot : { KEEP(*(.multiboot)) } :text
    .text : { *(.text) } :text
    .rodata : { *(.rodata) } :text
    .data : { *(.data) } :text
    .bss : { *(.bss) *(COMMON) } :text
}
