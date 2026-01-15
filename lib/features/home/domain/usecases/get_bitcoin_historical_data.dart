import 'package:flutter/material.dart';

import '../repositories/home_repository.dart';
import '../../data/models/bitcoin_historical_data_model.dart';

/// Use case para obter dados históricos do Bitcoin para gráficos
class GetBitcoinHistoricalDataUseCase {
  final HomeRepository repository;

  GetBitcoinHistoricalDataUseCase(this.repository);

  /// Busca dados históricos baseado no período selecionado
  /// Retorna o modelo completo com timestamps e preços
  Future<BitcoinHistoricalDataModel> call(String period, {String currency = 'usd'}) async {
    debugPrint('📈 [UseCase] Iniciando busca de dados históricos para período: $period, currency: $currency');
    final historicalData = await repository.getBitcoinHistoricalDataComplete(period, currency: currency);
    debugPrint('✅ [UseCase] Dados históricos obtidos para período: $period in $currency');
    return historicalData;
  }
  
  /// Versão que retorna apenas os preços (compatibilidade com código anterior)
  Future<List<double>> callForPrices(String period, {String currency = 'usd'}) async {
    return await repository.getBitcoinHistoricalData(period, currency: currency);
  }
}