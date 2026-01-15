import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Serviço para gerar ícones dinâmicos do system tray com texto sobreposto
class IconGeneratorService {
  static const int iconSize = 32; // Tamanho padrão para system tray
  
  /// Gera um ícone .ico com o preço do Bitcoin sobreposto
  static Future<String> generateBitcoinIcon({
    required String price,
    String? baseIconPath,
  }) async {
    try {
      print("🎨 Gerando ícone Bitcoin com badge de preço: $price");
      
      // Tenta carregar o ícone original primeiro
      img.Image? baseImage;
      
      if (Platform.isWindows) {
        final exeDir = path.dirname(Platform.resolvedExecutable);
        final originalIconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon.ico');
       // final originalIconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon-circular.ico');
        
        try {
          final iconFile = File(originalIconPath);
          if (await iconFile.exists()) {
            final iconBytes = await iconFile.readAsBytes();
            baseImage = img.decodeImage(iconBytes);
            print("✅ Ícone original carregado: $originalIconPath");
          }
        } catch (e) {
          print("⚠️ Erro ao carregar ícone original: $e");
        }
      }
      
      // Se não conseguir carregar o original, cria um ícone azul do Bitcoin
      if (baseImage == null) {
        baseImage = _createBitcoinIcon();
        print("🎨 Ícone Bitcoin azul criado como fallback");
      }
      
      // Redimensiona para 32x32 se necessário
      if (baseImage.width != iconSize || baseImage.height != iconSize) {
        baseImage = img.copyResize(baseImage, width: iconSize, height: iconSize);
      }
      
      // Adiciona badge DE PREÇO VISÍVEL por cima
      _addVisiblePriceBadge(baseImage, price);
      
      // Salva como arquivo temporário
      final tempDir = Directory.systemTemp;
      final iconPath = path.join(tempDir.path, 'btc_tray_${DateTime.now().millisecondsSinceEpoch}.ico');
      
      // Converte para ICO
      final icoBytes = _convertToIco(baseImage);
      await File(iconPath).writeAsBytes(icoBytes);
      
      print("✅ Badge adicionado ao ícone: $iconPath");
      return iconPath;
      
    } catch (e) {
      print("❌ Erro ao gerar ícone: $e");
      rethrow;
    }
  }
  
