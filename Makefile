# ============================================================================
# ovsbMicroKernelMac (MkM) - Makefile (64-bit, GRUB, ISO)
# ============================================================================

NASM := nasm
NASM_FLAGS := -f elf64

CC := gcc
CFLAGS := -ffreestanding -nostdlib -mno-red-zone -mno-mmx -mno-sse \
          -mgeneral-regs-only -Wall -O0 -c

LD := ld
LDFLAGS := -T linker.ld

GRUB := grub-mkrescue
QEMU := qemu-system-x86_64

BUILD_DIR := build
ISO_DIR := iso
ISO := OvsbMkM.iso

BOOT_ASM := boot64.asm
KERNEL_C := kernel.c
LINKER := linker.ld

BOOT_OBJ := $(BUILD_DIR)/boot64.o
KERNEL_OBJ := $(BUILD_DIR)/kernel.o
KERNEL_ELF := $(BUILD_DIR)/kernel.elf

.PHONY: all iso run clean help

all: $(KERNEL_ELF)

$(BOOT_OBJ): $(BOOT_ASM)
	@mkdir -p $(BUILD_DIR)
	@echo "[NASM] Compilando bootloader..."
	$(NASM) $(NASM_FLAGS) -o $@ $<

$(KERNEL_OBJ): $(KERNEL_C)
	@mkdir -p $(BUILD_DIR)
	@echo "[GCC]  Compilando kernel..."
	$(CC) $(CFLAGS) -o $@ $<

$(KERNEL_ELF): $(BOOT_OBJ) $(KERNEL_OBJ) $(LINKER)
	@echo "[LD]   Linkando..."
	$(LD) $(LDFLAGS) -o $@ $(BOOT_OBJ) $(KERNEL_OBJ)
	@echo "[OK]   Kernel: $(KERNEL_ELF)"

iso: $(KERNEL_ELF)
	@echo "[ISO]  Criando ISO..."
	@cp $(KERNEL_ELF) $(ISO_DIR)/boot/
	@$(GRUB) -o $(ISO) $(ISO_DIR) 2>/dev/null
	@echo "[OK]   ISO: $(ISO)"

run: iso
	@echo "[QEMU] Iniciando..."
	$(QEMU) -cdrom $(ISO) -m 256M

clean:
	@echo "[CLEAN] Limpando..."
	@rm -rf $(BUILD_DIR) $(ISO)

help:
	@echo "OvsbMkM - Build System (64-bit)"
	@echo "  make        Compila kernel"
	@echo "  make iso    Cria ISO"
	@echo "  make run    Compila + ISO + QEMU"
	@echo "  make clean  Limpa tudo"
