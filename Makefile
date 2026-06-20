# ============================================================================
# ovsbMicroKernelMac (MkM) - Makefile
# ============================================================================
# Arquivo: Makefile
# Descrição:
#   - Compila boot.asm (NASM → .o)
#   - Compila kernel.c (GCC → .o)
#   - Linka com linker.ld (LD → kernel.elf)
#   - Cria ISO bootável (GRUB)
#   - Executa no QEMU
# ============================================================================

# ============================================================================
# TOOLCHAIN
# ============================================================================

# Assembler (NASM)
NASM := nasm
NASM_FLAGS := -felf64 -F dwarf

# Compilador C (GCC)
CC := gcc
CFLAGS := -ffreestanding -fno-builtin -fno-stack-protector \
          -nostdlib -mno-red-zone -Wall -Wextra \
          -O2 -c

# Linker (GNU LD)
LD := ld
LD_FLAGS := -m elf_x86_64 -T kernel/boot/linker.ld --print-gc-sections

# QEMU
QEMU := qemu-system-x86_64
QEMU_FLAGS := -m 256M -kernel build/kernel.elf -serial stdio -no-reboot

# Diretórios
BUILD_DIR := build
KERNEL_DIR := kernel
OUTPUT := $(BUILD_DIR)/kernel.elf

# ============================================================================
# ARCHIVOS FONTE
# ============================================================================

BOOT_ASM := kernel/boot/boot.asm
KERNEL_C := kernel/core/kernel.c

# Objetos intermediários
BOOT_OBJ := $(BUILD_DIR)/boot.o
KERNEL_OBJ := $(BUILD_DIR)/kernel.o

# ============================================================================
# TARGETS
# ============================================================================

.PHONY: all clean run help

# Target padrão
all: $(OUTPUT)

# Compilar boot.asm
$(BOOT_OBJ): $(BOOT_ASM)
	@mkdir -p $(BUILD_DIR)
	@echo "[NASM] Compilando $(BOOT_ASM)..."
	$(NASM) $(NASM_FLAGS) -o $@ $<

# Compilar kernel.c
$(KERNEL_OBJ): $(KERNEL_C)
	@mkdir -p $(BUILD_DIR)
	@echo "[GCC] Compilando $(KERNEL_C)..."
	$(CC) $(CFLAGS) -o $@ $<

# Linkar em kernel.elf
$(OUTPUT): $(BOOT_OBJ) $(KERNEL_OBJ)
	@echo "[LD] Linkando para $(OUTPUT)..."
	$(LD) $(LD_FLAGS) -o $@ $(BOOT_OBJ) $(KERNEL_OBJ)
	@echo "[OK] Kernel construído com sucesso: $(OUTPUT)"
	@ls -lh $(OUTPUT)

# Executar no QEMU
run: $(OUTPUT)
	@echo "[QEMU] Inicializando kernel..."
	$(QEMU) $(QEMU_FLAGS)

# Limpeza
clean:
	@echo "[CLEAN] Removendo artefatos de build..."
	@rm -rf $(BUILD_DIR)

# Ajuda
help:
	@echo "ovsbMicroKernelMac (MkM) - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all   - Compilar kernel (padrão)"
	@echo "  make run   - Compilar e executar no QEMU"
	@echo "  make clean - Remover artefatos de build"
	@echo "  make help  - Mostrar esta mensagem"
	@echo ""
	@echo "Exemplos:"
	@echo "  make           # Apenas compilar"
	@echo "  make run       # Compilar e executar"
	@echo "  make clean all # Limpar e recompilar tudo"
	@echo ""
	@echo "Requisitos:"
	@echo "  - NASM (assembler)"
	@echo "  - GCC (compilador C)"
	@echo "  - GNU LD (linker)"
	@echo "  - QEMU (emulador)"
