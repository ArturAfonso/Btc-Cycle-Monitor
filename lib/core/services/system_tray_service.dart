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

  
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint("🔧 Inicializando window manager...");
      
      
      await windowManager.ensureInitialized();

      
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden, 
        title: "BTC Cycle Monitor",
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      debugPrint("🔧 Inicializando system tray...");
      
      
      trayManager.addListener(_instance);
      windowManager.addListener(_instance);

      
      String iconPath = 'assets/icons/favicon.ico';
      String badgeIconPath = 'assets/icons/favicon-badge.ico';

      
      if (Platform.isWindows) {
        final exeDir = path.dirname(Platform.resolvedExecutable);
        iconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon.ico');
        badgeIconPath = path.join(exeDir, 'data/flutter_assets/assets/icons/favicon-badge.ico');
        debugPrint("🔧 Caminho do ícone Windows: $iconPath");
      }
      
      
      _normalIconPath = iconPath;
      _badgeIconPath = badgeIconPath;

      try {
        await trayManager.setIcon(iconPath);
        debugPrint("✅ Ícone favicon.ico carregado com sucesso!");
      } catch (e) {
        debugPrint("❌ Erro ao carregar ícone: $e");
        debugPrint("🔧 Tentando caminho alternativo...");
        
        
        try {
          await trayManager.setIcon('assets/icons/favicon.ico');
         
          debugPrint("✅ Ícone carregado com caminho alternativo!");
        } catch (e2) {
          debugPrint("❌ Erro no fallback: $e2");
        }
      }
      
      
      await trayManager.setToolTip("BTC Cycle Monitor - Bitcoin em tempo real");

      
      await _setupTrayMenu();

      _isInitialized = true;
      debugPrint("✅ System Tray inicializado com sucesso!");
      
    } catch (e) {
      debugPrint("❌ Erro ao inicializar System Tray: $e");
    }
  }

  
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

  
  static Future<void> updateTooltip(String price, String change) async {
    if (!_isInitialized) return;

    try {
      final tooltip = "Bitcoin: $price ($change)\nClique para abrir";
      await trayManager.setToolTip(tooltip);
      debugPrint("💰 Tooltip atualizado: $price ($change)");
    } catch (e) {
      debugPrint("❌ Erro ao atualizar tooltip: $e");
    }
  }

  
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
      debugPrint("❌ Erro ao atualizar menu: $e");
    }
  }

  
  static Future<void> minimizeToTray() async {
    try {
      await windowManager.hide();
      debugPrint("📦 Aplicativo minimizado para o system tray");
    } catch (e) {
      debugPrint("❌ Erro ao minimizar: $e");
    }
  }

  
  static Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      debugPrint("👁️ Janela restaurada");
    } catch (e) {
      debugPrint("❌ Erro ao mostrar janela: $e");
    }
  }

  
  @override
  void onTrayIconMouseDown() async {
    debugPrint("🔔 Clique no ícone do tray");
    
    
    await hideBadge();
    
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await minimizeToTray();
    } else {
      await showWindow();
    }
  }

  
  static Future<void> showBadge() async {
    if (!_isInitialized || _hasNotificationBadge) return;

    try {
      await trayManager.setIcon(_badgeIconPath);
      _hasNotificationBadge = true;
      debugPrint("🔴 Badge de notificação ATIVADO no tray icon");
    } catch (e) {
      debugPrint("❌ Erro ao mostrar badge: $e");
      
      try {
        await trayManager.setIcon('assets/icons/favicon-badge.ico');
        _hasNotificationBadge = true;
        debugPrint("🔴 Badge ativado com caminho alternativo");
      } catch (e2) {
        debugPrint("❌ Erro no fallback do badge: $e2");
      }
    }
  }

  
  static Future<void> hideBadge() async {
    if (!_isInitialized || !_hasNotificationBadge) return;

    try {
      await trayManager.setIcon(_normalIconPath);
      _hasNotificationBadge = false;
      debugPrint("⚪ Badge de notificação REMOVIDO do tray icon");
    } catch (e) {
      debugPrint("❌ Erro ao esconder badge: $e");
      
      try {
        await trayManager.setIcon('assets/icons/favicon.ico');
        _hasNotificationBadge = false;
        debugPrint("⚪ Badge removido com caminho alternativo");
      } catch (e2) {
        debugPrint("❌ Erro no fallback ao remover badge: $e2");
      }
    }
  }

  
  static bool get hasBadge => _hasNotificationBadge;

  
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    debugPrint("� Menu clicado: ${menuItem.key}");
    switch (menuItem.key) {
      case 'show':
        await showWindow();
        break;
      case 'refresh':
        debugPrint("🔄 Refresh solicitado via tray");
        
        break;
      case 'exit':
        await dispose();
        await windowManager.close();
        break;
    }
  }

  
  @override
  void onWindowMinimize() async {
    debugPrint("📦 Janela minimizada - ocultando da barra de tarefas");
    await windowManager.hide();
  }

  
  static Future<void> dispose() async {
    try {
      await trayManager.destroy();
      trayManager.removeListener(_instance);
      windowManager.removeListener(_instance);
      
      _isInitialized = false;
      
      debugPrint("🧹 System Tray limpo");
    } catch (e) {
      debugPrint("❌ Erro ao limpar: $e");
    }
  }
}