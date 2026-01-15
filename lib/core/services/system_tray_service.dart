import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  static bool _isInitialized = false;
  static bool _hasNotificationBadge = false;
  static String _normalIconPath = '';
  static String _badgeIconPath = '';

  SystemTrayService._internal();

  factory SystemTrayService() => _instance;

  /// Inicializa o system tray e window manager
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("🔧 Inicializando window manager...");
      
      // Inicializa o window manager
      await windowManager.ensureInitialized();

      // Configura a janela
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden, // Esconde barra nativa, usa customizada
        title: "BTC Cycle Monitor",
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      print("🔧 Inicializando system tray...");
      
      // Configura listeners
      trayManager.addListener(_instance);
      windowManager.addListener(_instance);

      // Caminho para o ícone .ico (solução Windows)
      String iconPath = 'assets/icons/favicon.ico';
      String badgeIconPath = 'assets/icons/favicon-badge.ico';

      // No Windows, usar caminho absoluto conforme documentação
      if (Platform.isWindows) {
        final exeDir = path.dirname(Platform.resolvedExecutable);
        iconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon.ico');
        badgeIconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon-badge.ico');
        print("🔧 Caminho do ícone Windows: $iconPath");
      }
      
      // Salva os caminhos para uso posterior
      _normalIconPath = iconPath;
      _badgeIconPath = badgeIconPath;

      try {
        await trayManager.setIcon(iconPath);
        print("✅ Ícone favicon.ico carregado com sucesso!");
      } catch (e) {
        print("❌ Erro ao carregar ícone: $e");
        print("🔧 Tentando caminho alternativo...");
        
        // Fallback: tenta caminho direto
        try {
          await trayManager.setIcon('assets/icons/favicon.ico');
         // await trayManager.setIcon('assets/icons/favicon-circular32px.ico');
          print("✅ Ícone carregado com caminho alternativo!");
        } catch (e2) {
          print("❌ Erro no fallback: $e2");
        }
      }
      
      // Configura tooltip
      await trayManager.setToolTip("BTC Cycle Monitor - Bitcoin em tempo real");

      // Configura menu de contexto
      await _setupTrayMenu();

      _isInitialized = true;
      print("✅ System Tray inicializado com sucesso!");
      
    } catch (e) {
      print("❌ Erro ao inicializar System Tray: $e");
    }
  }

  /// Configura o menu de contexto do tray
  static Future<void> _setupTrayMenu() async {
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Mostrar App',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'price',
          label: 'Bitcoin: Carregando...',
          disabled: true,
        ),
        MenuItem(
          key: 'change',
          label: 'Variação: --',
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'refresh',
          label: 'Atualizar Dados',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Sair',
        ),
      ],
    ));
  }

  /// Atualiza o tooltip com preço atual
  static Future<void> updateTooltip(String price, String change) async {
    if (!_isInitialized) return;

    try {
      final tooltip = "Bitcoin: $price ($change)\nClique para abrir";
      await trayManager.setToolTip(tooltip);
      print("💰 Tooltip atualizado: $price ($change)");
    } catch (e) {
      print("❌ Erro ao atualizar tooltip: $e");
    }
  }

  /// Atualiza o menu com informações do preço
  static Future<void> updateMenuPrice(String price, String change) async {
    if (!_isInitialized) return;

    try {
      await trayManager.setContextMenu(Menu(
        items: [
          MenuItem(
            key: 'show',
            label: 'Mostrar App',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'price',
            label: 'Bitcoin: $price',
            disabled: true,
          ),
          MenuItem(
            key: 'change',
            label: 'Variação: $change',
            disabled: true,
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'refresh',
            label: 'Atualizar Dados',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit',
            label: 'Sair',
          ),
        ],
      ));
    } catch (e) {
      print("❌ Erro ao atualizar menu: $e");
    }
  }

  /// Minimiza para o tray
  static Future<void> minimizeToTray() async {
    try {
      await windowManager.hide();
      print("📦 Aplicativo minimizado para o system tray");
    } catch (e) {
      print("❌ Erro ao minimizar: $e");
    }
  }

  /// Mostra a janela
  static Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      print("👁️ Janela restaurada");
    } catch (e) {
      print("❌ Erro ao mostrar janela: $e");
    }
  }

  /// Callback quando clica no ícone do tray
  @override
  void onTrayIconMouseDown() async {
    print("🔔 Clique no ícone do tray");
    
    // Remove o badge ao clicar no ícone
    await hideBadge();
    
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await minimizeToTray();
    } else {
      await showWindow();
    }
  }

  /// Mostra o badge de notificação no ícone do tray
  static Future<void> showBadge() async {
    if (!_isInitialized || _hasNotificationBadge) return;

    try {
      await trayManager.setIcon(_badgeIconPath);
      _hasNotificationBadge = true;
      print("🔴 Badge de notificação ATIVADO no tray icon");
    } catch (e) {
      print("❌ Erro ao mostrar badge: $e");
      // Fallback: tenta caminho direto
      try {
        await trayManager.setIcon('assets/icons/favicon-badge.ico');
        _hasNotificationBadge = true;
        print("🔴 Badge ativado com caminho alternativo");
      } catch (e2) {
        print("❌ Erro no fallback do badge: $e2");
      }
    }
  }

  /// Esconde o badge de notificação do ícone do tray
  static Future<void> hideBadge() async {
    if (!_isInitialized || !_hasNotificationBadge) return;

    try {
      await trayManager.setIcon(_normalIconPath);
      _hasNotificationBadge = false;
      print("⚪ Badge de notificação REMOVIDO do tray icon");
    } catch (e) {
      print("❌ Erro ao esconder badge: $e");
      // Fallback: tenta caminho direto
      try {
        await trayManager.setIcon('assets/icons/favicon.ico');
        _hasNotificationBadge = false;
        print("⚪ Badge removido com caminho alternativo");
      } catch (e2) {
        print("❌ Erro no fallback ao remover badge: $e2");
      }
    }
  }

  /// Verifica se o badge está ativo
  static bool get hasBadge => _hasNotificationBadge;

  /// Callback quando clica em item do menu
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    print("� Menu clicado: ${menuItem.key}");
    switch (menuItem.key) {
      case 'show':
        await showWindow();
        break;
      case 'refresh':
        print("🔄 Refresh solicitado via tray");
        // TODO: Implementar callback para refresh
        break;
      case 'exit':
        await dispose();
        await windowManager.close();
        break;
    }
  }

  /// Callback quando janela é minimizada
  @override
  void onWindowMinimize() async {
    print("📦 Janela minimizada - ocultando da barra de tarefas");
    await windowManager.hide();
  }

  /// Limpa recursos
  static Future<void> dispose() async {
    try {
      await trayManager.destroy();
      trayManager.removeListener(_instance);
      windowManager.removeListener(_instance);
      
      _isInitialized = false;
      
      print("🧹 System Tray limpo");
    } catch (e) {
      print("❌ Erro ao limpar: $e");
    }
  }
}