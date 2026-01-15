import '../entities/home_data.dart';
import '../../data/models/bitcoin_historical_data_model.dart';

/// Interface do repositório para a feature Home
/// Define o contrato que deve ser implementado na camada de dados
abstract class HomeRepository {
  Future<HomeData> getHomeData();
  Future<void> refreshHomeData();
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency});
  Future<BitcoinHistoricalDataModel> getBitcoinHistoricalDataComplete(String period, {String currency});
}
