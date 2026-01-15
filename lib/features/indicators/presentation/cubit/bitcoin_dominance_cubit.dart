import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/api/coingecko_api.dart';
import '../../data/models/bitcoin_dominance_model.dart';
import 'bitcoin_dominance_state.dart';


class BitcoinDominanceCubit extends Cubit<BitcoinDominanceState> {
  final CoinGeckoApi _api;

  BitcoinDominanceCubit(this._api) : super(const BitcoinDominanceInitial());

  
  Future<void> loadBitcoinDominance() async {
    try {
      emit(const BitcoinDominanceLoading());

      debugPrint('🌍 [Bitcoin Dominance] Carregando dados globais...');
      
      
      final globalData = await _api.getGlobalMarketData();
      
      debugPrint('✅ [Bitcoin Dominance] Dominância BTC: ${globalData.btcDominance.toStringAsFixed(2)}%');
      debugPrint('📊 [Bitcoin Dominance] Status: ${globalData.dominanceStatus}');
      debugPrint('🎯 [Bitcoin Dominance] Proximidade do ciclo: ${globalData.cycleProximityPercentage.toStringAsFixed(1)}%');
      
      emit(BitcoinDominanceLoaded(
        dominance: globalData.btcDominance,
        status: globalData.dominanceStatus,
        message: globalData.dominanceMessage,
        cycleProximity: globalData.cycleProximityPercentage,
      ));
    } catch (e) {
      debugPrint('❌ [Bitcoin Dominance] Erro ao carregar: $e');
      emit(BitcoinDominanceError('Erro ao carregar dominância: ${e.toString()}'));
    }
  }

  
  Future<void> reload() async {
    await loadBitcoinDominance();
  }

  
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
      debugPrint('❌ [Bitcoin Dominance] Erro ao atualizar: $e');
      
    }
  }
}