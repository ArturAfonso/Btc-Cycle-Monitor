import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_data_model.dart';
import '../models/bitcoin_historical_data_model.dart';
import '../api/coingecko_api.dart';

/// Implementação concreta do repositório da Home
/// Coordena entre fontes de dados local e remota
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<HomeData> getHomeData() async {
    try {
      // Tenta pegar dados remotos primeiro
      final remoteData = await remoteDataSource.getHomeData();

      // Cache os dados localmente
      await localDataSource.cacheHomeData(remoteData);

      return remoteData;
    } catch (e) {
      // Se falhar, tenta dados em cache
      try {
        return await localDataSource.getCachedHomeData();
      } catch (cacheError) {
        // Se não há cache, retorna dados padrão
        return HomeDataModel(
          title: 'BTC Cycle Monitor',
          subtitle: 'Dados indisponíveis',
          lastUpdated: DateTime.now(),
          isLoading: false,
        );
      }
    }
  }

  @override
  Future<void> refreshHomeData() async {
    await remoteDataSource.refreshHomeData();
  }

  @override
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency = 'usd'}) async {
    try {
      return await remoteDataSource.getBitcoinHistoricalData(period, currency: currency);
    } catch (e) {
      // Em caso de erro, retorna dados simulados
      return _generateFallbackChartData();
    }
  }

  @override
  Future<BitcoinHistoricalDataModel> getBitcoinHistoricalDataComplete(String period, {String currency = 'usd'}) async {
    try {
      // Usa a API diretamente para obter dados com timestamps reais
      final apiDays = _periodToApiDays(period);
      print('DEBUG: Period $period -> API parameter: $apiDays, currency: $currency');
      
      final historicalData = await CoinGeckoApi().getBitcoinHistoricalData(
        days: apiDays,
        currency: currency.toLowerCase(),
      );
      
      print('DEBUG: Direct API call - received ${historicalData.prices.length} points for period $period in $currency');
      if (historicalData.prices.isNotEmpty) {
        print('DEBUG: First timestamp: ${historicalData.prices.first.timestamp}');
        print('DEBUG: Last timestamp: ${historicalData.prices.last.timestamp}');
        print('DEBUG: First price: ${historicalData.prices.first.price.toStringAsFixed(2)} $currency');
        print('DEBUG: Last price: ${historicalData.prices.last.price.toStringAsFixed(2)} $currency');
        
        // Mostra alguns pontos do meio para verificar se os dados fazem sentido
        if (historicalData.prices.length > 10) {
          final midIndex = historicalData.prices.length ~/ 2;
          print('DEBUG: Mid point ($midIndex): ${historicalData.prices[midIndex].timestamp} - ${historicalData.prices[midIndex].price.toStringAsFixed(2)} $currency');
        }
      }
      
      return historicalData;
    } catch (e) {
      // Em caso de erro, retorna dados simulados
      print('DEBUG: Error getting complete data for $period: $e');
      return _generateFallbackHistoricalData();
    }
  }

  /// Converte o período da UI para o parâmetro da API (mesmo que no datasource)
  String _periodToApiDays(String period) {
    switch (period) {
      case '1D':
        return '1';
      case '1W':
        return '7';
      case '1M':
        return '30';
      case '3M':
        return '90';
      case '1Y':
        return '365';
      default:
        return '1';
    }
  }

  /// Gera dados históricos simulados em caso de erro
  BitcoinHistoricalDataModel _generateFallbackHistoricalData() {
    final basePrice = 67000.0;
    final now = DateTime.now();
    final List<BitcoinHistoricalPoint> pricePoints = [];
    
    for (int i = 0; i < 50; i++) {
      final variation = (i * 45) + (i * 0.1 * (i % 3 == 0 ? 1 : -1)) * 200;
      final timestamp = now.subtract(Duration(hours: 50 - i));
      pricePoints.add(BitcoinHistoricalPoint(
        timestamp: timestamp,
        price: basePrice + variation,
      ));
    }
    
    return BitcoinHistoricalDataModel(
      prices: pricePoints,
      marketCaps: [],
      totalVolumes: [],
    );
  }

  /// Gera dados simulados em caso de erro na API
  List<double> _generateFallbackChartData() {
    final basePrice = 67000.0;
    final data = <double>[];
    
    for (int i = 0; i < 50; i++) {
      final variation = (i * 45) + (i * 0.1 * (i % 3 == 0 ? 1 : -1)) * 200;
      data.add(basePrice + variation);
    }
    
    return data;
  }
}
