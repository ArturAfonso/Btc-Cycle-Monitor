# Script PowerShell para criar um ícone com badge de notificação
# Usa System.Drawing do .NET Framework

Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$assetsDir = Join-Path $projectDir "assets\icons"

$inputIcon = Join-Path $assetsDir "favicon.ico"
$outputIcon = Join-Path $assetsDir "favicon-badge.ico"

Write-Host "Criando icone com badge de notificacao..." -ForegroundColor Cyan
Write-Host ("=" * 60)
Write-Host "Diretorio do projeto: $projectDir"
Write-Host "Lendo icone original: $inputIcon"

try {
    # Carrega o ícone original
    $icon = [System.Drawing.Icon]::new($inputIcon)
    $bitmap = $icon.ToBitmap()
    
    # Cria um novo bitmap com o mesmo tamanho
    $width = $bitmap.Width
    $height = $bitmap.Height
    $newBitmap = New-Object System.Drawing.Bitmap($width, $height)
    
    # Cria objeto Graphics para desenhar
    $graphics = [System.Drawing.Graphics]::FromImage($newBitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Desenha o ícone original
    $graphics.DrawImage($bitmap, 0, 0, $width, $height)
    
    # Calcula tamanho e posição do badge
    $badgeSize = [Math]::Max([Math]::Floor($width / 3), 8)
    $badgeX = $width - $badgeSize - 2
    $badgeY = 2
    
    # Desenha borda branca
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $graphics.FillEllipse($whiteBrush, $badgeX - 1, $badgeY - 1, $badgeSize + 2, $badgeSize + 2)
    
    # Desenha círculo vermelho
    $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::Red)
    $graphics.FillEllipse($redBrush, $badgeX, $badgeY, $badgeSize, $badgeSize)
    
    # Salva como PNG temporário
    $tempPng = Join-Path $assetsDir "temp-badge.png"
    $newBitmap.Save($tempPng, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Converte PNG para ICO usando o mesmo método do ícone original
    # Carrega o PNG
    $pngBitmap = [System.Drawing.Bitmap]::new($tempPng)
    
    # Cria o ícone a partir do bitmap
    $iconHandle = $pngBitmap.GetHicon()
    $newIcon = [System.Drawing.Icon]::FromHandle($iconHandle)
    
    # Salva como .ico
    $stream = [System.IO.FileStream]::new($outputIcon, [System.IO.FileMode]::Create)
    $newIcon.Save($stream)
    $stream.Close()
    
    # Limpa recursos
    $graphics.Dispose()
    $newBitmap.Dispose()
    $bitmap.Dispose()
    $icon.Dispose()
    $whiteBrush.Dispose()
    $redBrush.Dispose()
    $pngBitmap.Dispose()
    $newIcon.Dispose()
    
    # Remove arquivo temporário
    Remove-Item $tempPng -ErrorAction SilentlyContinue
    
    Write-Host "Icone com badge criado com sucesso: $outputIcon" -ForegroundColor Green
    Write-Host "Tamanho: ${width}x${height}px"
    Write-Host "Badge: ${badgeSize}px no canto superior direito"
    
} catch {
    Write-Host "Erro ao criar icone: $_" -ForegroundColor Red
    Write-Host "Certifique-se de que o arquivo favicon.ico existe em assets/icons/" -ForegroundColor Yellow
}
