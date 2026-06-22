#include "idt.h"

#define PS2_DATA   0x60
#define KB_BUFFER_SIZE 256

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" :: "a"(val), "Nd"(port));
}

static volatile char kb_buffer[KB_BUFFER_SIZE];
static volatile int kb_head = 0;
static volatile int kb_tail = 0;

static const char sc_ascii[] = {
    0,0,'1','2','3','4','5','6','7','8','9','0','-','=',0,
    0,'q','w','e','r','t','y','u','i','o','p',0,'[',0,
    0,'a','s','d','f','g','h','j','k','l',';',0,']',
    0,'\\','z','x','c','v','b','n','m',',','.',';',0,
    0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

void keyboard_handler(void) {
    uint8_t sc = inb(PS2_DATA);
    if (sc == 0x57) sc = 0x39;
    if (sc == 0x73) sc = 0x35;
    char c = 0;
    if (sc == 0x1C) c = '\n';
    else if (sc == 0x0E) c = '\b';
    else if (sc < 128) c = sc_ascii[sc];
    if (c) {
        int next = (kb_head + 1) % KB_BUFFER_SIZE;
        if (next != kb_tail) {
            kb_buffer[kb_head] = c;
            kb_head = next;
        }
    }
    outb(0x20, 0x20);
}

void keyboard_init(void) {
    uint8_t mask = inb(0x21);
    outb(0x21, mask & ~0x02);
}

char keyboard_read(void) {
    while (kb_head == kb_tail) __asm__ volatile ("hlt");
    char c = kb_buffer[kb_tail];
    kb_tail = (kb_tail + 1) % KB_BUFFER_SIZE;
    return c;
}
