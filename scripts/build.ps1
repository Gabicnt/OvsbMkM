# Build script for MkM
Set-Location C:\ovsbMicroKernelMac

Write-Host "Compilando bootloader..." -ForegroundColor Cyan
nasm -f bin -o build\bootloader.bin src\boot\bootloader.asm
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Compilando kernel..." -ForegroundColor Cyan
nasm -f bin -o build\kernel.bin src\kernel\kernel.asm
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Gerando imagem de disco..." -ForegroundColor Cyan
cmd /c "copy /b build\bootloader.bin + build\kernel.bin build\disk.img" | Out-Null

Write-Host "Executando QEMU..." -ForegroundColor Green
qemu-system-x86_64 -drive format=raw,file=build\disk.img