  /// Cria ícone Bitcoin azul (versão original)
  static img.Image _createBitcoinIcon() {
    final image = img.Image(width: iconSize, height: iconSize);
    
    // Fundo azul Bitcoin (cor original)
    img.fill(image, color: img.ColorRgb8(33, 150, 243)); // Azul Material
    
    // Círculo azul Bitcoin
    img.fillCircle(image, 
      x: iconSize ~/ 2, 
      y: iconSize ~/ 2, 
      radius: (iconSize ~/ 2) - 2,
      color: img.ColorRgb8(33, 150, 243),
    );
    
    // Borda branca
    img.drawCircle(image,
      x: iconSize ~/ 2,
      y: iconSize ~/ 2, 
      radius: (iconSize ~/ 2) - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
    
    // Símbolo Bitcoin branco
    _drawSimpleBitcoinSymbol(image);
    
    return image;
  }
  
  /// Desenha símbolo Bitcoin simplificado
  static void _drawSimpleBitcoinSymbol(img.Image image) {
    final white = img.ColorRgb8(255, 255, 255);
    
    // Desenha "₿" simples usando linhas
    final centerX = iconSize ~/ 2;
    final centerY = iconSize ~/ 2;
    
    // Linha vertical principal do B
    for (int y = centerY - 8; y < centerY + 8; y++) {
      image.setPixel(centerX - 4, y, white);
    }
    
    // Linhas horizontais do B
    for (int x = centerX - 4; x < centerX + 2; x++) {
      image.setPixel(x, centerY - 6, white); // Topo
      image.setPixel(x, centerY, white);     // Meio  
      image.setPixel(x, centerY + 6, white); // Base
    }
    
    // Linhas verticais direitas
    image.setPixel(centerX + 1, centerY - 4, white);
    image.setPixel(centerX + 1, centerY - 2, white);
    image.setPixel(centerX + 1, centerY + 2, white);
    image.setPixel(centerX + 1, centerY + 4, white);
  }
  
  /// Adiciona badge MUITO VISÍVEL com preço
  static void _addVisiblePriceBadge(img.Image image, String price) {
    // Simplifica o preço
    final simplifiedPrice = _simplifyPrice(price);
    
    // Badge MUITO MAIOR - ocupa quase metade do ícone
    final badgeSize = 24; // Aumentado de 18 para 24
    final badgeHeight = 16; // Altura específica
    final badgeX = iconSize - badgeSize;
    final badgeY = 0; // Topo da imagem
    
    // Cor MUITO CONTRASTANTE baseada no preço
    final badgeColor = price.contains('-') 
        ? img.ColorRgb8(255, 0, 0)     // VERMELHO FORTE
        : img.ColorRgb8(0, 255, 0);    // VERDE FORTE
    
    // FUNDO SÓLIDO do badge (retângulo MAIOR)
    for (int x = badgeX; x < iconSize; x++) {
      for (int y = badgeY; y < badgeY + badgeHeight && y < iconSize; y++) {
        image.setPixel(x, y, badgeColor);
      }
    }
    
    // BORDA PRETA DUPLA para máximo destaque
    // Borda horizontal
    for (int x = badgeX; x < iconSize; x++) {
      image.setPixel(x, badgeY, img.ColorRgb8(0, 0, 0)); // Topo
      if (badgeY + 1 < iconSize) image.setPixel(x, badgeY + 1, img.ColorRgb8(0, 0, 0)); // Topo duplo
      if (badgeY + badgeHeight - 1 < iconSize) image.setPixel(x, badgeY + badgeHeight - 1, img.ColorRgb8(0, 0, 0)); // Base
      if (badgeY + badgeHeight - 2 < iconSize) image.setPixel(x, badgeY + badgeHeight - 2, img.ColorRgb8(0, 0, 0)); // Base dupla
    }
    // Borda vertical
    for (int y = badgeY; y < badgeY + badgeHeight && y < iconSize; y++) {
      image.setPixel(badgeX, y, img.ColorRgb8(0, 0, 0)); // Esquerda
      if (badgeX + 1 < iconSize) image.setPixel(badgeX + 1, y, img.ColorRgb8(0, 0, 0)); // Esquerda dupla
      image.setPixel(iconSize - 1, y, img.ColorRgb8(0, 0, 0)); // Direita
      if (iconSize - 2 >= 0) image.setPixel(iconSize - 2, y, img.ColorRgb8(0, 0, 0)); // Direita dupla
    }
    
    // TEXTO MAIOR E MAIS GROSSO
    _drawBigContrastText(image, simplifiedPrice, badgeX + 3, badgeY + 3);
    
    print("🎯 Badge GRANDE adicionado: $simplifiedPrice (${badgeSize}x${badgeHeight}px)");
  }
  
  /// Desenha texto GRANDE e GROSSO (máximo contraste)
  static void _drawBigContrastText(img.Image image, String text, int x, int y) {
    final black = img.ColorRgb8(0, 0, 0); // PRETO para contraste máximo
    
    // Desenha texto MUITO MAIOR e MAIS GROSSO
    for (int i = 0; i < text.length && i < 3; i++) {
      final charX = x + (i * 6); // Espaçamento MAIOR entre caracteres
      
      // Desenha um padrão 4x8 pixels para cada caractere (MUITO MAIOR)
      for (int dx = 0; dx < 4; dx++) {
        for (int dy = 0; dy < 8; dy++) {
          final pixelX = charX + dx;
          final pixelY = y + dy;
          if (pixelX < iconSize && pixelY < iconSize) {
            image.setPixel(pixelX, pixelY, black);
          }
        }
      }
    }
    
    print("📝 Texto GRANDE desenhado: '$text' em $x,$y");
  }
  
  /// Simplifica o preço para display
  static String _simplifyPrice(String price) {
    String clean = price.replaceAll('\$', '').replaceAll(',', '').trim();
    
    try {
      double value = double.parse(clean);
      
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    } catch (e) {
      return clean.length > 3 ? clean.substring(0, 3) : clean;
    }
  }
  
  /// Converte para formato ICO (versão simplificada)
  static Uint8List _convertToIco(img.Image image) {
    // Para Windows, vamos usar PNG dentro do container ICO
    final pngBytes = img.encodePng(image);
    
    // Header ICO básico
    final ico = BytesBuilder();
    
    // ICO Header (6 bytes)
    ico.add([0, 0]); // Reserved
    ico.add([1, 0]); // Type: ICO  
    ico.add([1, 0]); // Number of images
    
    // Image Directory Entry (16 bytes)
    ico.addByte(32);          // Width
    ico.addByte(32);          // Height
    ico.addByte(0);           // Color palette
    ico.addByte(0);           // Reserved
    ico.add([1, 0]);          // Color planes
    ico.add([32, 0]);         // Bits per pixel
    
    // Size of PNG data (4 bytes, little endian)
    final size = pngBytes.length;
    ico.addByte(size & 0xFF);
    ico.addByte((size >> 8) & 0xFF);
    ico.addByte((size >> 16) & 0xFF);
    ico.addByte((size >> 24) & 0xFF);
    
    // Offset (4 bytes, little endian)
    final offset = 6 + 16;
    ico.addByte(offset & 0xFF);
    ico.addByte((offset >> 8) & 0xFF);
    ico.addByte((offset >> 16) & 0xFF);
    ico.addByte((offset >> 24) & 0xFF);
    
    // PNG data
    ico.add(pngBytes);
    
    return ico.toBytes();
  }
  
  /// Limpa ícones temporários
  static Future<void> cleanupOldIcons() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('btc_tray_') && file.path.endsWith('.ico')) {
          try {
            await file.delete();
          } catch (e) {
            // Ignora erros
          }
        }
      }
    } catch (e) {
      print("⚠️ Erro na limpeza: $e");
    }
  }
}