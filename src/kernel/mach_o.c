#include "mach_o.h"

// Ponto de entrada do programa carregado
typedef void (*entry_point_t)(void);

void *load_mach_o(void *data) {
    mach_header_64_t *header = (mach_header_64_t *)data;
    
    // Verificar magic number
    if (header->magic != MH_MAGIC_64 && header->magic != MH_CIGAM_64) {
        return 0;  // Formato inválido
    }
    
    volatile unsigned short *vga = (unsigned short *)0xB8000;
    vga[160] = (0x0A << 8) | 'M';  // M = Mach-O detectado
    vga[161] = (0x0A << 8) | 'O';
    
    // Processar comandos de carga
    uint8_t *cmds = (uint8_t *)(header + 1);
    entry_point_t entry = 0;
    
    for (uint32_t i = 0; i < header->ncmds; i++) {
        load_command_t *cmd = (load_command_t *)cmds;
        
        if (cmd->cmd == LC_SEGMENT_64) {
            segment_command_64_t *seg = (segment_command_64_t *)cmds;
            
            // Se for __TEXT, copiar para memória
            if (seg->filesize > 0) {
                uint8_t *src = (uint8_t *)data + seg->fileoff;
                uint8_t *dst = (uint8_t *)(uint64_t)seg->vmaddr;
                for (uint64_t j = 0; j < seg->filesize; j++) {
                    dst[j] = src[j];
                }
            }
        }
        
        if (cmd->cmd == LC_UNIXTHREAD) {
            // Extrair ponto de entrada (RIP)
            uint32_t *state = (uint32_t *)(cmds + 16);
            entry = (entry_point_t)((uint64_t *)(state + 8))[0];
        }
        
        cmds += cmd->cmdsize;
    }
    
    vga[162] = (0x0A << 8) | 'L';  // L = Loaded
    return (void *)entry;
}
