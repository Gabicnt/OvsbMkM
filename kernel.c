typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;

#define VGA_ADDR    0xB8000
#define VGA_WIDTH   80
#define VGA_HEIGHT  25
#define PS2_DATA    0x60
#define PS2_STATUS  0x64

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" :: "a"(val), "Nd"(port));
}

static volatile uint16_t *vga = (volatile uint16_t *)VGA_ADDR;
static int cx = 0, cy = 0;
static uint8_t color = 0x0A;

void vga_update_cursor(void) {
    uint16_t pos = cy * VGA_WIDTH + cx;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

void vga_clear(void) {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++)
        vga[i] = (color << 8) | ' ';
    cx = cy = 0;
    vga_update_cursor();
}

void vga_scroll(void) {
    for (int i = 0; i < VGA_WIDTH * (VGA_HEIGHT - 1); i++)
        vga[i] = vga[i + VGA_WIDTH];
    for (int i = VGA_WIDTH * (VGA_HEIGHT - 1); i < VGA_WIDTH * VGA_HEIGHT; i++)
        vga[i] = (color << 8) | ' ';
    if (cy > 0) cy--;
}

void vga_putchar(char c) {
    if (c == '\n') { cx = 0; cy++; }
    else if (c == '\b') { if (cx > 0) { cx--; vga[cy * VGA_WIDTH + cx] = (color << 8) | ' '; } }
    else if (c == '\t') { for (int i = 0; i < 4; i++) vga_putchar(' '); return; }
    else if (c != '\r') { vga[cy * VGA_WIDTH + cx] = (color << 8) | c; cx++; }
    if (cx >= VGA_WIDTH) { cx = 0; cy++; }
    if (cy >= VGA_HEIGHT) { vga_scroll(); cy = VGA_HEIGHT - 1; }
    vga_update_cursor();
}

void vga_puts(const char *s) {
    while (*s) vga_putchar(*s++);
}

uint8_t ps2_read(void) {
    while (!(inb(PS2_STATUS) & 1));
    return inb(PS2_DATA);
}

static const char sc_ascii[] = {
    0, 0, '1','2','3','4','5','6','7','8','9','0','-','=',0,
    0,'q','w','e','r','t','y','u','i','o','p','[',']',0,
    0,'a','s','d','f','g','h','j','k','l',';','\n',0,
    0,'\\','z','x','c','v','b','n','m',',','.','/',0,
    0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

static const char sc_shift[] = {
    0, 0, '!','@','#','$','%','^','&','*','(',')','_','+',0,
    0,'Q','W','E','R','T','Y','U','I','O','P','{','}',0,
    0,'A','S','D','F','G','H','J','K','L',':','\n',0,
    0,'|','Z','X','C','V','B','N','M','<','>','?',0,
    0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

char ps2_to_ascii(uint8_t sc, int shift) {
    if (sc >= sizeof(sc_ascii)) return 0;
    return shift ? sc_shift[sc] : sc_ascii[sc];
}

void kmain(void) {
    vga_clear();
    vga_puts("MkM MicroKernel v0.1.0\nTerminal inicializado. Digite 'help'.\n\n");
    
    char cmd[256];
    int len = 0, shift = 0;
    
    while (1) {
        vga_puts("MkM > ");
        len = 0;
        
        while (1) {
            uint8_t sc = ps2_read();
            
            if (sc == 0x2A || sc == 0x36) { shift = 1; continue; }
            if (sc == 0xAA || sc == 0xB6) { shift = 0; continue; }
            
            char c = ps2_to_ascii(sc, shift);
            
            if (c == '\n') {
                vga_putchar('\n');
                cmd[len] = 0;
                break;
            } else if (sc == 0x0E && len > 0) {
                len--;
                vga_putchar('\b');
            } else if (c != 0 && len < 255) {
                cmd[len++] = c;
                vga_putchar(c);
            }
        }
        
        if (len == 0) continue;
        
        // Comandos
        if (cmd[0] == 'h' && cmd[1] == 'e' && cmd[2] == 'l' && cmd[3] == 'p' && cmd[4] == 0) {
            vga_puts("Comandos: help, clear, echo, about, shutdown\n");
        } else if (cmd[0] == 'c' && cmd[1] == 'l' && cmd[2] == 'e' && cmd[3] == 'a' && cmd[4] == 'r') {
            vga_clear();
        } else if (cmd[0] == 'a' && cmd[1] == 'b' && cmd[2] == 'o' && cmd[3] == 'u' && cmd[4] == 't') {
            vga_puts("ovsbMicroKernelMac (MkM) v0.1.0\n");
            vga_puts("Microkernel para macOS\nAlvo: High Sierra x86-64\n");
        } else if (cmd[0] == 's' && cmd[1] == 'h' && cmd[2] == 'u' && cmd[3] == 't') {
            vga_puts("Desligando...\n");
            break;
        } else if (cmd[0] == 'e' && cmd[1] == 'c' && cmd[2] == 'h' && cmd[3] == 'o') {
            if (cmd[4] == ' ') vga_puts(cmd + 5);
            vga_putchar('\n');
        } else {
            vga_puts("Comando nao encontrado: ");
            vga_puts(cmd);
            vga_putchar('\n');
        }
    }
    
    __asm__ volatile ("cli; hlt");
}
