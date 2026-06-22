# OvsbMkM

Status: Work-in-progress kernel prototype (64-bit). Key subsystems implemented:
- Basic VGA terminal
- PS/2 keyboard driver and IRQ handling
- Basic IDT and PIC initialization
- Minimal syscall handler and stubs
- Simple memory manager and Mach-O loader prototype

Build & Run

```
make clean && make
make run    # boots in QEMU
```

Project layout

- `src/kernel/` — kernel sources (memory, mach_o, smc, nvram, pic)
- `src/drivers/` — drivers (keyboard)
- `boot64.asm`, `linker.ld`, `idt.*`, `syscall_entry.asm`, `Makefile`

Next steps

- Replace `test_macho` with a real Mach-O blob and improve loader
- Implement more BSD syscalls and process execution
- Add VFS and userspace support

If you want a clean commit, review changes and then run `git add . && git commit -m "Cleanup and docs"`.
# ovsbMicroKernelMac (MkM) - Fase 1: Terminal Interativo 64-bit

**Versão:** 0.10.0  
**Data:** 2026-06-21  
**Autor:** BugsAppettit  
**Status:** ✅ Funcional — Terminal 64-bit com GRUB + Multiboot2

---

## 📋 Visão Geral

A **Fase 1 do MkM** é um kernel bare-metal **x86-64** que demonstra os conceitos fundamentais de um sistema operacional moderno:

✅ **Boot via GRUB + Multiboot2** — ISO bootável (QEMU e hardware real)  
✅ **64-bit Long Mode** — Transição manual 32→64-bit  
✅ **Driver VGA** — Terminal de texto (80×25, cores)  
✅ **Driver PS/2** — Teclado com suporte básico (shift em breve)  
✅ **Terminal Interativo** — Shell com prompt "MkM> " e parser de comandos  
✅ **Comandos Internos** — `help`, `clear`, `echo`, `about`, `shutdown`  

### Tamanho
- **Kernel:** ~22 KB (ELF64)
- **RAM mínima:** 256 MB
- **ISO:** ~9 MB

---

## 🏗️ Arquitetura Técnica

### Fluxo de Inicialização

```
1. QEMU/PC carrega GRUB da ISO
   ↓
2. GRUB carrega kernel.elf (Multiboot2) em 0x100000 (1 MB)
   ↓
3. Bootloader (boot64.asm) configura:
   - PAE (Physical Address Extension)
   - PML4/PDP/PD (paginação identity mapping 1 GB)
   - EFER.LME (Long Mode Enable)
   - GDT 64-bit (code + data)
   ↓
4. Far jump para 64-bit mode
   ↓
5. Chamar kmain() em C
   ↓
6. Inicializar driver VGA + PS/2
   ↓
7. Loop do terminal interativo
```

### Estrutura de Memória

```
0x00000000 ┌──────────────────────┐
           │ IVT + BDA (BIOS)     │
0x00007C00 ├──────────────────────┤
           │ GRUB (stage 1)       │
0x00010000 ├──────────────────────┤
           │ GRUB (stage 2)       │
0x00100000 ├──────────────────────┤ ← Kernel (1 MB)
           │ .multiboot (header)  │
           │ .text (código)       │
           │ .rodata (strings)    │
           │ .data (variáveis)    │
           │ .paging (PML4/PDP/PD)│
           │ .bss (buffer, stack) │
0x00104000 ├──────────────────────┤
           │ Livre                │
0xFFFFFFFF └──────────────────────┘
```

---

## 💻 Compilação

### Requisitos (Linux — ambiente nativo)

| Ferramenta | Versão Mín. | Instalação |
|---|---|---|
| **NASM** | 2.15 | `sudo apt install nasm` |
| **GCC** | 9.0 | `sudo apt install gcc` |
| **GNU LD** | 2.35 | `sudo apt install binutils` |
| **GRUB** | 2.0 | `sudo apt install grub-pc-bin` |
| **Xorriso** | 1.0 | `sudo apt install xorriso` |
| **QEMU** | 5.0 | `sudo apt install qemu-system-x86` |

### Instalação Rápida (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y nasm gcc binutils grub-pc-bin xorriso qemu-system-x86
```

---

## 🚀 Build e Execução

### Makefile (Recomendado)

```bash
make          # Compila o kernel
make iso      # Cria a ISO bootável
make run      # Compila + ISO + QEMU (tudo em um)
make clean    # Limpa arquivos gerados
make help     # Mostra ajuda
```

### Manual (Passo a Passo)

```bash
# Compilar
nasm -f elf64 -o build/boot64.o boot64.asm
gcc -ffreestanding -nostdlib -mno-red-zone -mno-mmx -mno-sse -mgeneral-regs-only -Wall -O0 -c -o build/kernel.o kernel.c
ld -T linker.ld -o build/kernel.elf build/boot64.o build/kernel.o

