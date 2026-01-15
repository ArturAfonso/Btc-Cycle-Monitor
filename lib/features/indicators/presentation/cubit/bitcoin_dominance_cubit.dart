import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/api/coingecko_api.dart';
import '../../data/models/bitcoin_dominance_model.dart';
import 'bitcoin_dominance_state.dart';

/// Cubit para gerenciar o estado da dominância do Bitcoin
class BitcoinDominanceCubit extends Cubit<BitcoinDominanceState> {
  final CoinGeckoApi _api;

  BitcoinDominanceCubit(this._api) : super(const BitcoinDominanceInitial());

  /// Carrega os dados de dominância do Bitcoin
  Future<void> loadBitcoinDominance() async {
    try {
      emit(const BitcoinDominanceLoading());

      print('🌍 [Bitcoin Dominance] Carregando dados globais...');
      
      // Busca dados globais do mercado de criptomoedas
      final globalData = await _api.getGlobalMarketData();
      
      print('✅ [Bitcoin Dominance] Dominância BTC: ${globalData.btcDominance.toStringAsFixed(2)}%');
      print('📊 [Bitcoin Dominance] Status: ${globalData.dominanceStatus}');
      print('🎯 [Bitcoin Dominance] Proximidade do ciclo: ${globalData.cycleProximityPercentage.toStringAsFixed(1)}%');
      
      emit(BitcoinDominanceLoaded(
        dominance: globalData.btcDominance,
        status: globalData.dominanceStatus,
        message: globalData.dominanceMessage,
        cycleProximity: globalData.cycleProximityPercentage,
      ));
    } catch (e) {
      print('❌ [Bitcoin Dominance] Erro ao carregar: $e');
      emit(BitcoinDominanceError('Erro ao carregar dominância: ${e.toString()}'));
    }
  }

  /// Recarrega os dados
  Future<void> reload() async {
    await loadBitcoinDominance();
  }

  /// Atualiza dados silenciosamente (sem loading)
  Future<void> refresh() async {
    try {
      final globalData = await _api.getGlobalMarketData();
      
      emit(BitcoinDominanceLoaded(
        dominance: globalData.btcDominance,
        status: globalData.dominanceStatus,
        message: globalData.dominanceMessage,
        cycleProximity: globalData.cycleProximityPercentage,
      ));
    } catch (e) {
      print('❌ [Bitcoin Dominance] Erro ao atualizar: $e');
      // Mantém o estado atual em caso de erro no refresh
    }
  }
}