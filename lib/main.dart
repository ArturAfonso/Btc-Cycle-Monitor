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
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await initializeDateFormatting();
  
  await NotificationService.initialize();
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, 
    windowButtonVisibility: false,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize(); 
  });
 
  await initializeDependencies();
  
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
         
          final preferencesCubit = context.read<PreferencesCubit>();
          preferencesCubit.onCurrencyChanged = (currency) {
            final homeCubit = context.read<HomeCubit>();
            homeCubit.refreshDataWithCurrency(currency);
          };
          
          return MaterialApp(
            title: 'BTC Cycle Monitor',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, 
            home: const WindowLifecycleWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

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
    
   
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeSystemTray();
    });
    
    
    homeCubit.stream.listen((state) {
      _updateSystemTray(state);
    });
  }

  Future<void> _initializeSystemTray() async {
    try {
      await SystemTrayService.initialize();
      debugPrint("✅ System Tray inicializado com sucesso após primeiro frame");
    } catch (e) {
      debugPrint("❌ Erro ao inicializar System Tray");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemTrayService.dispose();
    super.dispose();
  }

  void _updateSystemTray(HomeState state) {
    if (state is HomeLoaded && state.data.bitcoinData != null) {
      final bitcoinData = state.data.bitcoinData!;
      final price = '\$${bitcoinData.currentPrice.toStringAsFixed(2)}';
      final change = '${bitcoinData.changePercentage >= 0 ? '+' : ''}${bitcoinData.changePercentage.toStringAsFixed(2)}%';
      
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
        debugPrint('🔄 App resumed - Timer reiniciado');
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ App paused - Timer continua em segundo plano');
        break;
      case AppLifecycleState.detached:
        homeCubit.stopAutoRefresh();
        SystemTrayService.dispose();
        debugPrint('🔚 App detached - Recursos limpos');
        break;
      case AppLifecycleState.inactive:
        debugPrint('😴 App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('👻 App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
