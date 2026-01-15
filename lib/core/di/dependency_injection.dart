import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;


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


final sl = GetIt.instance;


Future<void> initializeDependencies() async {
  
  sl.registerLazySingleton<http.Client>(() => http.Client());

  
  sl.registerLazySingleton<CoinGeckoApi>(
    () => CoinGeckoApi(httpClient: sl()),
  );

  
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(coinGeckoApi: sl()),
  );
  sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(),
  );

  
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  
  sl.registerLazySingleton(() => GetHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => RefreshHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => GetBitcoinHistoricalDataUseCase(sl()));

  
  sl.registerLazySingleton(() => PreferencesCubit());

  
  sl.registerFactory(() => HomeCubit(
    getHomeDataUseCase: sl(),
    refreshHomeDataUseCase: sl(),
    getBitcoinHistoricalDataUseCase: sl(),
    preferencesCubit: sl(),
  ));
}


Future<void> resetDependencies() async {
  await sl.reset();
}