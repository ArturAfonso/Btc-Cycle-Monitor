import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_home_data.dart';
import '../../domain/usecases/refresh_home_data.dart';
import '../../domain/usecases/get_bitcoin_historical_data.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';
import '../../../../core/services/alert_service.dart';
import 'home_state.dart';


class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;
  final RefreshHomeDataUseCase refreshHomeDataUseCase;
  final GetBitcoinHistoricalDataUseCase getBitcoinHistoricalDataUseCase;
  final PreferencesCubit preferencesCubit;
  
  
  String _selectedPeriod = '1D';
  
  
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 2);

  HomeCubit({
    required this.getHomeDataUseCase, 
    required this.refreshHomeDataUseCase,
    required this.getBitcoinHistoricalDataUseCase,
    required this.preferencesCubit,
  }) : super(HomeInitial()) {
    
    loadHomeData();
    
    _startAutoRefresh();
  }

  @override
  Future<void> close() {
    
    _autoRefreshTimer?.cancel();
    return super.close();
  }

  
  String get selectedPeriod => _selectedPeriod;

  
  String get _selectedCurrency {
    final prefsState = preferencesCubit.state;
    if (prefsState is PreferencesLoaded) {
      return prefsState.selectedCurrency;
    }
    return 'usd'; 
  }

  
  Future<void> loadHomeData() async {
    emit(HomeLoading());

    try {
      final homeData = await getHomeDataUseCase();
      
      
      try {
        final currency = _selectedCurrency;
        debugPrint('DEBUG [HomeCubit.loadHomeData]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(_selectedPeriod, currency: currency);
        
        
        final updatedBitcoinData = homeData.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = homeData.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        emit(HomeLoaded(updatedHomeData));
        
        _updateSystemTray(updatedHomeData);
      } catch (historicalError) {
        
        emit(HomeLoaded(homeData));
        
        _updateSystemTray(homeData);
      }
    } catch (e) {
      emit(HomeError('Erro ao carregar dados: ${e.toString()}'));
    }
  }

  
  Future<void> refreshData() async {
    try {
      await refreshHomeDataUseCase();
      await loadHomeData();
    } catch (e) {
      emit(HomeError('Erro ao atualizar dados: ${e.toString()}'));
    }
  }

  
  Future<void> refreshDataWithCurrency(String currency) async {
    debugPrint('🔄 [HomeCubit] Atualizando dados com moeda: ${currency.toUpperCase()}');
    try {
      
      await refreshHomeDataUseCase();
      await loadHomeData();
    } catch (e) {
      debugPrint('❌ [HomeCubit] Erro ao atualizar dados com nova moeda: $e');
      emit(HomeError('Erro ao atualizar dados: ${e.toString()}'));
    }
  }

  
  Future<void> changePeriod(String period) async {
    if (_selectedPeriod == period) return; 
    
    _selectedPeriod = period;
    
    
    final currentState = state;
    if (currentState is HomeLoaded) {
      emit(HomeLoaded(currentState.data, isLoadingChart: true));
      
      try {
        
        final currency = _selectedCurrency;
        debugPrint('DEBUG [HomeCubit.changePeriod]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(period, currency: currency);
        
        
        final updatedBitcoinData = currentState.data.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = currentState.data.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        emit(HomeLoaded(updatedHomeData, isLoadingChart: false));
      } catch (e) {
        
        emit(HomeLoaded(currentState.data, isLoadingChart: false));
      }
    } else {
      
      await loadHomeData();
    }
  }

  
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); 
    
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) async {
      try {
        debugPrint('🔄 Executando atualização automática... (${DateTime.now()})');
        
        await _autoUpdateData();
        debugPrint('✅ Atualização automática concluída');
      } catch (e) {
        
        debugPrint('❌ Erro na atualização automática: $e');
      }
    });
  }

  
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  
  void restartAutoRefresh() {
    debugPrint('🔄 App voltou ao foco - Buscando cotação imediatamente...');
    
    
    _autoUpdateData().then((_) {
      debugPrint('✅ Cotação atualizada imediatamente ao voltar ao foco');
    }).catchError((e) {
      debugPrint('❌ Erro na busca imediata: $e');
    });
    
    
    _startAutoRefresh();
  }

  
  Future<void> _autoUpdateData() async {
    try {
      final homeData = await getHomeDataUseCase();
      
      
      try {
        final currency = _selectedCurrency;
        debugPrint('DEBUG [HomeCubit._autoUpdateData]: Using currency $currency');
        final historicalDataModel = await getBitcoinHistoricalDataUseCase(_selectedPeriod, currency: currency);
        
        
        final updatedBitcoinData = homeData.bitcoinData?.copyWith(
          chartData: historicalDataModel.chartData,
          historicalData: historicalDataModel,
        );
        
        final updatedHomeData = homeData.copyWith(
          bitcoinData: updatedBitcoinData,
        );
        
        
        if (state is HomeLoaded) {
          emit(HomeLoaded(updatedHomeData));
          
          _updateSystemTray(updatedHomeData);
          
          
          if (updatedBitcoinData != null) {
            await AlertService.checkAlerts(updatedBitcoinData);
          }
        }
      } catch (historicalError) {
        
        if (state is HomeLoaded) {
          emit(HomeLoaded(homeData));
          
          _updateSystemTray(homeData);
          
          
          if (homeData.bitcoinData != null) {
            await AlertService.checkAlerts(homeData.bitcoinData!);
          }
        }
      }
    } catch (e) {
      
      debugPrint('Erro na atualização automática dos dados: $e');
    }
  }

  
  void _updateSystemTray(dynamic homeData) {
    try {
      if (homeData?.bitcoinData != null) {
        final bitcoin = homeData.bitcoinData;
        final price = bitcoin.currentPrice.toStringAsFixed(2);
        final change = bitcoin.changePercentage > 0 
            ? '+${bitcoin.changePercentage.toStringAsFixed(2)}%'
            : '${bitcoin.changePercentage.toStringAsFixed(2)}%';
        
        
        debugPrint('� [Bitcoin] Preço atualizado: \$$price ($change)');
      }
    } catch (e) {
      debugPrint('❌ [Bitcoin] Erro ao processar dados: $e');
    }
  }
}
