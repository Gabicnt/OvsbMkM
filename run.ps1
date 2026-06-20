# ============================================================================
# ovsbMicroKernelMac (MkM) - Script de Execução (Windows PowerShell)
# ============================================================================
# Arquivo: scripts/run.ps1
# Descrição: Build e executa o kernel no QEMU
# Uso: .\scripts\run.ps1 -Action [clean|build|run|all]
# ============================================================================

param(
    [string]$Action = "all"
)

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

function Print-Status {
    param([string]$Message)
    Write-Host "[MkM] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[AVISO] $Message" -ForegroundColor Yellow
}

function Check-Tool {
    param(
        [string]$ToolName,
        [string]$DownloadUrl
    )
    
    try {
        $output = & $ToolName --version 2>&1
        return $true
    } catch {
        Print-Error "$ToolName não encontrado!"
        Print-Error "Baixe em: $DownloadUrl"
        return $false
    }
}

# ============================================================================
# VERIFICAR REQUISITOS
# ============================================================================

function Verify-Requirements {
    Print-Status "Verificando requisitos..."
    
    $tools = @(
        @{name="nasm"; url="https://www.nasm.us/"},
        @{name="gcc"; url="https://mingw-w64.org/"},
        @{name="ld"; url="https://sourceware.org/binutils/"},
        @{name="qemu-system-x86_64"; url="https://www.qemu.org/download/"}
    )
    
    $all_ok = $true
    foreach ($tool in $tools) {
        if (-not (Check-Tool $tool.name $tool.url)) {
            $all_ok = $false
        }
    }
    
    if (-not $all_ok) {
        Print-Error "Requisitos não atendidos!"
        exit 1
    }
    
    Print-Status "Todos os requisitos OK!"
}

# ============================================================================
# COMPILAR
# ============================================================================

function Build-Kernel {
    Print-Status "Compilando kernel MkM..."
    
    # Limpar build anterior
    if (Test-Path "build") {
        Print-Status "Removendo build anterior..."
        Remove-Item -Recurse -Force "build"
    }
    
    # Criar diretório
    New-Item -ItemType Directory -Force -Path "build" | Out-Null
    
    # Compilar boot.asm
    Print-Status "Compilando boot.asm..."
    & nasm -felf64 -F dwarf -o "build/boot.o" "kernel/boot/boot.asm"
    if ($LASTEXITCODE -ne 0) {
        Print-Error "Falha ao compilar boot.asm!"
        exit 1
    }
    
    # Compilar kernel.c
    Print-Status "Compilando kernel.c..."
    & gcc -ffreestanding -fno-builtin -fno-stack-protector `
        -nostdlib -mno-red-zone -Wall -Wextra -O2 -c `
        -o "build/kernel.o" "kernel/core/kernel.c"
    if ($LASTEXITCODE -ne 0) {
        Print-Error "Falha ao compilar kernel.c!"
        exit 1
    }
    
    # Linkar
    Print-Status "Linkando kernel.elf..."
    & ld -m elf_x86_64 -T "kernel/boot/linker.ld" `
        -o "build/kernel.elf" "build/boot.o" "build/kernel.o"
    if ($LASTEXITCODE -ne 0) {
        Print-Error "Falha ao linkar kernel!"
        exit 1
    }
    
    # Verificar resultado
    if (Test-Path "build/kernel.elf") {
        Print-Status "Kernel compilado com sucesso!"
        $size = (Get-Item "build/kernel.elf").Length / 1KB
        Print-Status "Tamanho: $([Math]::Round($size, 2)) KB"
    } else {
        Print-Error "Falha na compilação!"
        exit 1
    }
}

# ============================================================================
# EXECUTAR
# ============================================================================

function Run-Kernel {
    if (-not (Test-Path "build/kernel.elf")) {
        Print-Warning "Kernel não encontrado, compilando..."
        Build-Kernel
    }
    
    Print-Status "Iniciando QEMU..."
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "ovsbMicroKernelMac (MkM) Fase 1" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Kernel: build/kernel.elf"
    Write-Host "Memória: 256 MB"
    Write-Host ""
    Write-Host "Comandos disponíveis:"
    Write-Host "  help, clear, echo, about, shutdown"
    Write-Host ""
    Write-Host "Para sair do QEMU: Ctrl+A, depois X"
    Write-Host "=========================================`n"
    
    & qemu-system-x86_64 `
        -m 256M `
        -kernel "build/kernel.elf" `
        -serial stdio `
        -no-reboot `
        -display none
    
    Print-Status "QEMU encerrado."
}

# ============================================================================
# LIMPEZA
# ============================================================================

function Clean-Build {
    Print-Status "Limpando build..."
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
    }
    Print-Status "Limpeza concluída."
}

# ============================================================================
# MAIN
# ============================================================================

Verify-Requirements

switch ($Action.ToLower()) {
    "build" {
        Build-Kernel
    }
    "run" {
        Run-Kernel
    }
    "all" {
        Build-Kernel
        Run-Kernel
    }
    "clean" {
        Clean-Build
    }
    default {
        Write-Host "ovsbMicroKernelMac (MkM) - Build & Run Script"
        Write-Host ""
        Write-Host "Uso: .\scripts\run.ps1 -Action [build|run|all|clean]"
        Write-Host ""
        Write-Host "Exemplos:"
        Write-Host "  .\scripts\run.ps1 -Action build  # Apenas compilar"
        Write-Host "  .\scripts\run.ps1 -Action run    # Apenas executar"
        Write-Host "  .\scripts\run.ps1                # Compilar e executar (padrão)"
        Write-Host "  .\scripts\run.ps1 -Action clean  # Limpar build"
        exit 1
    }
}
