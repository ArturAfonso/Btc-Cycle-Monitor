import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_home_data.dart';
import '../../domain/usecases/refresh_home_data.dart';
import '../../domain/usecases/get_bitcoin_historical_data.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';
import '../../../../core/services/alert_service.dart';
import 'home_state.dart';

/// Cubit responsável pela lógica da tela Home
class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;
  final RefreshHomeDataUseCase refreshHomeDataUseCase;
  final GetBitcoinHistoricalDataUseCase getBitcoinHistoricalDataUseCase;
  final PreferencesCubit preferencesCubit;
  
  // Controla o período selecionado para o gráfico
  String _selectedPeriod = '1D';
  
  // Timer para atualização automática a cada 2 minutos
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 2);

  HomeCubit({
    required this.getHomeDataUseCase, 
    required this.refreshHomeDataUseCase,
    required this.getBitcoinHistoricalDataUseCase,
    required this.preferencesCubit,
  }) : super(HomeInitial()) {
    // Carrega automaticamente os dados ao inicializar
    loadHomeData();
    // Inicia o timer de atualização automática
    _startAutoRefresh();
  }

  @override
  Future<void> close() {
    // Cancela o timer quando o Cubit for fechado
    _autoRefreshTimer?.cancel();
    return super.close();
  }

  /// Getter para o período atual
  String get selectedPeriod => _selectedPeriod;

  /// Obtém a moeda selecionada do PreferencesCubit
  String get _selectedCurrency {
    final prefsState = preferencesCubit.state;
    if (prefsState is PreferencesLoaded) {
      return prefsState.selectedCurrency;
    }
    return 'usd'; // Padrão se não houver preferências carregadas
  }

  /// Carrega os dados da Home
  Future<void> loadHomeData() async {
    emit(HomeLoading());

    try {
      final homeData = await getHomeDataUseCase();
      
      // Carrega também os dados históricos para o período padrão
      try {
        final currency = _selectedCurrency;
        print('DEBUG [HomeCubit.loadHomeData]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(_selectedPeriod, currency: currency);
        
        // Atualiza os dados do Bitcoin com os dados históricos reais
        final updatedBitcoinData = homeData.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = homeData.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        emit(HomeLoaded(updatedHomeData));
        // Atualiza system tray no carregamento inicial
        _updateSystemTray(updatedHomeData);
      } catch (historicalError) {
        // Se falhar ao carregar dados históricos, usa os dados padrão
        emit(HomeLoaded(homeData));
        // Atualiza system tray mesmo se dados históricos falharam
        _updateSystemTray(homeData);
      }
    } catch (e) {
      emit(HomeError('Erro ao carregar dados: ${e.toString()}'));
    }
  }

  /// Atualiza os dados da Home
  Future<void> refreshData() async {
    try {
      await refreshHomeDataUseCase();
      await loadHomeData();
    } catch (e) {
      emit(HomeError('Erro ao atualizar dados: ${e.toString()}'));
    }
  }

  /// Atualiza os dados com uma nova moeda
  Future<void> refreshDataWithCurrency(String currency) async {
    print('🔄 [HomeCubit] Atualizando dados com moeda: ${currency.toUpperCase()}');
    try {
      // Força recarregamento dos dados com a nova moeda
      await refreshHomeDataUseCase();
      await loadHomeData();
    } catch (e) {
      print('❌ [HomeCubit] Erro ao atualizar dados com nova moeda: $e');
      emit(HomeError('Erro ao atualizar dados: ${e.toString()}'));
    }
  }

  /// Muda o período do gráfico e recarrega os dados
  Future<void> changePeriod(String period) async {
    if (_selectedPeriod == period) return; // Não faz nada se já está selecionado
    
    _selectedPeriod = period;
    
    // Emite o estado atual mas com loading para mostrar que está carregando
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoaded(currentState.data, isLoadingChart: true));
      
      try {
        // Busca dados históricos para o novo período
        final currency = _selectedCurrency;
        print('DEBUG [HomeCubit.changePeriod]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(period, currency: currency);
        
        // Atualiza os dados do gráfico
        final updatedBitcoinData = currentState.data.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = currentState.data.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        emit(HomeLoaded(updatedHomeData, isLoadingChart: false));
      } catch (e) {
        // Se der erro, mantém os dados atuais mas remove o loading
        emit(HomeLoaded(currentState.data, isLoadingChart: false));
      }
    } else {
      // Se não está carregado, carrega tudo novamente
      await loadHomeData();
    }
  }

  /// Inicia o timer de atualização automática
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // Cancela timer anterior se existir
    
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      try {
        print('🔄 Executando atualização automática... (${DateTime.now()})');
        // Atualiza os dados automaticamente
        await _autoUpdateData();
        print('✅ Atualização automática concluída');
      } catch (e) {
        // Silenciosamente falha para não interromper o timer
        print('❌ Erro na atualização automática: $e');
      }
    });
  }

  /// Para o timer de atualização automática
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Reinicia o timer de atualização automática com busca imediata
  void restartAutoRefresh() {
    print('🔄 App voltou ao foco - Buscando cotação imediatamente...');
    
    // Faz uma busca imediata da cotação
    _autoUpdateData().then((_) {
      print('✅ Cotação atualizada imediatamente ao voltar ao foco');
    }).catchError((e) {
      print('❌ Erro na busca imediata: $e');
    });
    
    // Reinicia o timer para as próximas atualizações
    _startAutoRefresh();
  }

  /// Método interno para atualização automática (não emite loading)
  Future<void> _autoUpdateData() async {
    try {
      final homeData = await getHomeDataUseCase();
      
      // Carrega também os dados históricos para o período atual
      try {
        final currency = _selectedCurrency;
        print('DEBUG [HomeCubit._autoUpdateData]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(_selectedPeriod, currency: currency);
        
        // Atualiza os dados do Bitcoin com os dados históricos reais
        final updatedBitcoinData = homeData.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = homeData.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        // Só emite se ainda estiver em estado carregado (não interrompe loading manual)
        if (state is HomeLoaded) {
          emit(HomeLoaded(updatedHomeData));
          // Atualiza system tray com novo preço
          _updateSystemTray(updatedHomeData);
          
          // Verifica alertas configurados
          if (updatedBitcoinData != null) {
            await AlertService.checkAlerts(updatedBitcoinData);
          }
        }
      } catch (historicalError) {
        // Se falhar ao carregar dados históricos, usa apenas os dados principais
        if (state is HomeLoaded) {
          emit(HomeLoaded(homeData));
          // Atualiza system tray mesmo se dados históricos falharam
          _updateSystemTray(homeData);
          
          // Verifica alertas mesmo sem dados históricos
          if (homeData.bitcoinData != null) {
            await AlertService.checkAlerts(homeData.bitcoinData!);
          }
        }
      }
    } catch (e) {
      // Falha silenciosa para não interromper a experiência do usuário
      print('Erro na atualização automática dos dados: $e');
    }
  }

  /// Atualiza informações do Bitcoin (removido system tray por enquanto)
  void _updateSystemTray(dynamic homeData) {
    try {
      if (homeData?.bitcoinData != null) {
        final bitcoin = homeData.bitcoinData;
        final price = bitcoin.currentPrice.toStringAsFixed(2);
        final change = bitcoin.changePercentage > 0 
            ? '+${bitcoin.changePercentage.toStringAsFixed(2)}%'
            : '${bitcoin.changePercentage.toStringAsFixed(2)}%';
        
        // SystemTrayService.updateTooltip(price, change); // Removido temporariamente
        print('� [Bitcoin] Preço atualizado: \$$price ($change)');
      }
    } catch (e) {
      print('❌ [Bitcoin] Erro ao processar dados: $e');
    }
  }
}
