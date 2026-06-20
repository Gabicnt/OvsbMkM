# ovsbMicroKernelMac (MkM) - Fase 1: Terminal Interativo

**Versão:** 0.1.0  
**Data:** 2026  
**Autor:** BugsAppetit
**Status:** Funcional

---

## 📋 Visão Geral

A **Fase 1 do MkM** é um kernel bare-metal x86-64 que demonstra os conceitos fundamentais de um sistema operacional:

✅ **Bootloader Multiboot2** — Inicialização via GRUB/QEMU  
✅ **64-bit Long Mode** — Execução em modo protegido 64-bit  
✅ **Driver VGA** — Terminal de texto (80x25 caracteres)  
✅ **Driver PS/2** — Teclado com suporte a shift e caracteres especiais  
✅ **Terminal Interativo** — Shell básico com prompt e parser de comandos  
✅ **Comandos Internos** — help, clear, echo, about, shutdown  

### Tamanho
- **Kernel:** ~15 KB (ELF)
- **RAM mínima:** 256 MB

---

## 🏗️ Arquitetura Técnica

### Fluxo de Inicialização

```
1. QEMU carrega kernel.elf via Multiboot2
   ↓
2. CPU executa boot.asm (_start)
   ↓
3. Bootloader configura:
   - GDT (Global Descriptor Table)
   - Paginação (4KB pages, identity mapping 2GB)
   - EFER.LME (Long Mode Enable)
   ↓
4. Transição para 64-bit mode
   ↓
5. Chamar kmain() em C
   ↓
6. Inicializar VGA driver
   ↓
7. Loop de terminal (leitura de teclado, execução de comandos)
```

### Estrutura de Memória

```
0x0000_0000 ┌─────────────────────┐
            │  Não mapeado        │
            │  (kernel protege)   │
0x0010_0000 ├─────────────────────┤
            │  Kernel MkM         │
            │  (boot.asm + .text) │  ← 0x100000 (1MB)
0x0010_F000 ├─────────────────────┤
            │  .data + .bss       │
0x0010_FFFF ├─────────────────────┤
            │  Heap (futuro)      │
            │  (alocador buddy)   │
0x2000_0000 ├─────────────────────┤
            │  Stack (16KB)       │
            │  (cresce para baixo)│
0xFFFF_FFFF └─────────────────────┘
```

### Drivers Implementados

#### Driver VGA (modo texto 80x25)
- Buffer de vídeo em `0xB8000` (16 bits por caractere)
- Cores: preto (fundo) + verde claro (texto)
- Funções:
  - `vga_putchar(c)` — escrever um caractere
  - `vga_puts(s)` — escrever string
  - `vga_clear_screen()` — limpar tela
  - `vga_scroll()` — rolar linhas para cima
  - `vga_update_cursor()` — posicionar cursor (portas 0x3D4-0x3D5)

#### Driver PS/2 (teclado)
- Leitura de scancodes via porta `0x60` (data) e `0x64` (status)
- Suporte a shift para caracteres maiúsculos/símbolos
- Escapes reconhecidos:
  - Enter (`0x1C`) → nova linha
  - Backspace (`0x0E`) → apagar caractere
  - Shift left/right (`0x2A`/`0x36`) → maiúsculas

---

## 💻 Compilação

### Requisitos

| Ferramenta | Versão Mín. | Plataforma | Download |
|---|---|---|---|
| **NASM** | 2.15 | Windows/Linux/macOS | https://www.nasm.us/ |
| **GCC** | 9.0 | Windows/Linux/macOS | https://gcc.gnu.org/ |
| **GNU LD** | 2.35 | Windows/Linux/macOS | https://sourceware.org/binutils/ |
| **Make** | 4.0 | Linux/macOS | gnu.org/software/make/ |
| **QEMU** | 5.0 | Windows/Linux/macOS | https://www.qemu.org/ |

### Instalação (por SO)

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y nasm gcc make qemu-system-x86
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install -y nasm gcc make qemu-system-x86
```

#### macOS (Homebrew)
```bash
brew install nasm gcc make qemu
```

#### Windows 10/11 (Chocolatey)
```powershell
choco install nasm gcc make qemu
```

#### Windows 10/11 (Manual)
1. Baixar NASM: https://www.nasm.us/
2. Baixar MinGW-w64: https://mingw-w64.org/
3. Baixar GNU Binutils (LD)
4. Baixar QEMU: https://www.qemu.org/download/

---

## 🚀 Execução

### Método 1: Script (Recomendado)

#### Linux/macOS
```bash
cd ovsbMicroKernelMac
chmod +x scripts/run.sh
./scripts/run.sh          # Compilar + executar
./scripts/run.sh build    # Apenas compilar
./scripts/run.sh clean    # Limpar build
```

#### Windows
```powershell
cd ovsbMicroKernelMac
.\scripts\run.ps1                 # Compilar + executar
.\scripts\run.ps1 -Action build   # Apenas compilar
.\scripts\run.ps1 -Action clean   # Limpar build
```

### Método 2: Makefile (Linux/macOS)
```bash
cd ovsbMicroKernelMac
make              # Compilar
make run          # Compilar + executar
make clean        # Limpar
make help         # Mostrar ajuda
```

### Método 3: Manual

#### 1. Compilar boot.asm
```bash
nasm -felf64 -F dwarf -o build/boot.o kernel/boot/boot.asm
```

#### 2. Compilar kernel.c
```bash
gcc -ffreestanding -fno-builtin -fno-stack-protector \
    -nostdlib -mno-red-zone -Wall -O2 -c \
    -o build/kernel.o kernel/core/kernel.c
