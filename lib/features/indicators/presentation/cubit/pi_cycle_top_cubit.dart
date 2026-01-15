import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/api/coingecko_api.dart';
import '../../utils/pi_cycle_top_calculator.dart';
import 'pi_cycle_top_state.dart';

/// Cubit para gerenciar o estado do indicador Pi Cycle Top
class PiCycleTopCubit extends Cubit<PiCycleTopState> {
  final CoinGeckoApi _api;
  String _currentCurrency = 'usd'; // Moeda atual

  PiCycleTopCubit(this._api) : super(PiCycleTopInitial());

  /// Atualiza a moeda e recarrega os dados
  Future<void> updateCurrency(String currency) async {
    final newCurrency = currency.toLowerCase();
    
    // Sempre recarrega se a moeda mudou OU se ainda não há dados carregados
    if (_currentCurrency != newCurrency || state is! PiCycleTopLoaded) {
      _currentCurrency = newCurrency;
      print('💱 [Pi Cycle Top] Moeda atualizada para: $_currentCurrency');
      await loadPiCycleTop();
    }
  }

  /// Carrega os dados históricos e calcula o Pi Cycle Top
  /// 
  /// Usa o endpoint /market_chart com days=365 que retorna dados diários (~366 pontos)
  /// Isso é suficiente para calcular SMA 350 (precisamos de 350+ pontos)
  Future<void> loadPiCycleTop() async {
    try {
      emit(PiCycleTopLoading());

      print('📊 [Pi Cycle Top] Carregando dados históricos em $_currentCurrency...');
      
      // Busca 365 dias de dados históricos (diários = 366 pontos) na moeda selecionada
      final historicalData = await _api.getBitcoinHistoricalData(
        days: '365',
        currency: _currentCurrency,
      );
      
      if (historicalData.prices.isEmpty) {
        emit(const PiCycleTopError('Nenhum dado histórico disponível'));
        return;
      }

      // Extrai preços dos dados históricos
      final closePrices = historicalData.prices.map((p) => p.price).toList();
      
      print('📊 [Pi Cycle Top] Recebidos ${closePrices.length} preços de fechamento em $_currentCurrency');
      print('📊 [Pi Cycle Top] Necessário: 350 para SMA 350');
      
      if (closePrices.length < 350) {
        print('❌ [Pi Cycle Top] DADOS INSUFICIENTES: ${closePrices.length} < 350');
        emit(PiCycleTopLoaded(
          sma111: null,
          sma350x2: null,
          distance: null,
          status: 'insufficient_data',
          message: 'Dados insuficientes. Recebido ${closePrices.length} pontos, necessário pelo menos 350 dias de histórico.',
        ));
        return;
      }
      
      print('📊 [Pi Cycle Top] Analisando ${closePrices.length} preços de fechamento...');
      
      // Analisa o estado atual do indicador
      final analysis = PiCycleTopCalculator.analyzeCurrentState(closePrices);
      
      // Log detalhado
      if (analysis['sma111'] != null && analysis['sma350x2'] != null) {
        print('📊 [Pi Cycle Top] SMA 111: \$${analysis['sma111'].toStringAsFixed(2)}');
        print('📊 [Pi Cycle Top] SMA 350 x 2: \$${analysis['sma350x2'].toStringAsFixed(2)}');
        print('📊 [Pi Cycle Top] Distância: ${analysis['distance'].toStringAsFixed(2)}%');
        print('📊 [Pi Cycle Top] Status: ${analysis['status']}');
      }
      
      emit(PiCycleTopLoaded(
        sma111: analysis['sma111'],
        sma350x2: analysis['sma350x2'],
        distance: analysis['distance'],
        status: analysis['status'],
        message: analysis['message'],
      ));
    } catch (e) {
      print('❌ [Pi Cycle Top] Erro ao carregar: $e');
      emit(PiCycleTopError('Erro ao carregar Pi Cycle Top: ${e.toString()}'));
    }
  }

  /// Recarrega os dados
  Future<void> reload() async {
    await loadPiCycleTop();
  }
}
