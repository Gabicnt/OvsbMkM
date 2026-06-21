cd ~/OvsbMkM

# Verificar o que mudou
git status

# Adicionar todos os arquivos
git add -A

# Fazer o commit
git commit -m "Fase 1: Terminal 64-bit funcional com GRUB + Multiboot2

- Bootloader 64-bit (boot64.asm) com transição manual
- Kernel C 64-bit (kernel.c) com terminal interativo
- Linker script (linker.ld) com seção .paging
- Makefile para build, ISO e QEMU
- Documentação atualizada (README, arquitetura, saída esperada)
- Removidos arquivos antigos (16-bit, testes, Windows)"

# Enviar para o GitHub
git push origin main