```

#### 3. Linkar
```bash
ld -m elf_x86_64 -T kernel/boot/linker.ld \
    -o build/kernel.elf build/boot.o build/kernel.o
```

#### 4. Executar
```bash
qemu-system-x86_64 -m 256M -kernel build/kernel.elf -serial stdio -no-reboot
```

---

## 🎮 Uso do Terminal

### Saída Esperada

```
MkM MicroKernel v0.1.0 Terminal inicializado. Digite 'help' para comandos.
MkM > 
```

### Comandos Disponíveis

#### `help` — Mostrar ajuda
```
MkM > help
Comandos disponiveis:
  help   - Mostra esta ajuda
  clear  - Limpa a tela
  echo   - Repete o texto digitado
  about  - Sobre o MkM
  shutdown - Desliga o sistema
MkM > 
```

#### `clear` — Limpar tela
```
MkM > clear
```
A tela é zerada e o cursor volta ao topo.

#### `echo [texto]` — Repetir texto
```
MkM > echo Ola Mundo!
Ola Mundo!
MkM > 
```

#### `about` — Informações do MkM
```
MkM > about
ovsbMicroKernelMac (MkM) v0.1.0
Microkernel para executar binarios macOS
Alvo: High Sierra x86-64
Feito do zero, sem XNU

Arquitetura: 64-bit x86-64
Boot: Multiboot2
Fase: 1 (Terminal Interativo)
MkM > 
```

#### `shutdown` — Desligar sistema
```
MkM > shutdown

Desligando...
```
O kernel executa `cli` + `hlt` (halts CPU).

#### Comando não reconhecido
```
MkM > xyz
Comando nao encontrado: xyz
MkM > 
```

### Entrada do Teclado

- **Caracteres alfanuméricos:** A-Z, a-z, 0-9
- **Símbolos:** `!@#$%^&*()-_=+[]{}';:",.<>?/\|~`` (com shift)
- **Especiais:**
  - **Enter** — Executar comando
  - **Backspace** — Apagar caractere anterior
  - **Shift** — Maiúsculas e símbolos alternativos

### Sair do QEMU

Pressione **Ctrl+A** seguido de **X**:
```
Ctrl+A
X
```

---

## 📁 Estrutura de Arquivos

```
ovsbMicroKernelMac/
├── Makefile                          # Build system
├── README.md                         # Este arquivo
│
├── kernel/
│   ├── boot/
│   │   ├── boot.asm                  # Bootloader Multiboot2 + GDT + paginação
│   │   ├── linker.ld                 # Script de linker
│   │   └── constants.asm             # (futuro) constantes compartilhadas
│   │
│   └── core/
│       └── kernel.c                  # Kernel principal (VGA + PS/2 + terminal)
│
├── scripts/
│   ├── run.sh                        # Script Linux/macOS
│   └── run.ps1                       # Script Windows PowerShell
│
├── build/
│   ├── boot.o                        # (gerado) Objeto boot
│   ├── kernel.o                      # (gerado) Objeto kernel
│   └── kernel.elf                    # (gerado) Binário executável
│
└── docs/
    └── PHASE1.md                     # Documentação detalhada
```

---

## 🔍 Detalhes Técnicos

### Multiboot2 Header

O bootloader começa com o header Multiboot2 que identifica o kernel para GRUB/QEMU:

```asm
; Magic number (0xE85250D6)
dd 0xE85250D6

; Arquitetura: i386 (0 = 32-bit, compatível com 64-bit)
dd 0

; Tamanho do header + checksum
dd header_end - header_start
dd -(magic + arch + size)

; Tags opcionais (framebuffer, etc.)
; ...
```

### Transição para 64-bit

1. **Habilitar PAE** (Physical Address Extension) via CR4
2. **Habilitar LME** (Long Mode Enable) via EFER MSR
3. **Habilitar paginação** via CR0.PG
4. **Carregar GDT** com descritores 64-bit
5. **Far jump** para seletor de código 64-bit

