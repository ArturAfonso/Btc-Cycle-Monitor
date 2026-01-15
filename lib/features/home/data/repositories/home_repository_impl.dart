import 'package:flutter/material.dart';

import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_data_model.dart';
import '../models/bitcoin_historical_data_model.dart';
import '../api/coingecko_api.dart';



class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;

  HomeRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<HomeData> getHomeData() async {
    try {
      
      final remoteData = await remoteDataSource.getHomeData();

      
      await localDataSource.cacheHomeData(remoteData);

      return remoteData;
    } catch (e) {
      
      try {
        return await localDataSource.getCachedHomeData();
      } catch (cacheError) {
        
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
      
      return _generateFallbackChartData();
    }
  }

  @override
  Future<BitcoinHistoricalDataModel> getBitcoinHistoricalDataComplete(String period, {String currency = 'usd'}) async {
    try {
      
      final apiDays = _periodToApiDays(period);
      debugPrint('DEBUG: Period $period -> API parameter: $apiDays, currency: $currency');
      
      final historicalData = await CoinGeckoApi().getBitcoinHistoricalData(
        days: apiDays,
        currency: currency.toLowerCase(),
      );
      
      debugPrint('DEBUG: Direct API call - received ${historicalData.prices.length} points for period $period in $currency');
      if (historicalData.prices.isNotEmpty) {
        debugPrint('DEBUG: First timestamp: ${historicalData.prices.first.timestamp}');
        debugPrint('DEBUG: Last timestamp: ${historicalData.prices.last.timestamp}');
        debugPrint('DEBUG: First price: ${historicalData.prices.first.price.toStringAsFixed(2)} $currency');
        debugPrint('DEBUG: Last price: ${historicalData.prices.last.price.toStringAsFixed(2)} $currency');
        
        
        if (historicalData.prices.length > 10) {
          final midIndex = historicalData.prices.length ~/ 2;
          debugPrint('DEBUG: Mid point ($midIndex): ${historicalData.prices[midIndex].timestamp} - ${historicalData.prices[midIndex].price.toStringAsFixed(2)} $currency');
        }
      }
      
      return historicalData;
    } catch (e) {
      
      debugPrint('DEBUG: Error getting complete data for $period: $e');
      return _generateFallbackHistoricalData();
    }
  }

  
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
