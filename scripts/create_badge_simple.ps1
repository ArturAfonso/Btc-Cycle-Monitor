# Script simplificado para criar ícone com badge
# Carrega a maior resolução disponível do ícone

Add-Type -AssemblyName System.Drawing

$assetsDir = "C:\flutterProjects\btc_cycle_monitor\assets\icons"
$inputIcon = Join-Path $assetsDir "favicon.ico"
$outputIcon = Join-Path $assetsDir "favicon-badge.ico"

Write-Host "Criando icone com badge..." -ForegroundColor Cyan

try {
    # Carrega o ícone e pega todos os tamanhos disponíveis
    $iconBytes = [System.IO.File]::ReadAllBytes($inputIcon)
    $ms = New-Object System.IO.MemoryStream(,$iconBytes)
    $icon = [System.Drawing.Icon]::new($ms)
    
    # Tenta obter o bitmap de 32x32 ou o maior disponível
    $sizes = @(256, 128, 64, 48, 32, 24, 16)
    $bitmap = $null
    
    foreach ($size in $sizes) {
        try {
            $bitmap = [System.Drawing.Icon]::new($icon, $size, $size).ToBitmap()
            $width = $bitmap.Width
            $height = $bitmap.Height
            Write-Host "Usando tamanho: ${width}x${height}px" -ForegroundColor Green
            break
        } catch {
            continue
        }
    }
    
    if ($bitmap -eq $null) {
        # Fallback: usa o bitmap direto
        $bitmap = $icon.ToBitmap()
        $width = $bitmap.Width
        $height = $bitmap.Height
    }
    
    # Cria novo bitmap
    $newBitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Desenha ícone original
    $graphics.DrawImage($bitmap, 0, 0, $width, $height)
    
    # Calcula badge
    $badgeSize = [Math]::Max([Math]::Floor($width / 3), 6)
    $badgeX = $width - $badgeSize - 1
    $badgeY = 1
    
    # Desenha badge com borda branca
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $graphics.FillEllipse($whiteBrush, $badgeX - 1, $badgeY - 1, $badgeSize + 2, $badgeSize + 2)
    
    # Círculo vermelho
    $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 220, 0, 0))
    $graphics.FillEllipse($redBrush, $badgeX, $badgeY, $badgeSize, $badgeSize)
    
    # Converte para ICO
    $iconHandle = $newBitmap.GetHicon()
    $newIcon = [System.Drawing.Icon]::FromHandle($iconHandle)
    
    # Salva
    $stream = [System.IO.FileStream]::new($outputIcon, [System.IO.FileMode]::Create)
    $newIcon.Save($stream)
    $stream.Close()
    
    # Limpa
    $graphics.Dispose()
    $newBitmap.Dispose()
    $bitmap.Dispose()
    $icon.Dispose()
    $ms.Dispose()
    $whiteBrush.Dispose()
    $redBrush.Dispose()
    $newIcon.Dispose()
    
    Write-Host "SUCESSO! Icone criado: $outputIcon" -ForegroundColor Green
    Write-Host "Badge vermelho adicionado no canto superior direito" -ForegroundColor Yellow
    
} catch {
    Write-Host "Erro: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
