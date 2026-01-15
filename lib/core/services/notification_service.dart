import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:win_toast/win_toast.dart';
import 'system_tray_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Serviço centralizado para gerenciar notificações do Windows
/// 
/// Fornece métodos para exibir diferentes tipos de notificações:
/// - Notificações de informação
/// - Notificações de sucesso
/// - Notificações de alerta
/// - Notificações de erro
/// - Notificações personalizadas
class NotificationService {
  static bool _isInitialized = false;
  static String _iconPath = '';
  
  // Callback para quando a notificação é clicada
  static Function(String?)? onNotificationClicked;
  
  // Callback para quando a notificação é dispensada
  static Function(String?)? onNotificationDismissed;

  /// Inicializa o serviço de notificações
  /// Deve ser chamado uma vez no início do app
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ [Notification] Serviço já inicializado');
      return;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Define o caminho do ícone (PNG funciona melhor com notificações do Windows)
        if (Platform.isWindows) {
          final exeDir = path.dirname(Platform.resolvedExecutable);
          // Tenta usar PNG primeiro (funciona melhor), depois ICO como fallback
          final pngPath = path.join(exeDir, 'data/flutter_assets/assets/icons/bcm-logo-circular.png');
          final icoPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon-circular.ico');
          
          // Verifica qual arquivo existe
          if (File(pngPath).existsSync()) {
            _iconPath = pngPath;
            print('🔧 [Notification] Usando ícone PNG: $_iconPath');
          } else if (File(icoPath).existsSync()) {
            _iconPath = icoPath;
            print('🔧 [Notification] Usando ícone ICO: $_iconPath');
          } else {
            print('⚠️ [Notification] Nenhum ícone encontrado, usando padrão');
          }
        }
        
