import '../../data/models/bitcoin_historical_data_model.dart';


class BitcoinData {
  final double currentPrice;
  final double changeAmount;
  final double changePercentage;
  final double maxPrice24h;
  final double minPrice24h;
  final double volume24h;
  final double marketCap;
  final double circulatingSupply;
  final double dominance;
  final String sentiment;
  final double change7d;
  final double change30d;
  final List<double> chartData;
  final BitcoinHistoricalDataModel? historicalData; 

  const BitcoinData({
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercentage,
    required this.maxPrice24h,
    required this.minPrice24h,
    required this.volume24h,
    required this.marketCap,
    required this.circulatingSupply,
    required this.dominance,
    required this.sentiment,
    required this.change7d,
    required this.change30d,
    required this.chartData,
    this.historicalData,
  });

  
  BitcoinData copyWith({
    double? currentPrice,
    double? changeAmount,
    double? changePercentage,
    double? maxPrice24h,
    double? minPrice24h,
    double? volume24h,
    double? marketCap,
    double? circulatingSupply,
    double? dominance,
    String? sentiment,
    double? change7d,
    double? change30d,
    List<double>? chartData,
    BitcoinHistoricalDataModel? historicalData,
  }) {
    return BitcoinData(
      currentPrice: currentPrice ?? this.currentPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercentage: changePercentage ?? this.changePercentage,
      maxPrice24h: maxPrice24h ?? this.maxPrice24h,
      minPrice24h: minPrice24h ?? this.minPrice24h,
      volume24h: volume24h ?? this.volume24h,
      marketCap: marketCap ?? this.marketCap,
      circulatingSupply: circulatingSupply ?? this.circulatingSupply,
      dominance: dominance ?? this.dominance,
      sentiment: sentiment ?? this.sentiment,
      change7d: change7d ?? this.change7d,
      change30d: change30d ?? this.change30d,
      chartData: chartData ?? this.chartData,
      historicalData: historicalData ?? this.historicalData,
    );
  }
}



class HomeData {
  final String title;
  final String subtitle;
  final DateTime lastUpdated;
  final bool isLoading;
  final BitcoinData? bitcoinData;

  const HomeData({
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    this.isLoading = false,
    this.bitcoinData,
  });

  HomeData copyWith({String? title, String? subtitle, DateTime? lastUpdated, bool? isLoading, BitcoinData? bitcoinData}) {
    return HomeData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      bitcoinData: bitcoinData ?? this.bitcoinData,
    );
  }
}
