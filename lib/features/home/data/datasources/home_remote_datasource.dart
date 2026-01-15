import '../api/coingecko_api.dart';
import '../models/home_data_model.dart';
import '../../../../core/services/preferences_service.dart';
import '../models/bitcoin_price_model.dart';
import '../../../indicators/data/models/bitcoin_dominance_model.dart';

/// Interface para fonte de dados remota da Home
abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
  Future<void> refreshHomeData();
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency});
}

/// Implementação da fonte de dados remota
/// Integra com a API do CoinGecko para dados reais
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final CoinGeckoApi _coinGeckoApi;

  HomeRemoteDataSourceImpl({
    required CoinGeckoApi coinGeckoApi,
  }) : _coinGeckoApi = coinGeckoApi;

  @override
  Future<HomeDataModel> getHomeData() async {
    try {
      // Busca a moeda selecionada nas preferências
      final selectedCurrency = await PreferencesService.getSelectedCurrency();
      
      // Busca todos os dados em paralelo para otimizar performance
      final futures = await Future.wait([
        _coinGeckoApi.getBitcoinPrice(currency: selectedCurrency),
        _coinGeckoApi.getGlobalMarketData(),
        _coinGeckoApi.getBitcoinDetailedInfo(),
      ]);
      
      final bitcoinPrice = futures[0] as BitcoinPriceModel;
      final globalData = futures[1] as BitcoinDominanceModel;
      final detailedInfo = futures[2] as Map<String, dynamic>;
      
      // Usa dados reais da API
      final changePercentage = bitcoinPrice.baseCurrencyChange;
      final changeAmount = bitcoinPrice.baseCurrencyPrice * (changePercentage / 100);
      
      // Fornecimento circulante em milhões
      final circulatingSupply = detailedInfo['circulating_supply'] as double?;
      final circulatingSupplyMillion = circulatingSupply != null ? circulatingSupply / 1e6 : null;
      
      final bitcoinData = BitcoinDataModel(
        currentPrice: bitcoinPrice.baseCurrencyPrice,
        changeAmount: changeAmount,
        changePercentage: changePercentage,
        maxPrice24h: bitcoinPrice.baseCurrencyHigh24h ?? bitcoinPrice.baseCurrencyPrice * 1.025, // Máxima convertida ou fallback
        minPrice24h: bitcoinPrice.baseCurrencyLow24h ?? bitcoinPrice.baseCurrencyPrice * 0.985, // Mínima convertida ou fallback
        // 🆕 TODOS OS DADOS REAIS DA API COM CONVERSÃO DE MOEDA
        volume24h: bitcoinPrice.baseCurrencyVolume24h / 1e9, // Converte para bilhões na moeda selecionada
        marketCap: bitcoinPrice.baseCurrencyMarketCap / 1e12, // Converte para trilhões na moeda selecionada
        circulatingSupply: circulatingSupplyMillion ?? 19.6, // Real da API ou fallback
        dominance: globalData.btcDominance, // 🆕 REAL DA API
        sentiment: bitcoinPrice.isPositive ? 'Altista' : 'Baixista',
        change7d: 0.0, // Removido - dados não confiáveis
        change30d: 0.0, // Removido - dados não confiáveis
        chartData: _generateChartData(bitcoinPrice.baseCurrencyPrice),
      );
      
      return HomeDataModel(
        title: 'BTC Cycle Monitor',
        subtitle: 'Acompanhamento em tempo real de Bitcoin',
        lastUpdated: DateTime.now(),
        isLoading: false,
        bitcoinData: bitcoinData,
      );
    } catch (e) {
      // Em caso de erro, retorna dados simulados como fallback
      return _getFallbackData();
    }
  }

  /// Dados de fallback em caso de erro na API
  HomeDataModel _getFallbackData() {
    final bitcoinData = BitcoinDataModel(
      currentPrice: 67234.50,
      changeAmount: 2.34,
      changePercentage: 3.61,
      maxPrice24h: 68450.00,
      minPrice24h: 65120.00,
      volume24h: 28.5,
      marketCap: 1.32,
      circulatingSupply: 19.6,
      dominance: 54.2,
      sentiment: 'Altista',
      change7d: 12.4,
      change30d: 18.7,
      chartData: _generateChartData(67234.50),
    );
    
    return HomeDataModel(
      title: 'BTC Cycle Monitor',
      subtitle: 'Dados simulados (API indisponível)',
      lastUpdated: DateTime.now(),
      isLoading: false,
      bitcoinData: bitcoinData,
    );
  }

  List<double> _generateChartData(double currentPrice) {
    // Gera dados de gráfico baseados no preço atual
    final data = <double>[];
    final basePrice = currentPrice * 0.95; // Começa 5% abaixo do preço atual
    
    for (int i = 0; i < 50; i++) {
      final variation = (i * (currentPrice - basePrice) / 49) + 
                       (i * 0.01 * (i % 3 == 0 ? 1 : -1)) * currentPrice;
      data.add(basePrice + variation);
    }
    
    return data;
  }

  @override
  Future<void> refreshHomeData() async {
    // Para refresh, apenas aguarda um pouco para simular o processo
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency = 'usd'}) async {
    try {
      // Converte período da UI para parâmetro da API
      final apiDays = _periodToApiDays(period);
      print('DEBUG: Period $period -> API days: $apiDays, currency: $currency');
      
      // Busca dados históricos reais da API na moeda especificada
      final historicalData = await _coinGeckoApi.getBitcoinHistoricalData(
        days: apiDays,
        currency: currency.toLowerCase(),
      );
      
      print('DEBUG: Received ${historicalData.chartData.length} points for period $period in $currency');
      
      // Retorna apenas os preços para o gráfico
      return historicalData.chartData;
    } catch (e) {
      // Em caso de erro, retorna dados simulados
      print('DEBUG: Error fetching data for $period: $e');
      return _generateFallbackChartData(period);
    }
  }

  /// Converte o período da UI para o parâmetro da API
  String _periodToApiDays(String period) {
    switch (period) {
      case '1D':
        return '1'; // 1 dia completo (24 horas)
      case '1W':
        return '7'; // 7 dias (1 semana)
      case '1M':
        return '30'; // 30 dias (1 mês)
      case '3M':
        return '90'; // 90 dias (3 meses)
      case '1Y':
        return '365'; // 365 dias (1 ano)
      default:
        return '1';
    }
  }

  /// Gera dados simulados baseados no período
  List<double> _generateFallbackChartData(String period) {
    final basePrice = 67000.0;
    final data = <double>[];
    
    // Ajusta a quantidade de pontos baseado no período
    int pointCount = switch (period) {
      '1D' => 24,   // 24 pontos para 1 dia (1 hora cada)
      '1W' => 7*24, // 168 pontos para 1 semana (1 hora cada)
      '1M' => 30,   // 30 pontos para 1 mês (1 dia cada)
      '3M' => 90,   // 90 pontos para 3 meses (1 dia cada)
      '1Y' => 365,  // 365 pontos para 1 ano (1 dia cada)
      _ => 50,
    };
    
    for (int i = 0; i < pointCount; i++) {
      final variation = (i * 45) + (i * 0.1 * (i % 3 == 0 ? 1 : -1)) * 200;
      data.add(basePrice + variation);
    }
    
    return data;
  }
}
