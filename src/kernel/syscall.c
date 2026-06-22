#include "idt.h"
#include <stdint.h>

// Syscalls do XNU (High Sierra) — números essenciais
#define SYS_exit     1
#define SYS_read     3
#define SYS_write    4
#define SYS_open     5
#define SYS_close    6
#define SYS_mmap     197
#define SYS_munmap   73
#define SYS_mprotect 74
#define SYS_getpid   20
#define SYS_getuid   24
#define SYS_geteuid  25
#define SYS_getgid   47
#define SYS_getegid  48
#define SYS_ioctl    54
#define SYS_gettimeofday 116

extern void vga_putchar(char c);
extern void vga_puts(const char *s);

// minimal kernel state
static int fake_pid = 1;

void syscall_handler(uint64_t num, uint64_t a1, uint64_t a2, uint64_t a3) {
    switch (num) {
        case SYS_write: {
            int fd = (int)a1;
            const char *buf = (const char *)a2;
            int count = (int)a3;
            if (fd == 1 || fd == 2) {
                for (int i = 0; i < count; i++) vga_putchar(buf[i]);
            }
            break;
        }
        case SYS_read: {
            int fd = (int)a1;
            char *buf = (char *)a2;
            int count = (int)a3;
            // apenas leitura do teclado (/dev/tty)
            if (fd == 0) {
                for (int i = 0; i < count; i++) {
                    // bloqueante simplificado: retorna 0
                    buf[i] = 0;
                }
            }
            break;
        }
        case SYS_open: {
            const char *path = (const char *)a1;
            // suportamos apenas /dev/tty -> fd 0
            if (path && path[0] == '/') {
                if (path[1]=='d' && path[2]=='e' && path[3]=='v') {
                    // /dev/tty -> return 0
                    // outras -> -1
                    if (path[4]=='/') return; 
                }
            }
            break;
        }
        case SYS_close:
            // noop
            break;
        case SYS_mmap:
        case SYS_munmap:
        case SYS_mprotect:
            // stubs — não implementado
            break;
        case SYS_getpid:
            // retornar pid em registro — simplificado: escreve no vga uma letra
            vga_puts("[pid]");
            break;
        case SYS_getuid:
        case SYS_geteuid:
        case SYS_getgid:
        case SYS_getegid:
            // retornar 0
            break;
        case SYS_ioctl:
            // stubs
            break;
        case SYS_gettimeofday:
            // opcional: preencher timeval/tz — stub
            break;
        default:
            vga_puts("Unknown syscall\n");
            break;
    }
}
