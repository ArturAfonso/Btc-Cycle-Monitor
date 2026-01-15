# 🔴 CRIAR ÍCONE COM BADGE - GUIA RÁPIDO

## Método Mais Simples (Recomendado):

### Passo 1: Abrir arquivo no Paint
```powershell
mspaint assets\icons\bcm-logo-circular.png
```

### Passo 2: Desenhar o Badge
1. No Paint, clique em **"Formas"** → Selecione **"Elipse/Círculo"**
2. Selecione **"Contorno sólido"** (sem contorno, só preenchimento)
3. Escolha a cor **VERMELHA PURA** (R:255, G:0, B:0)
4. Segure **SHIFT** e desenhe um círculo pequeno no **canto superior direito**
   - Tamanho: aproximadamente 1/4 do tamanho total da imagem
   - Posição: bem no cantinho, com pequena margem

### Passo 3: Salvar
1. Clique em **Arquivo** → **Salvar como** → **PNG**
2. Nome: `bcm-logo-circular-badge.png`
3. Local: `assets\icons\`

### Passo 4: Converter para ICO
**Opção A - Online (Mais fácil):**
1. Abra: https://convertio.co/pt/png-ico/
2. Faça upload do arquivo `bcm-logo-circular-badge.png`
3. Clique em **Converter**
4. Baixe o arquivo `.ico` gerado
5. Renomeie para `favicon-badge.ico`
6. Mova para `assets\icons\`

**Opção B - Usar ferramenta:**
```powershell
# Se tiver ImageMagick instalado:
magick convert assets\icons\bcm-logo-circular-badge.png -define icon:auto-resize=256,128,64,48,32,16 assets\icons\favicon-badge.ico
```

---

## Método Alternativo - Usar Ferramenta Online:

1. Acesse: https://www.favicon-generator.org/
2. Upload do `favicon.ico` ou `bcm-logo-circular.png`
3. Use o editor para adicionar um círculo vermelho
4. Baixe como `favicon-badge.ico`
5. Salve em `assets\icons\`

---

## TESTE RÁPIDO:

Depois de criar o ícone, teste:

```powershell
# Execute o app
flutter run -d windows

# Clique no botão "Teste Notificação"
# Observe o ícone do tray mudar
```

---

## Dica Visual:

O badge deve parecer assim:
```
┌─────────────┐
│ 🪙       🔴 │  <- Círculo vermelho pequeno no canto
│             │
│    LOGO     │
│             │
│             │
└─────────────┘
```

Tamanho do badge: ~25-30% do tamanho total
Posição: canto superior direito, com 2-3px de margem