# Criar ISO
cp build/kernel.elf iso/boot/
grub-mkrescue -o OvsbMkM.iso iso/ 2>/dev/null

# Executar
qemu-system-x86_64 -cdrom OvsbMkM.iso -m 256M
```

---

## 🎮 Uso do Terminal

### Saída Esperada

```
OvsbMkM 64-bit Terminal v3.0
Digite 'help'

MkM> 
```

### Comandos Disponíveis

| Comando | Ação |
|---------|------|
| `help` | Lista comandos |
| `clear` | Limpa a tela |
| `echo <texto>` | Repete o texto |
| `about` | Informações do sistema |
| `shutdown` | Para a CPU (`cli; hlt`) |

### Exemplos

```
MkM> help
help, clear, echo, about, shutdown

MkM> about
OvsbMkM 64-bit
Microkernel macOS High Sierra

MkM> echo Ola Mundo!
Ola Mundo!

MkM> clear

MkM> shutdown
Desligando...
```

### Teclado

- **Enter:** Executa comando
- **Backspace:** Apaga caractere
- **Letras:** Minúsculas (shift em breve)
- **Números:** 0-9

---

## 📁 Estrutura de Arquivos

```
OvsbMkM/
├── boot64.asm              # Bootloader Multiboot2 + transição 64-bit
├── kernel.c                # Terminal interativo 64-bit
├── linker.ld               # Linker script
├── Makefile                # Build system
├── iso/
│   └── boot/
│       └── grub/
│           └── grub.cfg    # Configuração do GRUB
├── build/
│   ├── boot64.o
│   ├── kernel.o
│   └── kernel.elf
├── OvsbMkM.iso             # ISO bootável
├── README.md               # Este arquivo
├── ARCHITECTURE_PHASE1.md  # Detalhes técnicos
├── EXPECTED_OUTPUT.md      # Saída esperada
├── QUICKSTART.md           # Guia rápido
└── TROUBLESHOOTING.md      # Solução de problemas
```

---

## ⚠️ Limitações Conhecidas

1. **Sem IDT** — Exceções causam Triple Fault
2. **Sem shift** — Apenas letras minúsculas
3. **Sem multitarefa** — Único fluxo de execução
4. **Sem sistema de arquivos** — Shell em RAM
5. **Sem proteção de memória** — Tudo em Ring 0
6. **Sem heap dinâmico** — Buffer fixo (256 B)

---

## 📚 Próximos Passos

### Fase 2 (Imediato)
- IDT para tratamento de exceções
- Suporte a shift (maiúsculas/símbolos)
- Histórico de comandos
- Cores no terminal

### Fase 3
- Escalonador de tarefas
- Gerenciador de memória (kmalloc/kfree)
- Heap dinâmico

### Fase 4
- IPC Mach (portas, mensagens)
- Memória compartilhada

### Fase 5
- Carregador de binários Mach-O
- Syscalls BSD essenciais

### Fase 6+
- Drivers reais (AHCI, USB, rede)
- Port do Mesa (OpenGL)
- Interface gráfica (WindowServer)

---

## 📖 Referências

- **OSDev Wiki:** https://wiki.osdev.org/
- **Multiboot2 Spec:** https://www.gnu.org/software/grub/manual/multiboot2/
- **Intel 64 Manual:** https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
- **Repositório:** https://github.com/Gabicnt/OvsbMkM

---

## ✅ Checklist de Verificação

- [x] `boot64.asm` compila sem erros
- [x] `kernel.c` compila sem erros
- [x] `build/kernel.elf` gerado
- [x] ISO bootável criada
- [x] QEMU inicia sem crash
- [x] Prompt "MkM> " aparece
- [x] Teclado funciona
- [x] `help` lista comandos
- [x] `echo` repete texto
- [x] `clear` limpa tela
- [x] `about` mostra informações
- [x] `shutdown` para CPU
- [x] Comando inválido mostra erro

---

**Última atualização:** 2026-06-21 — Terminal 64-bit funcional! 🚀  
**Status:** ✅ Rodando no QEMU (Linux) | ✅ Base para próximas fases