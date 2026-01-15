import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;


class IconGeneratorService {
  static const int iconSize = 32; 
  
  
  static Future<String> generateBitcoinIcon({
    required String price,
    String? baseIconPath,
  }) async {
    try {
      debugPrint("🎨 Gerando ícone Bitcoin com badge de preço: $price");
      
      
      img.Image? baseImage;
      
      if (Platform.isWindows) {
        final exeDir = path.dirname(Platform.resolvedExecutable);
        final originalIconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon.ico');
       
        
        try {
          final iconFile = File(originalIconPath);
          if (await iconFile.exists()) {
            final iconBytes = await iconFile.readAsBytes();
            baseImage = img.decodeImage(iconBytes);
            debugPrint("✅ Ícone original carregado: $originalIconPath");
          }
        } catch (e) {
          debugPrint("⚠️ Erro ao carregar ícone original: $e");
        }
      }
      
      
      if (baseImage == null) {
        baseImage = _createBitcoinIcon();
        debugPrint("🎨 Ícone Bitcoin azul criado como fallback");
      }
      
      
      if (baseImage.width != iconSize || baseImage.height != iconSize) {
        baseImage = img.copyResize(baseImage, width: iconSize, height: iconSize);
      }
      
      
      _addVisiblePriceBadge(baseImage, price);
      
      
      final tempDir = Directory.systemTemp;
      final iconPath = path.join(tempDir.path, 'btc_tray_${DateTime.now().millisecondsSinceEpoch}.ico');
      
      
      final icoBytes = _convertToIco(baseImage);
      await File(iconPath).writeAsBytes(icoBytes);
      
      debugPrint("✅ Badge adicionado ao ícone: $iconPath");
      return iconPath;
      
    } catch (e) {
      debugPrint("❌ Erro ao gerar ícone: $e");
      rethrow;
    }
  }
  
  
  static img.Image _createBitcoinIcon() {
    final image = img.Image(width: iconSize, height: iconSize);
    
    
    img.fill(image, color: img.ColorRgb8(33, 150, 243)); 
    
    
    img.fillCircle(image, 
      x: iconSize ~/ 2, 
      y: iconSize ~/ 2, 
      radius: (iconSize ~/ 2) - 2,
      color: img.ColorRgb8(33, 150, 243),
    );
    
    
    img.drawCircle(image,
      x: iconSize ~/ 2,
      y: iconSize ~/ 2, 
      radius: (iconSize ~/ 2) - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
    
    
    _drawSimpleBitcoinSymbol(image);
    
    return image;
  }
  
  
  static void _drawSimpleBitcoinSymbol(img.Image image) {
    final white = img.ColorRgb8(255, 255, 255);
    
    
    final centerX = iconSize ~/ 2;
    final centerY = iconSize ~/ 2;
    
    
    for (int y = centerY - 8; y < centerY + 8; y++) {
      image.setPixel(centerX - 4, y, white);
    }
    
    
    for (int x = centerX - 4; x < centerX + 2; x++) {
      image.setPixel(x, centerY - 6, white); 
      image.setPixel(x, centerY, white);     
      image.setPixel(x, centerY + 6, white); 
    }
    
    
    image.setPixel(centerX + 1, centerY - 4, white);
    image.setPixel(centerX + 1, centerY - 2, white);
    image.setPixel(centerX + 1, centerY + 2, white);
    image.setPixel(centerX + 1, centerY + 4, white);
  }
  
  
  static void _addVisiblePriceBadge(img.Image image, String price) {
    
    final simplifiedPrice = _simplifyPrice(price);
    
    
    final badgeSize = 24; 
    final badgeHeight = 16; 
    final badgeX = iconSize - badgeSize;
    final badgeY = 0; 
    
    
    final badgeColor = price.contains('-') 
        ? img.ColorRgb8(255, 0, 0)     
        : img.ColorRgb8(0, 255, 0);    
    
    
    for (int x = badgeX; x < iconSize; x++) {
      for (int y = badgeY; y < badgeY + badgeHeight && y < iconSize; y++) {
        image.setPixel(x, y, badgeColor);
      }
    }
    
    
    
    for (int x = badgeX; x < iconSize; x++) {
      image.setPixel(x, badgeY, img.ColorRgb8(0, 0, 0)); 
      if (badgeY + 1 < iconSize) image.setPixel(x, badgeY + 1, img.ColorRgb8(0, 0, 0)); 
      if (badgeY + badgeHeight - 1 < iconSize) image.setPixel(x, badgeY + badgeHeight - 1, img.ColorRgb8(0, 0, 0)); 
      if (badgeY + badgeHeight - 2 < iconSize) image.setPixel(x, badgeY + badgeHeight - 2, img.ColorRgb8(0, 0, 0)); 
    }
    
    for (int y = badgeY; y < badgeY + badgeHeight && y < iconSize; y++) {
      image.setPixel(badgeX, y, img.ColorRgb8(0, 0, 0)); 
      if (badgeX + 1 < iconSize) image.setPixel(badgeX + 1, y, img.ColorRgb8(0, 0, 0)); 
      image.setPixel(iconSize - 1, y, img.ColorRgb8(0, 0, 0)); 
      if (iconSize - 2 >= 0) image.setPixel(iconSize - 2, y, img.ColorRgb8(0, 0, 0)); 
    }
    
    
    _drawBigContrastText(image, simplifiedPrice, badgeX + 3, badgeY + 3);
    
    debugPrint("🎯 Badge GRANDE adicionado: $simplifiedPrice (${badgeSize}x${badgeHeight}px)");
  }
  
  
  static void _drawBigContrastText(img.Image image, String text, int x, int y) {
    final black = img.ColorRgb8(0, 0, 0); 
    
    
    for (int i = 0; i < text.length && i < 3; i++) {
      final charX = x + (i * 6); 
      
      
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
    
    debugPrint("📝 Texto GRANDE desenhado: '$text' em $x,$y");
  }
  
  
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
  
  
  static Uint8List _convertToIco(img.Image image) {
    
    final pngBytes = img.encodePng(image);
    
    
    final ico = BytesBuilder();
    
    
    ico.add([0, 0]); 
    ico.add([1, 0]); 
    ico.add([1, 0]); 
    
    
    ico.addByte(32);          
    ico.addByte(32);          
    ico.addByte(0);           
    ico.addByte(0);           
    ico.add([1, 0]);          
    ico.add([32, 0]);         
    
    
    final size = pngBytes.length;
    ico.addByte(size & 0xFF);
    ico.addByte((size >> 8) & 0xFF);
    ico.addByte((size >> 16) & 0xFF);
    ico.addByte((size >> 24) & 0xFF);
    
    
    final offset = 6 + 16;
    ico.addByte(offset & 0xFF);
    ico.addByte((offset >> 8) & 0xFF);
    ico.addByte((offset >> 16) & 0xFF);
    ico.addByte((offset >> 24) & 0xFF);
    
    
    ico.add(pngBytes);
    
    return ico.toBytes();
  }
  
  
  static Future<void> cleanupOldIcons() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('btc_tray_') && file.path.endsWith('.ico')) {
          try {
            await file.delete();
          } catch (e) {
            
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Erro na limpeza: $e");
    }
  }
}