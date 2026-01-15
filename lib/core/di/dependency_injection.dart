import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Features
import '../../features/home/data/api/coingecko_api.dart';
import '../../features/home/data/datasources/home_local_datasource.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data.dart';
import '../../features/home/domain/usecases/refresh_home_data.dart';
import '../../features/home/domain/usecases/get_bitcoin_historical_data.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../preferences/preferences_cubit.dart';

/// Localizador de serviços para injeção de dependências
final sl = GetIt.instance;

/// Inicializa todas as dependências do app
Future<void> initializeDependencies() async {
  // Core - HTTP Client
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // APIs
  sl.registerLazySingleton<CoinGeckoApi>(
    () => CoinGeckoApi(httpClient: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(coinGeckoApi: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => RefreshHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => GetBitcoinHistoricalDataUseCase(sl()));

  // Global Preferences Cubit (Singleton para manter estado global)
  sl.registerLazySingleton(() => PreferencesCubit());

  // Cubits
  sl.registerFactory(() => HomeCubit(
    getHomeDataUseCase: sl(),
    refreshHomeDataUseCase: sl(),
    getBitcoinHistoricalDataUseCase: sl(),
    preferencesCubit: sl(),
  ));
}

/// Limpa todas as dependências (útil para testes)
Future<void> resetDependencies() async {
  await sl.reset();
}