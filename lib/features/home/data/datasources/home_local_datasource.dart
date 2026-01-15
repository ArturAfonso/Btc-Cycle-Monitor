import '../models/home_data_model.dart';

/// Interface para fonte de dados local da Home
abstract class HomeLocalDataSource {
  Future<HomeDataModel> getCachedHomeData();
  Future<void> cacheHomeData(HomeDataModel homeDataModel);
}

/// Implementação da fonte de dados local
/// Por enquanto simula dados em memória
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeDataModel? _cachedData;

  @override
  Future<HomeDataModel> getCachedHomeData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }
    throw Exception('Nenhum dado em cache encontrado');
  }

  @override
  Future<void> cacheHomeData(HomeDataModel homeDataModel) async {
    _cachedData = homeDataModel;
  }
}
