typedef unsigned char uint8_t;
typedef unsigned short uint16_t;

#define VGA_ADDR  0xB8000
#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define PS2_DATA   0x60
#define PS2_STATUS 0x64
#define COLOR (0x0A)

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" :: "a"(val), "Nd"(port));
}

volatile uint16_t *vga = (uint16_t *)VGA_ADDR;
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
    uint16_t pos = cy * VGA_WIDTH + cx;
    outb(0x3D4, 0x0F); outb(0x3D5, pos & 0xFF);
    outb(0x3D4, 0x0E); outb(0x3D5, (pos >> 8) & 0xFF);
}

void vga_puts(const char *s) { while (*s) vga_putchar(*s++); }
void vga_clear() { for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) vga[i] = (COLOR << 8) | ' '; cx = cy = 0; }

uint8_t ps2_read() { while (!(inb(PS2_STATUS) & 0x01)); return inb(PS2_DATA); }

static const char sc_ascii[] = {
    0,0,'1','2','3','4','5','6','7','8','9','0','-','=',0,
    0,'q','w','e','r','t','y','u','i','o','p','[',']',0,
    0,'a','s','d','f','g','h','j','k','l',';',0,0,0,
    0,'\\','z','x','c','v','b','n','m',',','.','/',0,
    0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

int strcmp(const char *a, const char *b) { while (*a && *a == *b) { a++; b++; } return *a - *b; }
int strncmp(const char *a, const char *b, int n) { for (int i = 0; i < n; i++) { if (a[i] != b[i]) return a[i] - b[i]; if (!a[i]) return 0; } return 0; }

void kmain(void) {
    vga_clear();
    vga_puts("OvsbMkM 64-bit Terminal v3.0\nDigite 'help'\n\n");
    char cmd[256];
    int len = 0;
    while (1) {
        vga_puts("MkM> ");
        len = 0;
        while (1) {
            uint8_t sc = ps2_read();
            if (sc == 0x1C) { vga_putchar('\n'); cmd[len] = 0; break; }
            else if (sc == 0x0E) { if (len > 0) { len--; vga_putchar('\b'); } }
            else if (sc < 128) { char c = sc_ascii[sc]; if (c && len < 255) { cmd[len++] = c; vga_putchar(c); } }
        }
        if (len == 0) continue;
        if (strcmp(cmd, "help") == 0) vga_puts("help, clear, echo, about, shutdown\n");
        else if (strcmp(cmd, "clear") == 0) vga_clear();
        else if (strncmp(cmd, "echo ", 5) == 0) { vga_puts(cmd + 5); vga_putchar('\n'); }
        else if (strcmp(cmd, "about") == 0) vga_puts("OvsbMkM 64-bit\nMicrokernel macOS High Sierra\n");
        else if (strcmp(cmd, "shutdown") == 0) { vga_puts("Desligando...\n"); __asm__ volatile ("cli; hlt"); }
        else { vga_puts("? "); vga_puts(cmd); vga_putchar('\n'); }
    }
}
