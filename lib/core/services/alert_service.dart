import 'dart:io';
import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../features/home/domain/entities/home_data.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';


class AlertService {
  static DateTime? _lastOscillationAlertTime;
  static double? _lastChangeAmountChecked;
  
  
  static String _getAlertImagePath() {
    
    final exeDir = path.dirname(Platform.resolvedExecutable);
    
    
    
    final possiblePaths = [
      path.join(exeDir, 'data', 'flutter_assets', 'assets', 'icons', 'alerta.png'),
      path.join(exeDir, '..', 'data', 'flutter_assets', 'assets', 'icons', 'alerta.png'),
      path.join(exeDir, 'data', 'flutter_assets', 'alerta.png'),
    ];
    
    for (final imagePath in possiblePaths) {
      if (File(imagePath).existsSync()) {
        debugPrint('🖼️ Imagem de alerta encontrada: $imagePath');
        return imagePath;
      }
    }
    
    debugPrint('⚠️ Imagem de alerta não encontrada');
    debugPrint('   Diretório do executável: $exeDir');
    return '';
  }
  
  
  static Future<void> checkAlerts(BitcoinData bitcoinData) async {
    await _checkPriceAlerts(bitcoinData);
    await _checkOscillationAlert(bitcoinData);
  }
  
  
  static Future<void> _checkPriceAlerts(BitcoinData bitcoinData) async {
    final alertTargetFiat = await PreferencesService.getAlertTargetFiat();
    final currency = await PreferencesService.getSelectedCurrency();
    
    
    final currentPrice = bitcoinData.currentPrice;
    
    
    
    
    
    if (alertTargetFiat != null && alertTargetFiat > 0.0) {
      if (currentPrice >= alertTargetFiat) {
        final imagePath = _getAlertImagePath();
        
        await _triggerPriceAlert(
          'Alerta de Preço $currency',
          'Bitcoin atingiu ${Utility().priceToCurrency(currentPrice, fiat: currency)} (alvo: ${Utility().priceToCurrency(alertTargetFiat, fiat: currency)})',
          imagePath: imagePath,
        );
        
        
        final alertRecurring = await PreferencesService.getAlertRecurring();
        if (!alertRecurring) {
          
          await PreferencesService.setLastTriggeredAlertFiat(alertTargetFiat);
          await PreferencesService.setAlertTargetFiat(null);
        }
      }
    }
  }
  
  
  static Future<void> _checkOscillationAlert(BitcoinData bitcoinData) async {
    final alertOscillation = await PreferencesService.getAlertOscillation();
    
    
    if (alertOscillation == 0.0) {
      return;
    }
    
    final currentChangePercentage = bitcoinData.changePercentage;
    
    
    if (_lastChangeAmountChecked != null) {
      if ((currentChangePercentage - _lastChangeAmountChecked!).abs() < 0.1) {
        return; 
      }
    }
    
    _lastChangeAmountChecked = currentChangePercentage;
    
    
    if (alertOscillation < 0.0) {
      
      if (currentChangePercentage <= alertOscillation) {
        
        if (_shouldTriggerOscillationAlert()) {
          final imagePath = _getAlertImagePath();
          
          final changeFormatted = currentChangePercentage.toStringAsFixed(2);
          final targetFormatted = alertOscillation.toStringAsFixed(2);
          await _triggerOscillationAlert(
            'Alerta de Queda',
            'Bitcoin caiu $changeFormatted% (alvo: $targetFormatted%)',
            imagePath: imagePath,
          );
          _lastOscillationAlertTime = DateTime.now();
          
          
          final alertRecurring = await PreferencesService.getAlertRecurring();
          if (!alertRecurring) {
            await PreferencesService.setAlertOscillation(0.0);
            debugPrint('🔕 Alerta de oscilação removido (não recorrente)');
          }
        }
      }
    } else if (alertOscillation > 0.0) {
      
      if (currentChangePercentage >= alertOscillation) {
        
        if (_shouldTriggerOscillationAlert()) {
          final imagePath = _getAlertImagePath();
          
          final changeFormatted = '+${currentChangePercentage.toStringAsFixed(2)}';
          final targetFormatted = '+${alertOscillation.toStringAsFixed(2)}';
          await _triggerOscillationAlert(
            'Alerta de Alta',
            'Bitcoin subiu $changeFormatted% (alvo: $targetFormatted%)',
            imagePath: imagePath,
          );
          _lastOscillationAlertTime = DateTime.now();
          
          
          final alertRecurring = await PreferencesService.getAlertRecurring();
          if (!alertRecurring) {
            await PreferencesService.setAlertOscillation(0.0);
            debugPrint('🔕 Alerta de oscilação removido (não recorrente)');
          }
        }
      }
    }
  }
  
  
  static bool _shouldTriggerOscillationAlert() {
    if (_lastOscillationAlertTime == null) {
      return true;
    }
    
    
    final timeSinceLastAlert = DateTime.now().difference(_lastOscillationAlertTime!);
    return timeSinceLastAlert.inMinutes >= 5;
  }
  
  
  static Future<void> _triggerPriceAlert(String title, String message, {required String imagePath}) async {
    debugPrint('🔔 $title: $message');
    
    final showNotifications = await PreferencesService.getShowNotifications();
    if (showNotifications) {
      await NotificationService.showBitcoinAlert(
        title: title,
        message: message,
        imagePath: imagePath,
      );
    }
  }
  
  
  static Future<void> _triggerOscillationAlert(String title, String message, {required String imagePath}) async {
    debugPrint('📊 $title: $message');
    
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
