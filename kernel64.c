void kmain(void) {
    volatile unsigned short *vga = (unsigned short *)0xB8000;
    const char *msg = "MkM 64-bit Kernel v1.0.0!";
    for (int i = 0; i < 80*25; i++) vga[i] = (0x0A << 8) | ' ';
    for (int i = 0; msg[i]; i++) vga[i] = (0x0A << 8) | msg[i];
    while(1);
}
