% ============================================================================
% ovsbMicroKernelMac (MkM) - SAÍDA ESPERADA
% ============================================================================
% Arquivo: docs/EXPECTED_OUTPUT.md
% Descrição: Screenshots e exemplos de saída terminal esperada
% ============================================================================

# Saída Esperada - Terminal MkM Fase 1

Este documento mostra exatamente o que você deve ver ao executar o kernel.

---

## 🎯 Inicialização

### Ao Executar `make run` ou Script

**Terminal output (primeiros 2 segundos):**

```
[MkM] Compilando kernel MkM...
[MkM] Kernel compilado com sucesso!
[MkM] Iniciando QEMU...

=========================================
ovsbMicroKernelMac (MkM) Fase 1
=========================================

Kernel: build/kernel.elf
Memória: 256 MB

Comandos disponíveis:
  help, clear, echo, about, shutdown

Para sair do QEMU: Ctrl+A, depois X
=========================================

```

**Dentro do QEMU (na janela):**

```
MkM MicroKernel v0.1.0 Terminal inicializado. Digite 'help' para comandos.
MkM > █
```

O cursor piscará depois de `>`. Se vir isso, **kernel está funcional!** ✅

---

## 📖 Exemplos de Comandos

### 1. Comando: `help`

**Input:**
```
MkM > help
```

**Output esperada:**
```
Comandos disponiveis:
  help   - Mostra esta ajuda
  clear  - Limpa a tela
  echo   - Repete o texto digitado
  about  - Sobre o MkM
  shutdown - Desliga o sistema
MkM > 
```

**O que vira:** Lista formatada com 5 comandos disponíveis, depois novo prompt.

---

### 2. Comando: `echo`

#### Exemplo 1: Texto simples

**Input:**
```
MkM > echo Ola Mundo!
```

**Output esperada:**
```
Ola Mundo!
MkM > 
```

#### Exemplo 2: Múltiplas palavras

**Input:**
```
MkM > echo O MkM eh incrivel
```

**Output esperada:**
```
O MkM eh incrivel
MkM > 
```

#### Exemplo 3: Sem argumentos

**Input:**
```
MkM > echo
```

**Output esperada:**
```

MkM > 
```

(Nada impresso, apenas nova linha)

#### Exemplo 4: Com números

**Input:**
```
MkM > echo 12345
```

**Output esperada:**
```
12345
MkM > 
```

---

### 3. Comando: `about`

**Input:**
```
MkM > about
```

**Output esperada:**
```
ovsbMicroKernelMac (MkM) v0.1.0
Microkernel para executar binarios macOS
Alvo: High Sierra x86-64
Feito do zero, sem XNU

Arquitetura: 64-bit x86-64
Boot: Multiboot2
Fase: 1 (Terminal Interativo)
MkM > 
```

**Nota:** Exibe informações completas sobre o projeto em 7 linhas.

---

### 4. Comando: `clear`

**Antes:**
```
MkM > clear
MkM > help
Comandos disponiveis:
  help   - Mostra esta ajuda
  clear  - Limpa a tela
  echo   - Repete o texto digitado
  about  - Sobre o MkM
  shutdown - Desliga o sistema
MkM > _
```

**Depois de `clear`:**
```
MkM > 
```

A tela fica completamente vazia. Cursor volta ao topo esquerdo.

---

### 5. Comando: `shutdown`

**Input:**
```
MkM > shutdown
```

**Output esperada:**
```

Desligando...
```

Depois de 1 segundo, QEMU fecha e retorna ao terminal host.

---

### 6. Comando Inválido

**Input:**
```
MkM > xyz
```

**Output esperada:**
```
Comando nao encontrado: xyz
MkM > 
```

**Input:**
```
MkM > foobar arg1 arg2
```

**Output esperada:**
```
Comando nao encontrado: foobar
MkM > 
```

---

## ⌨️ Entrada do Teclado

### Digitação Normal

**Input:** Digite `echo test` lentamente

**Aparência na tela:**

```
MkM > e
MkM > ec
MkM > ech
MkM > echo
MkM > echo 
MkM > echo t
MkM > echo te
MkM > echo tes
MkM > echo test
```

Cada caractere aparece imediatamente após digitar.

### Backspace

**Input:** Digite `echo test`, depois Backspace 4 vezes

**Aparência:**

```
MkM > echo test████
MkM > echo tes
MkM > echo te
MkM > echo t
MkM > echo 
```

Cada backspace remove um caractere (mostra `\b \b` na tela).

### Enter

**Input:** Digite `help`, depois Enter

**Aparência:**

```
MkM > help█
[Enter]
Comandos disponiveis:
  help   - Mostra esta ajuda
  ...
MkM > 
```

Comando é executado, nova linha, novo prompt.

### Shift + Caracteres

**Input:** Tipo `HELLO` (com Caps Lock ou Shift)

**Aparência:**

```
MkM > HELLO
test output here
MkM > 
```

Letras maiúsculas aparecem normalmente.

**Input:** Digite `!@#$%` (Shift + números)

**Aparência:**

```
MkM > echo !@#$%
!@#$%
MkM > 
```

Símbolos aparecem corretamente.

---

## 🎬 Cenário Completo

Fluxo típico de uso:

```
MkM MicroKernel v0.1.0 Terminal inicializado. Digite 'help' para comandos.

MkM > help
Comandos disponiveis:
  help   - Mostra esta ajuda
  clear  - Limpa a tela
  echo   - Repete o texto digitado
  about  - Sobre o MkM
  shutdown - Desliga o sistema

MkM > about
ovsbMicroKernelMac (MkM) v0.1.0
Microkernel para executar binarios macOS
Alvo: High Sierra x86-64
Feito do zero, sem XNU

Arquitetura: 64-bit x86-64
Boot: Multiboot2
Fase: 1 (Terminal Interativo)

MkM > echo Teste do MkM funciona!
Teste do MkM funciona!

MkM > echo Vamos tentar algo mais longo
Vamos tentar algo mais longo

MkM > xyz
Comando nao encontrado: xyz

MkM > clear
[Tela limpa]

MkM > 

MkM > shutdown

Desligando...
[QEMU fecha após 1 segundo]
```

---

## 📊 Detalhes de Visualização

### Cores

- **Fundo:** Preto absoluto (`#000000`)
- **Texto:** Verde claro/brilhante (`#00FF00` ou similar)
- **Cursor:** Retângulo branco piscante (2Hz)

### Fonte

- Tipo: Monospace (VGA padrão)
- Tamanho: ~8x16 pixels por caractere (depende de QEMU)
- Resolução: 80 caracteres × 25 linhas

### Layout

```
┌────────────────────────────────────────────────────────────────────────────┐
│MkM MicroKernel v0.1.0 Terminal inicializado. Digite 'help' para comandos.  │
│MkM > █                                                                     │
│                                                                            │
│                                                                            │
│                                                                            │
│                         (22 linhas vazias)                                │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Nota:** Linhas 2-25 estão vazias (preenchidas com espaços pretos).

---

## 🔄 Scroll

Se digitar muitos `help` seguidos (saída > 23 linhas):

```
MkM > help
Comandos disponiveis:
  help   - Mostra esta ajuda
  clear  - Limpa a tela
  ...
MkM > help
Comandos disponiveis:
  help   - Mostra esta ajuda
  [primeira linha de help anterior desaparece]
  ...
```

Tela faz scroll (rola) para cima quando atinge linha 25. Funciona corretamente.

---

## ⚠️ Se NÃO Ver Isso

### Cenário 1: Tela Preta, Nada Aparece

**Significado:** Kernel provavelmente crashou antes de VGA ser inicializado.

**O que fazer:**
1. Verifique se `make` compilou sem erros
2. Verifique tamanho de `build/kernel.elf` (deve ser 10-20 KB)
3. Verifique se QEMU iniciou (deve abrir janela)
4. Recompile tudo: `make clean all`

**Se persistir:** Veja [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Cenário 2: Caracteres Aleatórios ou Lixo

**Significado:** VGA inicializado mas buffer corrompido.

**O que fazer:**
1. `clear` deve corrigir (telinha fica vazia)
2. Se não corrigir, problema com VGA buffer
3. Recompile: `make clean`

### Cenário 3: Prompt Aparece mas Teclado Não Responde

**Significado:** VGA OK, mas PS/2 travou.

**O que fazer:**
1. Tente digitar mesmo assim (às vezes delay)
2. Presione Ctrl+A, depois X para sair do QEMU
3. Verifique se driver PS/2 está correto
4. Veja [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Cenário 4: Teclado Funciona mas Comandos Aleatórios

**Significado:** PS/2 funciona, parser quebrado.

**O que fazer:**
1. Digite `help` — deve listar 5 comandos
2. Se não funciona, problema em execute_command()
3. Digite `clear` — deve limpar tela
4. Recompile e tente novamente

---

## 🎨 Variações Esperadas

Dependendo de QEMU/máquina, pode haver pequenas variações:

### Variação 1: Timing do Prompt

```
[Mais rápido]
MkM > █

[Mais lento]
MkM MicroKernel v0.1.0 Terminal inicializado. Digite 'help' para comandos.
MkM > █
```

Ambos são normais. Apenas timing diferente.

### Variação 2: Cursor

Pode aparecer como:
- Retângulo branco sólido
- Underscore `_` piscante
- Barra vertical `|`

Todas são válidas (depende de emulação VGA do QEMU).

### Variação 3: Cores

Se QEMU não emula cores VGA perfeitamente:
- Verde pode ser ligeiramente diferente
- Fundo pode não ser 100% preto
- Ainda é legível

Não é problema do kernel.

---

## 📋 Checklist de Verificação Visual

Ao executar `make run`, verifique:

- [ ] Janela QEMU abre em ~2 segundos
- [ ] Fundo é preto (não branco ou cinza)
- [ ] Texto é verde claro e legível
- [ ] Primeira linha é "MkM MicroKernel v0.1.0..."
- [ ] Segunda linha é "MkM > " com cursor
- [ ] Cursor pisca (não é estático)
- [ ] Teclado funciona (letra aparece ao digitar)
- [ ] Backspace apaga caracteres
- [ ] Enter executa comando
- [ ] `help` lista 5 comandos
- [ ] `echo teste` imprime "teste"
- [ ] `about` mostra 7 linhas de info
- [ ] `clear` limpa tela completamente
- [ ] `shutdown` fecha QEMU
- [ ] Nenhum erro ou crash

Se todos marcados: **Terminal está 100% correto! ✅**

---

**Última atualização:** 2026-06-20

Pronto para começar! 🚀
