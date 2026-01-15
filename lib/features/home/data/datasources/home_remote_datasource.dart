import 'package:flutter/material.dart';

import '../api/coingecko_api.dart';
import '../models/home_data_model.dart';
import '../../../../core/services/preferences_service.dart';
import '../models/bitcoin_price_model.dart';
import '../../../indicators/data/models/bitcoin_dominance_model.dart';


abstract class HomeRemoteDataSource {
  Future<HomeDataModel> getHomeData();
  Future<void> refreshHomeData();
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency});
}



class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final CoinGeckoApi _coinGeckoApi;

  HomeRemoteDataSourceImpl({
    required CoinGeckoApi coinGeckoApi,
  }) : _coinGeckoApi = coinGeckoApi;

  @override
  Future<HomeDataModel> getHomeData() async {
    try {
      
      final selectedCurrency = await PreferencesService.getSelectedCurrency();
      
      
      final futures = await Future.wait([
        _coinGeckoApi.getBitcoinPrice(currency: selectedCurrency),
        _coinGeckoApi.getGlobalMarketData(),
        _coinGeckoApi.getBitcoinDetailedInfo(),
      ]);
      
      final bitcoinPrice = futures[0] as BitcoinPriceModel;
      final globalData = futures[1] as BitcoinDominanceModel;
      final detailedInfo = futures[2] as Map<String, dynamic>;
      
      
      final changePercentage = bitcoinPrice.baseCurrencyChange;
      final changeAmount = bitcoinPrice.baseCurrencyPrice * (changePercentage / 100);
      
      
      final circulatingSupply = detailedInfo['circulating_supply'] as double?;
      final circulatingSupplyMillion = circulatingSupply != null ? circulatingSupply / 1e6 : null;
      
      final bitcoinData = BitcoinDataModel(
        currentPrice: bitcoinPrice.baseCurrencyPrice,
        changeAmount: changeAmount,
        changePercentage: changePercentage,
        maxPrice24h: bitcoinPrice.baseCurrencyHigh24h ?? bitcoinPrice.baseCurrencyPrice * 1.025, 
        minPrice24h: bitcoinPrice.baseCurrencyLow24h ?? bitcoinPrice.baseCurrencyPrice * 0.985, 
        
        volume24h: bitcoinPrice.baseCurrencyVolume24h / 1e9, 
        marketCap: bitcoinPrice.baseCurrencyMarketCap / 1e12, 
        circulatingSupply: circulatingSupplyMillion ?? 19.6, 
        dominance: globalData.btcDominance, 
        sentiment: bitcoinPrice.isPositive ? 'Altista' : 'Baixista',
        change7d: 0.0, 
        change30d: 0.0, 
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
      
      return _getFallbackData();
    }
  }

  
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
    
    final data = <double>[];
    final basePrice = currentPrice * 0.95; 
    
    for (int i = 0; i < 50; i++) {
      final variation = (i * (currentPrice - basePrice) / 49) + 
                       (i * 0.01 * (i % 3 == 0 ? 1 : -1)) * currentPrice;
      data.add(basePrice + variation);
    }
    
    return data;
  }

  @override
  Future<void> refreshHomeData() async {
    
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<double>> getBitcoinHistoricalData(String period, {String currency = 'usd'}) async {
    try {
      
      final apiDays = _periodToApiDays(period);
      debugPrint('DEBUG: Period $period -> API days: $apiDays, currency: $currency');
      
      
      final historicalData = await _coinGeckoApi.getBitcoinHistoricalData(
        days: apiDays,
        currency: currency.toLowerCase(),
      );
      
      debugPrint('DEBUG: Received ${historicalData.chartData.length} points for period $period in $currency');
      
      
      return historicalData.chartData;
    } catch (e) {
      
      debugPrint('DEBUG: Error fetching data for $period: $e');
      return _generateFallbackChartData(period);
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

  
  List<double> _generateFallbackChartData(String period) {
    final basePrice = 67000.0;
    final data = <double>[];
    
    
    int pointCount = switch (period) {
      '1D' => 24,   
      '1W' => 7*24, 
      '1M' => 30,   
      '3M' => 90,   
      '1Y' => 365,  
      _ => 50,
    };
    
    for (int i = 0; i < pointCount; i++) {
      final variation = (i * 45) + (i * 0.1 * (i % 3 == 0 ? 1 : -1)) * 200;
      data.add(basePrice + variation);
    }
    
    return data;
  }
}
