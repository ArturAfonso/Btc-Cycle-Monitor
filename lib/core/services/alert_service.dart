import 'dart:io';
import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:path/path.dart' as path;

import '../../features/home/domain/entities/home_data.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

/// Serviço responsável por verificar e disparar alertas
class AlertService {
  static DateTime? _lastOscillationAlertTime;
  static double? _lastChangeAmountChecked;
  
  /// Obtém o caminho absoluto da imagem de alerta
  static String _getAlertImagePath() {
    // Tenta encontrar a imagem no diretório de assets
    final exeDir = path.dirname(Platform.resolvedExecutable);
    
    // Em Debug, as imagens ficam em: build\windows\x64\runner\Debug\data\flutter_assets\assets\icons\
    // Em Release, as imagens ficam em: build\windows\x64\runner\Release\data\flutter_assets\assets\icons\
    final possiblePaths = [
      path.join(exeDir, 'data', 'flutter_assets', 'assets', 'icons', 'alerta.png'),
      path.join(exeDir, '..', 'data', 'flutter_assets', 'assets', 'icons', 'alerta.png'),
      path.join(exeDir, 'data', 'flutter_assets', 'alerta.png'),
    ];
    
    for (final imagePath in possiblePaths) {
      if (File(imagePath).existsSync()) {
        print('🖼️ Imagem de alerta encontrada: $imagePath');
        return imagePath;
      }
    }
    
    print('⚠️ Imagem de alerta não encontrada');
    print('   Diretório do executável: $exeDir');
    return '';
  }
  
  /// Verifica os alertas baseado nos dados do Bitcoin
  static Future<void> checkAlerts(BitcoinData bitcoinData) async {
    await _checkPriceAlerts(bitcoinData);
    await _checkOscillationAlert(bitcoinData);
  }
  
  /// Verifica alertas de preço (BTC ou Fiat)
  static Future<void> _checkPriceAlerts(BitcoinData bitcoinData) async {
    final alertTargetFiat = await PreferencesService.getAlertTargetFiat();
    final currency = await PreferencesService.getSelectedCurrency();
    
    // O currentPrice já vem na moeda selecionada nas preferências
    final currentPrice = bitcoinData.currentPrice;
    
    // TODO: Implementar alerta de BTC quando tivermos API que retorna preço em BTC
    // Por enquanto, só suportamos alertas em moeda Fiat
    
    // Verifica alerta de Fiat
    if (alertTargetFiat != null && alertTargetFiat > 0.0) {
      if (currentPrice >= alertTargetFiat) {
        final imagePath = _getAlertImagePath();
        
        await _triggerPriceAlert(
          'Alerta de Preço $currency',
          'Bitcoin atingiu ${Utility().priceToCurrency(currentPrice, fiat: currency)} (alvo: ${Utility().priceToCurrency(alertTargetFiat, fiat: currency)})',
          imagePath: imagePath,
        );
        
        // Remove o alerta após disparar apenas se não for recorrente
        final alertRecurring = await PreferencesService.getAlertRecurring();
        if (!alertRecurring) {
          // Salva o último alerta disparado antes de remover
          await PreferencesService.setLastTriggeredAlertFiat(alertTargetFiat);
          await PreferencesService.setAlertTargetFiat(null);
        }
      }
    }
  }
  
  /// Verifica alertas de oscilação
  static Future<void> _checkOscillationAlert(BitcoinData bitcoinData) async {
    final alertOscillation = await PreferencesService.getAlertOscillation();
    
    // Se o alerta está desativado (0.0), não faz nada
    if (alertOscillation == 0.0) {
      return;
    }
    
    final currentChangePercentage = bitcoinData.changePercentage;
    
    // Evita alertas repetitivos - verifica se mudou significativamente
    if (_lastChangeAmountChecked != null) {
      if ((currentChangePercentage - _lastChangeAmountChecked!).abs() < 0.1) {
        return; // Mudança muito pequena, não verifica
      }
    }
    
    _lastChangeAmountChecked = currentChangePercentage;
    
    // Verifica se atingiu a oscilação alvo
    if (alertOscillation < 0.0) {
      // Alerta de queda
      if (currentChangePercentage <= alertOscillation) {
        // Evita alertas repetitivos - só alerta uma vez por período
        if (_shouldTriggerOscillationAlert()) {
          final imagePath = _getAlertImagePath();
          // Formata com sinal negativo
          final changeFormatted = currentChangePercentage.toStringAsFixed(2);
          final targetFormatted = alertOscillation.toStringAsFixed(2);
          await _triggerOscillationAlert(
            'Alerta de Queda',
            'Bitcoin caiu $changeFormatted% (alvo: $targetFormatted%)',
            imagePath: imagePath,
          );
          _lastOscillationAlertTime = DateTime.now();
          
          // Remove o alerta após disparar apenas se não for recorrente
          final alertRecurring = await PreferencesService.getAlertRecurring();
          if (!alertRecurring) {
            await PreferencesService.setAlertOscillation(0.0);
            print('🔕 Alerta de oscilação removido (não recorrente)');
          }
        }
      }
    } else if (alertOscillation > 0.0) {
      // Alerta de alta
      if (currentChangePercentage >= alertOscillation) {
        // Evita alertas repetitivos - só alerta uma vez por período
        if (_shouldTriggerOscillationAlert()) {
          final imagePath = _getAlertImagePath();
          // Formata com sinal positivo
          final changeFormatted = '+${currentChangePercentage.toStringAsFixed(2)}';
          final targetFormatted = '+${alertOscillation.toStringAsFixed(2)}';
          await _triggerOscillationAlert(
            'Alerta de Alta',
            'Bitcoin subiu $changeFormatted% (alvo: $targetFormatted%)',
            imagePath: imagePath,
          );
          _lastOscillationAlertTime = DateTime.now();
          
          // Remove o alerta após disparar apenas se não for recorrente
          final alertRecurring = await PreferencesService.getAlertRecurring();
          if (!alertRecurring) {
            await PreferencesService.setAlertOscillation(0.0);
            print('🔕 Alerta de oscilação removido (não recorrente)');
          }
        }
      }
    }
  }
  
  /// Verifica se deve disparar alerta de oscilação (evita spam)
  static bool _shouldTriggerOscillationAlert() {
    if (_lastOscillationAlertTime == null) {
      return true;
    }
    
    // Só permite novo alerta após 5 minutos
    final timeSinceLastAlert = DateTime.now().difference(_lastOscillationAlertTime!);
    return timeSinceLastAlert.inMinutes >= 5;
  }
  
  /// Dispara notificação de alerta de preço
  static Future<void> _triggerPriceAlert(String title, String message, {required String imagePath}) async {
    print('🔔 $title: $message');
    
    final showNotifications = await PreferencesService.getShowNotifications();
    if (showNotifications) {
      await NotificationService.showBitcoinAlert(
        title: title,
        message: message,
        imagePath: imagePath,
      );
    }
  }
  
  /// Dispara notificação de alerta de oscilação
  static Future<void> _triggerOscillationAlert(String title, String message, {required String imagePath}) async {
    print('📊 $title: $message');
    
    final showNotifications = await PreferencesService.getShowNotifications();
    if (showNotifications) {
      await NotificationService.showBitcoinAlert(
        title: title,
        message: message,
        imagePath: imagePath,
      );
    }
  }
}
