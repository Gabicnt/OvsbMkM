% ============================================================================
% ovsbMicroKernelMac (MkM) - Guia Técnico Arquitetura Fase 1
% ============================================================================
% Arquivo: docs/ARCHITECTURE_PHASE1.md
% Descrição: Explica em detalhes a arquitetura de boot, drivers e design
% ============================================================================

# Arquitetura Técnica - Fase 1 do MkM

## 1. Fluxo de Boot Completo

### 1.1 QEMU → Kernel (Multiboot2)

```
QEMU inicia com flag: -kernel build/kernel.elf
        ↓
QEMU carrega kernel.elf na memória (1MB = 0x100000)
        ↓
QEMU busca magic number Multiboot2 (0xE85250D6) nos primeiros 32KB
        ↓
QEMU valida checksum e tags Multiboot2
        ↓
QEMU seta CPU em modo protegido 32-bit
        ↓
QEMU seta ESP (stack pointer) temporário
        ↓
QEMU salta para _start do kernel
        ↓
EAX = magic number (0x36D76289)
EBX = pointer para estrutura multiboot2_info
```

### 1.2 Bootloader (boot.asm) — 32-bit

O bootloader realiza as seguintes etapas:

#### Etapa 1: Salvamento de Parâmetros
```asm
mov r8d, eax    ; Salvar magic
mov r9d, ebx    ; Salvar mbi pointer
```
Feito porque vamos mudar de modo e precisar desses valores.

#### Etapa 2: Configuração de GDT

O bootloader carrega uma GDT mínima com 3 descritores:

```
GDT[0] = Null descriptor (obrigatório)
GDT[1] = Code 64-bit (seletor 0x08)
         - L=1 (Long Mode)
         - DB=0 (não aplicável em LM)
         - P=1 (Present)
         - DPL=0 (Kernel mode)
         - S=1 (System)
         - Type=0xA (code, exec-only, readable)

GDT[2] = Data 64-bit (seletor 0x10)
         - Flags similares, mas Type=0x2 (data, r/w)
```

Isso permite que quando entrarmos em long mode, já temos os seletores certos.

#### Etapa 3: Habilitar Bits do Processador

```asm
; PSE (Page Size Extensions) - não obrigatório, mas bom
mov eax, cr4
or eax, 0x10        ; Bit 4 (PSE)
mov cr4, eax

; PAE (Physical Address Extension) - OBRIGATÓRIO para long mode
mov eax, cr4
or eax, 0x20        ; Bit 5 (PAE)
mov cr4, eax

; EFER.LME (Long Mode Enable) - OBRIGATÓRIO
mov ecx, 0xC0000080     ; Endereço MSR EFER
rdmsr
or eax, 0x100           ; Bit 8 (LME)
wrmsr
```

#### Etapa 4: Configurar Paginação

A paginação é OBRIGATÓRIA para entrar em long mode. Criamos tabelas mínimas:

```
PML4 (Page Map Level 4) — 512 entradas de 64 bits
  └─ PDP (Page Directory Pointer) — 512 entradas
      └─ PD (Page Directory) — 512 entradas (2MB pages)
```

Isso mapeia os primeiros 2GB de RAM (512 × 2MB) como identity mapping (virtual = physical).

```asm
mov eax, pml4_table     ; Carregar PML4
mov cr3, eax            ; CR3 aponta para PML4
```

#### Etapa 5: Habilitar Paginação

```asm
mov eax, cr0
or eax, 0x80000001     ; PG (bit 31) + PE (bit 0)
mov cr0, eax
```

#### Etapa 6: Far Jump para 64-bit

```asm
jmp 0x08:_start64       ; Seletor 0x08 = GDT[1] (code 64-bit)
```

Isso força uma refetch da próxima instrução usando o novo seletor, ativando 64-bit mode.

### 1.3 Kernel (kernel.c) — 64-bit

Agora em 64-bit mode:

```asm
bits 64
_start64:
    ; Carregar seletores de dados
    mov ax, 0x10        ; Seletor GDT[2]
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Configurar stack
    mov rsp, stack_top
    
    ; Restaurar argumentos multiboot2
    mov rdi, r8         ; magic (argumento 1 para kmain)
    mov rsi, r9         ; mbi (argumento 2 para kmain)
    
    ; Chamar C
    call kmain
```

## 2. Drivers: VGA (Modo Texto)

### 2.1 Framebuffer VGA

O buffer de vídeo em modo texto fica em `0xB8000` (memória física, mapeada):

```
0xB8000: Caractere 0,0 | Atributo (cor) 0,0
0xB8002: Caractere 0,1 | Atributo (cor) 0,1
...
0xB8002 * 80 = 0xB8FA0: Caractere 24,0 | Atributo 24,0 (última linha)
```

Total: 80 caracteres × 25 linhas × 2 bytes = 4000 bytes