### Parser de Comandos

O kernel implementa um parser simples que:
1. Recebe string do buffer de teclado
2. Separa por espaços em branco
3. Extrai comando e argumentos
4. Procura em tabela de funções
5. Executa ou exibe erro

```c
typedef struct {
    const char *name;           /* "help", "echo", etc. */
    void (*handler)(void);      /* Função a executar */
} command_t;
```

---

## 🐛 Debugging

### Saída Serial

O kernel envia mensagens via serial (porta COM1) quando compilado com flags de debug:

```bash
# Executar com saída serial em arquivo
qemu-system-x86_64 -m 256M -kernel build/kernel.elf \
    -serial file:serial.log -no-reboot
```

### GDB Remote Debugging (futuro)

```bash
qemu-system-x86_64 -m 256M -kernel build/kernel.elf \
    -s -S -serial stdio
```

Depois em outro terminal:
```bash
gdb build/kernel.elf
target remote localhost:1234
```

---

## ⚠️ Limitações Conhecidas

1. **Sem suporte a interrupts** — Apenas polling de teclado
2. **Sem multitarefa** — Um thread linear
3. **Sem heap dinâmico** — Buffer de comando é fixo (256B)
4. **Sem proteção de memória** — Tudo roda em ring 0
5. **Sem drivers reais** — VGA e PS/2 mínimos apenas
6. **Sem suporte a interrupções de hardware** — IDT não configurada
7. **Sem sistema de arquivos** — Apenas shell em RAM

Estes limitações são intencionais na Fase 1. Serão abordadas nas fases seguintes.

---

## 📚 Próximos Passos (Fase 2+)

### Fase 2: Linguagem Proprietária
- Compilador que gera C a partir de sintaxe própria
- Transpiler com otimizador básico

### Fase 3: Microkernel Avançado
- Escalonador de tarefas preemptivo
- GDT/IDT completos com exceções
- Gerenciador de memória (buddy allocator)
- Heap dinâmico (kmalloc/kfree)

### Fase 4: IPC Mach
- Sistema de portas Mach
- Mensagens interprocess
- Memória compartilhada

### Fase 5: Carregador Mach-O
- Parser de binários macOS
- Dinâmica linker stub (dyld)
- Execução de aplicativos reais

---

## 📖 Referências

### Documentação
- **OSDev Wiki:** https://wiki.osdev.org/
- **x86-64 Manual:** https://www.amd.com/en/technologies/x86
- **Multiboot2 Spec:** https://www.gnu.org/software/grub/manual/multiboot2/
- **Intel 64 SDM:** https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html

### Ferramentas
- **NASM Manual:** https://www.nasm.us/xdocs/
- **GCC Manual:** https://gcc.gnu.org/onlinedocs/
- **QEMU Manual:** https://wiki.qemu.org/Manual

### Inspiração
- **Linux Kernel:** https://www.kernel.org/
- **Darling (macOS compat):** https://www.darlinghq.org/
- **Hackintosh/OpenCore:** https://dortania.github.io/

---

## ✅ Checklist de Verificação

Após compilação bem-sucedida, verifique:

- [ ] `make` executa sem erros
- [ ] `build/kernel.elf` existe e é > 10KB
- [ ] QEMU inicia kernel sem crash
- [ ] Prompt "MkM > " aparece
- [ ] Teclado funciona (letras aparecem)
- [ ] `help` lista comandos corretamente
- [ ] `echo Teste` ecoa "Teste"
- [ ] `clear` limpa a tela
- [ ] `about` mostra informações
- [ ] `shutdown` desliga (Ctrl+A, X para sair)
- [ ] Comando inválido exibe erro

---

## 🤝 Contribuindo

Para contribuir na Fase 1 ou fases posteriores:

1. Fork do projeto no GitHub
2. Crie uma branch: `git checkout -b feature/sua-feature`
3. Commit suas mudanças: `git commit -am 'Descrição clara'`
4. Push para a branch: `git push origin feature/sua-feature`
5. Abra um Pull Request

### Diretrizes
- Código limpo, comentado em português/inglês
- Nenhuma dependência externa (bare-metal)
- Testes manuais no QEMU
- Atualize documentação

---

## 📝 Licença

A definir (planejado código aberto). Veja `LICENSE` para detalhes.

---

## 🙏 Agradecimentos

Este projeto é inspirado em:
- **OSDev community** — educação em desenvolvimento de SO
- **Hackintosh projects** — compatibilidade macOS em x86
- **Darling project** — implementação de compatibilidade macOS open-source
- **XNU kernel** — arquitetura de microkernel

---

**Última atualização:** 2026-06-20  
**Status:** Funcionando! ✅
