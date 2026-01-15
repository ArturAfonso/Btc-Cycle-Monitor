import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'core/services/system_tray_service.dart';
import 'core/services/notification_service.dart';
import 'core/preferences/preferences_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/cubit/home_state.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa todos os locales necessários para formatação de moeda
  await initializeDateFormatting();
  
  // Inicializa o serviço de notificações
  await NotificationService.initialize();
  
  // Configuração da janela - SEMPRE maximizada ao iniciar
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Remove barra de título padrão
    windowButtonVisibility: false, // Remove botões padrão
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize(); // 🚀 SEMPRE MAXIMIZADO AO INICIAR!
  });
  
  // Inicializa todas as dependências
  await initializeDependencies();
  
  // System tray será inicializado após o app estar rodando
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<PreferencesCubit>()..loadPreferences(),
        ),
        BlocProvider(
          create: (context) => sl<HomeCubit>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Conecta o callback para refresh automático quando moeda mudar
          final preferencesCubit = context.read<PreferencesCubit>();
          preferencesCubit.onCurrencyChanged = (currency) {
            final homeCubit = context.read<HomeCubit>();
            homeCubit.refreshDataWithCurrency(currency);
          };
          
          return MaterialApp(
            title: 'BTC Cycle Monitor',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Força tema escuro
            home: const WindowLifecycleWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Wrapper para gerenciar o ciclo de vida da janela e system tray
class WindowLifecycleWrapper extends StatefulWidget {
  const WindowLifecycleWrapper({super.key});

  @override
  State<WindowLifecycleWrapper> createState() => _WindowLifecycleWrapperState();
}

class _WindowLifecycleWrapperState extends State<WindowLifecycleWrapper>
    with WidgetsBindingObserver {
  late HomeCubit homeCubit;

  @override
  void initState() {
    super.initState();
    homeCubit = context.read<HomeCubit>();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicializa o system tray após a primeira renderização
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeSystemTray();
    });
    
    // Escuta mudanças no estado para atualizar o system tray
    homeCubit.stream.listen((state) {
      _updateSystemTray(state);
    });
  }

  /// Inicializa o system tray de forma segura
  Future<void> _initializeSystemTray() async {
    try {
      await SystemTrayService.initialize();
      print("✅ System Tray inicializado com sucesso após primeiro frame");
    } catch (e) {
      print("❌ Erro ao inicializar System Tray: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemTrayService.dispose();
    super.dispose();
  }

  /// Atualiza o system tray com informações do Bitcoin
  void _updateSystemTray(HomeState state) {
    if (state is HomeLoaded && state.data.bitcoinData != null) {
      final bitcoinData = state.data.bitcoinData!;
      final price = '\$${bitcoinData.currentPrice.toStringAsFixed(2)}';
      final change = '${bitcoinData.changePercentage >= 0 ? '+' : ''}${bitcoinData.changePercentage.toStringAsFixed(2)}%';
      
      // Atualiza tooltip e menu do system tray
      SystemTrayService.updateTooltip(price, change);
      SystemTrayService.updateMenuPrice(price, change);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        homeCubit.restartAutoRefresh();
        print('🔄 App resumed - Timer reiniciado');
        break;
      case AppLifecycleState.paused:
        print('⏸️ App paused - Timer continua em segundo plano');
        break;
      case AppLifecycleState.detached:
        homeCubit.stopAutoRefresh();
        SystemTrayService.dispose();
        print('🔚 App detached - Recursos limpos');
        break;
      case AppLifecycleState.inactive:
        print('😴 App inactive');
        break;
      case AppLifecycleState.hidden:
        print('👻 App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
