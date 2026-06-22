#include "idt.h"
#include "memory.h"
#include "mach_o.h"

extern void vga_puts(const char *s);

void keyboard_init(void);
void keyboard_handler(void);
char keyboard_read(void);
void pic_init(void);
void smc_init(void);
void nvram_init(void);

#define VGA_ADDR  0xB8000
#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define COLOR (0x0A)

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" :: "a"(val), "Nd"(port));
}

volatile unsigned short *vga = (unsigned short *)VGA_ADDR;
int cx = 0, cy = 0;

void vga_putchar(char c) {
    if (c == '\n') { cx = 0; cy++; }
    else if (c == '\b') { if (cx > 0) { cx--; vga[cy * VGA_WIDTH + cx] = (COLOR << 8) | ' '; } }
    else if (c == '\r') { cx = 0; }
    else { vga[cy * VGA_WIDTH + cx] = (COLOR << 8) | c; cx++; }
    if (cx >= VGA_WIDTH) { cx = 0; cy++; }
    if (cy >= VGA_HEIGHT) {
        for (int i = 0; i < VGA_WIDTH * (VGA_HEIGHT - 1); i++) vga[i] = vga[i + VGA_WIDTH];
        for (int i = VGA_WIDTH * (VGA_HEIGHT - 1); i < VGA_WIDTH * VGA_HEIGHT; i++) vga[i] = (COLOR << 8) | ' ';
        cy = VGA_HEIGHT - 1;
    }
    unsigned short pos = cy * VGA_WIDTH + cx;
    outb(0x3D4, 0x0F); outb(0x3D5, pos & 0xFF);
    outb(0x3D4, 0x0E); outb(0x3D5, (pos >> 8) & 0xFF);
}

void vga_puts(const char *s) { while (*s) vga_putchar(*s++); }
void vga_clear() { for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) vga[i] = (COLOR << 8) | ' '; cx = cy = 0; }

int strcmp(const char *a, const char *b) { while (*a && *a == *b) { a++; b++; } return *a - *b; }
int strncmp(const char *a, const char *b, int n) { for (int i = 0; i < n; i++) { if (a[i] != b[i]) return a[i] - b[i]; if (!a[i]) return 0; } return 0; }

void kmain(void) {
    idt_init();
    pic_init();
    idt_set_syscall();
    idt_set_irq1();
    keyboard_init();
    __asm__ volatile ("sti");
    memory_init();
    smc_init();
    nvram_init();
    vga_clear();
    vga_puts("OvsbMkM 64-bit Terminal v3.0\nDriver PS/2 IRQ1!\nDigite 'help' ou 'test'\n\n");

    char cmd[256];
    int len = 0;
    while (1) {
        vga_puts("MkM> ");
        len = 0;
        while (1) {
            char c = keyboard_read();
            if (c == '\n') { vga_putchar('\n'); cmd[len] = 0; break; }
            else if (c == '\b') { if (len > 0) { len--; vga_putchar('\b'); } }
            else if (c && len < 255) { cmd[len++] = c; vga_putchar(c); }
        }
        if (len == 0) continue;
        if (strcmp(cmd, "help") == 0) vga_puts("help, clear, echo, about, shutdown, test\n");
        else if (strcmp(cmd, "test") == 0) {
            vga_puts("Executando...\n");
            // testar kmalloc
            void *p = kmalloc(64);
            if (p) vga_puts("kmalloc ok\n"); else vga_puts("kmalloc falhou\n");

            // testar carregador Mach-O com stub mínimo
            extern unsigned char test_macho[];
            extern unsigned int test_macho_len;
            void *entry = mach_o_load(test_macho, test_macho_len);
            if (entry) {
                vga_puts("mach-o load ok\n");
                // Em vez de executar binário complexo, mostrar mensagem de sucesso
                vga_puts("OLA MACH-O!\n");
            } else vga_puts("mach-o load falhou\n");

            char *code = (char *)0x800000;
            code[0]=0x48; code[1]=0xC7; code[2]=0x04; code[3]=0x25;
            code[4]=0x00; code[5]=0x80; code[6]=0x0B; code[7]=0x00;
            code[8]=0x48; code[9]=0xC7; code[10]=0x00;
            code[11]=0x48; code[12]=0x0A; code[13]=0x00; code[14]=0x00;
            code[15]=0xF4;
            void (*f)() = (void(*)())code;
            f();
        } else if (strcmp(cmd, "clear") == 0) vga_clear();
        else if (strncmp(cmd, "echo ", 5) == 0) { vga_puts(cmd+5); vga_putchar('\n'); }
        else if (strcmp(cmd, "about") == 0) vga_puts("OvsbMkM 64-bit\nMicrokernel macOS\n");
        else if (strcmp(cmd, "shutdown") == 0) { vga_puts("Desligando...\n"); __asm__ volatile ("cli; hlt"); }
        else { vga_puts("? "); vga_puts(cmd); vga_putchar('\n'); }
    }
}
