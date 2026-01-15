import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/api/coingecko_api.dart';
import '../../utils/pi_cycle_top_calculator.dart';
import 'pi_cycle_top_state.dart';


class PiCycleTopCubit extends Cubit<PiCycleTopState> {
  final CoinGeckoApi _api;
  String _currentCurrency = 'usd'; 

  PiCycleTopCubit(this._api) : super(PiCycleTopInitial());

  
  Future<void> updateCurrency(String currency) async {
    final newCurrency = currency.toLowerCase();
    
    
    if (_currentCurrency != newCurrency || state is! PiCycleTopLoaded) {
      _currentCurrency = newCurrency;
      debugPrint('💱 [Pi Cycle Top] Moeda atualizada para: $_currentCurrency');
      await loadPiCycleTop();
    }
  }

  
  
  
  
  Future<void> loadPiCycleTop() async {
    try {
      emit(PiCycleTopLoading());

      debugPrint('📊 [Pi Cycle Top] Carregando dados históricos em $_currentCurrency...');
      
      
      final historicalData = await _api.getBitcoinHistoricalData(
        days: '365',
        currency: _currentCurrency,
      );
      
      if (historicalData.prices.isEmpty) {
        emit(const PiCycleTopError('Nenhum dado histórico disponível'));
        return;
      }

      
      final closePrices = historicalData.prices.map((p) => p.price).toList();
      
      debugPrint('📊 [Pi Cycle Top] Recebidos ${closePrices.length} preços de fechamento em $_currentCurrency');
      debugPrint('📊 [Pi Cycle Top] Necessário: 350 para SMA 350');
      
      if (closePrices.length < 350) {
        debugPrint('❌ [Pi Cycle Top] DADOS INSUFICIENTES: ${closePrices.length} < 350');
        emit(PiCycleTopLoaded(
          sma111: null,
          sma350x2: null,
          distance: null,
          status: 'insufficient_data',
          message: 'Dados insuficientes. Recebido ${closePrices.length} pontos, necessário pelo menos 350 dias de histórico.',
        ));
        return;
      }
      
      debugPrint('📊 [Pi Cycle Top] Analisando ${closePrices.length} preços de fechamento...');
      
      
      final analysis = PiCycleTopCalculator.analyzeCurrentState(closePrices);
      
      
      if (analysis['sma111'] != null && analysis['sma350x2'] != null) {
        debugPrint('📊 [Pi Cycle Top] SMA 111: \$${analysis['sma111'].toStringAsFixed(2)}');
        debugPrint('📊 [Pi Cycle Top] SMA 350 x 2: \$${analysis['sma350x2'].toStringAsFixed(2)}');
        debugPrint('📊 [Pi Cycle Top] Distância: ${analysis['distance'].toStringAsFixed(2)}%');
        debugPrint('📊 [Pi Cycle Top] Status: ${analysis['status']}');
      }
      
      emit(PiCycleTopLoaded(
        sma111: analysis['sma111'],
        sma350x2: analysis['sma350x2'],
        distance: analysis['distance'],
        status: analysis['status'],
        message: analysis['message'],
      ));
    } catch (e) {
      debugPrint('❌ [Pi Cycle Top] Erro ao carregar: $e');
      emit(PiCycleTopError('Erro ao carregar Pi Cycle Top: ${e.toString()}'));
    }
  }

  
  Future<void> reload() async {
    await loadPiCycleTop();
  }
}
