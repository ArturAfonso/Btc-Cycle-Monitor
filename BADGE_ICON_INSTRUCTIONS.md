# INSTRUÇÕES PARA CRIAR O ÍCONE COM BADGE MANUALMENTE

## Opção 1: Usando um editor online (Recomendado)
1. Acesse: https://www.favicon-generator.org/ ou https://redketchup.io/icon-editor
2. Faça upload do arquivo `favicon.ico` de `assets/icons/`
3. Use a ferramenta de desenho para adicionar um círculo vermelho pequeno no canto superior direito
   - Cor: #FF0000 (vermelho puro)
   - Tamanho: aproximadamente 1/3 do tamanho total
   - Posição: canto superior direito
4. Exporte como favicon-badge.ico
5. Salve em `assets/icons/favicon-badge.ico`

## Opção 2: Usando Paint + Conversor Online
1. Abra `favicon.ico` no Paint do Windows
2. Desenhe um círculo vermelho pequeno no canto superior direito usando a ferramenta de elipse
   - Segure SHIFT para fazer um círculo perfeito
   - Use vermelho puro
3. Salve como PNG primeiro: `favicon-badge.png`
4. Acesse https://convertio.co/png-ico/ 
5. Converta o PNG para ICO
6. Salve como `favicon-badge.ico` em `assets/icons/`

## Opção 3: Copiar o ícone original temporariamente
Enquanto você não cria o ícone personalizado, vou copiar o ícone original
e o código vai funcionar (mas sem o badge visual ainda).

Execute no PowerShell:
```powershell
Copy-Item "assets\icons\favicon.ico" "assets\icons\favicon-badge.ico"
```

Depois você pode substituir por um ícone com o ponto vermelho desenhado.