### 2.2 Formato de Cor

Cada caractere usa 2 bytes:

```
Byte 0: Caractere ASCII
Byte 1: Atributo (cor)
        - Bits 0-3: Cor do texto (0-15)
        - Bits 4-6: Cor de fundo (0-7)
        - Bit 7: Intensidade/blink
```

No MkM usamos:
```
Fundo preto (0) + texto verde claro (10)
= (0 << 4) | 10 = 0x0A por byte
```

Então quando escrevemos caractere 'A':
```c
uint16_t entry = (TEXT_COLOR << 8) | 'A';
vga_driver.buffer[linha * 80 + col] = entry;
```

### 2.3 Mover Cursor (portas 0x3D4-0x3D5)

O cursor VGA é controlado via portas I/O:

```c
uint16_t pos = row * 80 + col;

// Byte high do cursor
outb(0x3D4, 0x0E);         // Registrador "cursor high byte"
outb(0x3D5, (pos >> 8) & 0xFF);

// Byte low do cursor
outb(0x3D4, 0x0F);         // Registrador "cursor low byte"
outb(0x3D5, pos & 0xFF);
```

## 3. Drivers: PS/2 (Teclado)

### 3.1 Portas PS/2

```
0x60: Data port (leitura de scancodes)
0x64: Status port (leitura de flags)
      - Bit 0 (OBF): Output Buffer Full (dados disponíveis)
      - Bit 1 (IBF): Input Buffer Full (controladora ocupada)
```

### 3.2 Ler Scancode

```c
// Aguardar dados disponíveis
while (!(inb(0x64) & 0x01)) {
    delay_us(100);
}

// Ler scancode
uint8_t scancode = inb(0x60);
```

### 3.3 Tabela de Scancodes

PS/2 envia scancodes (não ASCII direto):

```
Scancode 0x1E = 'a'
Scancode 0x30 = 'b'
...
Scancode 0x1C = Enter
Scancode 0x0E = Backspace
Scancode 0x2A = Left Shift (pressed)
Scancode 0xAA = Left Shift (released) = 0x2A | 0x80
```

Mantemos um array `scancode_table[256]` que mapeia scancodes para ASCII:

```c
scancode_table[0x1E] = 'a';
scancode_table[0x30] = 'b';
// ...
```

### 3.4 Detecção de Shift

Quando recebemos `0x2A` (shift pressed), setamos flag:

```c
if (scancode == PS2_LSHIFT) {
    ps2_shift_pressed = 1;
    return 0;
}
```

Quando recebemos `0xAA` (shift released):

```c
if (scancode == (PS2_LSHIFT | 0x80)) {
    ps2_shift_pressed = 0;
    return 0;
}
```

Depois usamos `scancode_table_shift[]` se shift está ativo.

## 4. Parser de Comandos

### 4.1 Buffer de Comando

Mantemos um buffer de até 256 caracteres:

```c
struct {
    uint8_t buffer[256];    // String do comando
    uint32_t length;         // Comprimento atual
} cmd_buffer;
```

Enquanto o usuário digita:
- Caracteres normais: `cmd_buffer_add_char(c)`
- Backspace: `cmd_buffer_backspace()`
- Enter: sair do loop, processar `cmd_buffer.buffer`

### 4.2 Parse e Tokenização

```c
const char *ptr = cmd_line;
char arg_buffer[256];
const char *argv[16];
int argc = 0;

while (*ptr && argc < 16) {
    // Pular espaços
    while (*ptr == ' ' || *ptr == '\t') ptr++;
    
    if (!*ptr) break;
    
    // Gravar início do argumento
    argv[argc++] = ptr;
    
    // Avançar até próximo espaço
    while (*ptr && *ptr != ' ' && *ptr != '\t') ptr++;
}
```

Resultado para "echo Ola Mundo":
```
argc = 3
argv[0] = "echo"
argv[1] = "Ola"
argv[2] = "Mundo"
```

### 4.3 Tabela de Comandos (Futura)

Para adicionar novo comando, seria:

```c
typedef struct {
    const char *name;
    void (*handler)(int argc, const char **argv);
} cmd_t;

cmd_t commands[] = {
    {"help", cmd_help},
    {"echo", cmd_echo},
    {"clear", cmd_clear},
    {NULL, NULL}
};

for (int i = 0; commands[i].name; i++) {
    if (strcmp(argv[0], commands[i].name) == 0) {
        commands[i].handler(argc, argv);
        break;
    }
}
```

Por enquanto usamos `if/else if` por simplicidade.

## 5. Alocação de Memória

### 5.1 Símbolos do Linker

O linker script define símbolos:

```ld
PROVIDE(_bss_start = .);
*(.bss)
PROVIDE(_bss_end = .);
```

Que podem ser usados em C:

```c
extern char _bss_start, _bss_end;
uint32_t bss_size = &_bss_end - &_bss_start;
```

### 5.2 Stack

```ld
section .bss
    stack_bottom:
        resb 16384       ; 16KB de stack
    stack_top:
```

Em boot.asm:
```asm
mov rsp, stack_top      ; Stack cresce para baixo
```

### 5.3 Heap (Futuro)

Na Fase 3 adicionaremos um allocador buddy para kmalloc/kfree:

```c
kmalloc(size)     → aloca do heap
kfree(ptr)        → libera para heap
```

## 6. Fluxo do Terminal Interativo

```
while (1) {
    // Exibir prompt
    vga_puts("MkM > ");
    
    // Limpar buffer
    cmd_buffer_clear();
    
    // Loop de leitura de linha
    while (1) {
        scancode = ps2_read_key();      // Bloqueia até tecla
        ascii = ps2_scancode_to_ascii(scancode);
        
        if (ascii == '\n') {
            vga_putchar('\n');
            break;                      // Executar
        } else if (ascii == '\b') {
            cmd_buffer_backspace();
            vga_puts("\b \b");          // Apagar na tela
        } else {
            cmd_buffer_add_char(ascii);
            vga_putchar(ascii);         // Echo
        }
    }
    
    // Executar comando armazenado
    if (cmd_buffer.length > 0) {
        execute_command((const char *)cmd_buffer.buffer);
    }
}
```

## 7. Porquê Estas Escolhas?

### Por que Multiboot2?

- Standard de boot (GRUB, QEMU compatíveis)
- Não precisa reescrever bootloader para cada plataforma
- Tags permitem framebuffer, memory map, etc.
- Será CRUCIAL quando evoluir para boot em máquinas reais

### Por que Paginação Agora?

- Long mode (64-bit) EXIGE paginação
- Facilita memory protection depois (bits NX, RW, etc.)
- Identity mapping simplifica agora, permite VA ≠ PA depois
- Necessário para multitarefa segura

### Por que VGA Texto (não Framebuffer)?

- Testável em qualquer máquina (legado universal)
- Simples de implementar (2 bytes por char, não pixels)
- QEMU simula VGA melhor que framebuffer UEFI
- Será base para TUI depois

### Por que PS/2 (não USB)?

- PS/2 é barramento serial, mais simples
- QEMU emula PS/2 por padrão
- USB é standard moderno, mas mais complexo (118 linhas vs 1000s)
- Legacy support significa roda em máquinas antigas
- Será complementado com USB depois

## 8. Limitações Intencionais

### Sem Interrupts

Ainda fazemos polling de teclado (spin loop) em vez de interrupts. Por quê?

- IDT (Interrupt Descriptor Table) adiciona complexidade
- Polling funciona perfeitamente para input de terminal
- Interrupts virão na Fase 3 com escalonador

### Sem Proteção de Memória

Tudo roda em Ring 0 (privilégio máximo). Por quê?

- Sem isolamento de processo ainda (Fase 4+)
- Ring 0 permite I/O direto (necessário para drivers)
- Proteção virá com paginação avançada

### Sem Sistema de Arquivos

Apenas shell em RAM. Por quê?

- VFS é Fase 6, muito complexo para Fase 1
- Terminal demonsistra conceitos fundamentais sem FS
- Depois carregaremos aplicativos via VFS + Mach-O loader

## 9. Otimizações Possíveis (Futuro)

1. **Inline ASM para funções críticas** (VGA putchar, PS/2 read)
2. **Ring buffer para teclado** (buffer circular de 256 scancodes)
3. **Cursor piscante** (via timer interrupt a 2Hz)
4. **Syntax highlighting** (cores diferentes para comandos)
5. **History de comandos** (buffer de últimas 10 linhas)
6. **Tab completion** (autocompletar comandos)
7. **Alias de comandos** (shortcuts customizados)

## 10. Debugging

### Saída Serial

Para debug:

```c
void serial_putchar(char c) {
    while ((inb(0x3F8 + 5) & 0x20) == 0);
    outb(0x3F8, c);
}
```

Depois rodar QEMU com:
```bash
qemu-system-x86_64 -kernel kernel.elf -serial file:serial.log
```

### GDB Remote

```bash
qemu-system-x86_64 -kernel kernel.elf -s -S
# Em outro terminal:
gdb kernel.elf
target remote localhost:1234
break kmain
continue
```

## 11. Transição para Fase 2

A Fase 2 adiciona:

- **Escalonador de tarefas** (round-robin)
- **Context switching** (salvar/restaurar registradores)
- **Exceções** (IDT completa)
- **Tratamento de erros** (#PF para page faults, #UD para inválidas)
- **Timers** (periódicos para escalonador)

Muita da infraestrutura aqui (GDT, paginação, memory layout) será reutilizada.

---

**Última atualização:** 2026-06-20