        await WinToast.instance().initialize(
          appName: 'BTC Cycle Monitor',
          productName: 'BTC Cycle Monitor',
          companyName: 'BTC Cycle Monitor',
        );
        _isInitialized = true;
        print('✅ [Notification] Serviço inicializado com sucesso');
        print('💡 [Notification] O ícone do cabeçalho vem do ícone do executável .exe');
      } else {
        print('⚠️ [Notification] Plataforma não suportada');
      }
    } catch (e) {
      print('❌ [Notification] Erro ao inicializar: $e');
    }
  }

  /// Exibe uma notificação de informação (azul)
  static Future<void> showInfo({
    required String title,
    required String body,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Exibe uma notificação de sucesso (verde)
  static Future<void> showSuccess({
    required String title,
    required String body,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: '✅ $title',
      body: body,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Exibe uma notificação de alerta (amarelo/laranja)
  static Future<void> showWarning({
    required String title,
    required String body,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: '⚠️ $title',
      body: body,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Exibe uma notificação de erro (vermelho)
  static Future<void> showError({
    required String title,
    required String body,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: '❌ $title',
      body: body,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Exibe uma notificação sobre o Bitcoin
  static Future<void> showBitcoinAlert({
    required String title,
    required String message,
    String? imagePath,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: '₿ $title',
      body: message,
      imagePath: imagePath,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Exibe uma notificação de indicador técnico
  static Future<void> showIndicatorAlert({
    required String indicatorName,
    required String status,
    required String message,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    await _showNotification(
      title: '📊 $indicatorName - $status',
      body: message,
      silent: false,
      payload: payload,
      onClicked: onClicked,
    );
  }

  /// Método interno para exibir notificação
  /// 
  /// NOTA: O tempo que a notificação fica visível é controlado pelo Windows.
  /// Para alterar isso, o usuário pode ir em:
  /// Configurações > Sistema > Notificações > Tempo de exibição da notificação
  static Future<void> _showNotification({
    required String title,
    required String body,
    String? imagePath,
    bool silent = false,
    String? payload,
    Function(String?)? onClicked,
  }) async {
    if (!_isInitialized) {
      print('⚠️ [Notification] Tentando exibir notificação antes de inicializar');
      await initialize();
    }

    try {
      // Para Windows, usamos o WinToast
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Toca o som de notificação do Windows antes de mostrar o toast
        if (!silent) {
          try {
            // Tenta tocar o som padrão do Windows
            await SystemSound.play(SystemSoundType.tick);
          } catch (e) {
            print('⚠️ [Notification] Não foi possível tocar o som: $e');
          }
        }
        
        // Exibe a notificação do Windows
        // O tempo de exibição é controlado pelas configurações do Windows
        // Usa imageAndText04 para exibir imagem grande na lateral (hero image)
        final result = await WinToast.instance().showToast(
          type: ToastType.imageAndText04,
          title: title,
          subtitle: body,
          imagePath: imagePath ?? (_iconPath.isNotEmpty ? _iconPath : ''),
        );
        
        print('🔔 [Notification] Notificação Windows exibida: $title');
        if (imagePath != null) {
          print('🖼️ [Notification] Imagem customizada: $imagePath');
        } else if (_iconPath.isNotEmpty) {
          print('🖼️ [Notification] Ícone padrão: $_iconPath');
        }
        print('📊 [Notification] Evento recebido: $result');
        
        // Ativa o badge vermelho no tray icon
        await SystemTrayService.showBadge();
        
        // Processa o evento retornado
        if (result != null) {
          final resultString = result.toString();
          
          // Detecta clique na notificação (ActivatedEvent)
          if (resultString.contains('ActivatedEvent')) {
            print('✅ [Notification] Notificação foi CLICADA pelo usuário');
            
            // Remove o badge ao clicar na notificação
            await SystemTrayService.hideBadge();
            
            onClicked?.call(payload);
            onNotificationClicked?.call(payload);
          } 
          // Detecta quando a notificação foi dispensada (DismissedEvent)
          else if (resultString.contains('DismissedEvent')) {
            if (resultString.contains('userCanceled')) {
              print('⏹️ [Notification] Notificação foi FECHADA pelo usuário');
              
              // Remove o badge ao fechar a notificação
              await SystemTrayService.hideBadge();
            } else if (resultString.contains('timedOut')) {
              print('⏱️ [Notification] Notificação EXPIROU (tempo esgotado)');
              // Badge permanece quando expira, só remove se usuário interagir
            } else {
              print('⏹️ [Notification] Notificação foi DISPENSADA: $resultString');
              
              // Remove o badge em outros casos de dispensa
              await SystemTrayService.hideBadge();
            }
            onNotificationDismissed?.call(payload);
          }
        }
      } else {
        // Fallback para outras plataformas
        print('📢 NOTIFICAÇÃO: $title - $body');
      }
    } catch (e) {
      print('❌ [Notification] Erro ao exibir notificação: $e');
      // Fallback: print
      print('📢 NOTIFICAÇÃO: $title - $body');
    }
  }

  /// Cancela uma notificação específica
  static Future<void> cancel(int id) async {
    // WinToast não suporta cancelamento de notificações específicas
    print('⚠️ [Notification] Cancelamento não suportado no Windows');
  }

  /// Cancela todas as notificações
  static Future<void> cancelAll() async {
    // WinToast não suporta cancelamento de todas as notificações
    print('⚠️ [Notification] Cancelamento não suportado no Windows');
  }

  /// Verifica se as notificações estão habilitadas
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    // No Windows, geralmente estão sempre habilitadas
    return true;
  }

  /// Retorna instruções para configurar notificações persistentes no Windows
  static String getWindowsNotificationInstructions() {
    return '''
Para fazer as notificações ficarem visíveis por mais tempo no Windows:

1. Abra Configurações do Windows (Win + I)
2. Vá em Sistema > Notificações
3. Role até encontrar "BTC Cycle Monitor" na lista de apps
4. Clique em "BTC Cycle Monitor"
5. Ative "Mostrar banner de notificação"
6. Ative "Mostrar notificações na central de ações"
7. Para aumentar o tempo:
   - As notificações aparecem na "Central de Ações" (Win + A)
   - Lá elas ficam até você fechar manualmente
   - Configure a prioridade como "Alta" para manter na central por mais tempo

Dica: Clique no ícone de sino (Win + A) para ver todas as notificações.
''';
  }
}
