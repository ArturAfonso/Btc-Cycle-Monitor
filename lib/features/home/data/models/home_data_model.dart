import '../../domain/entities/home_data.dart';


class BitcoinDataModel extends BitcoinData {
  const BitcoinDataModel({
    required super.currentPrice,
    required super.changeAmount,
    required super.changePercentage,
    required super.maxPrice24h,
    required super.minPrice24h,
    required super.volume24h,
    required super.marketCap,
    required super.circulatingSupply,
    required super.dominance,
    required super.sentiment,
    required super.change7d,
    required super.change30d,
    required super.chartData,
  });

  factory BitcoinDataModel.fromJson(Map<String, dynamic> json) {
    return BitcoinDataModel(
      currentPrice: (json['currentPrice'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      changePercentage: (json['changePercentage'] as num).toDouble(),
      maxPrice24h: (json['maxPrice24h'] as num).toDouble(),
      minPrice24h: (json['minPrice24h'] as num).toDouble(),
      volume24h: (json['volume24h'] as num).toDouble(),
      marketCap: (json['marketCap'] as num).toDouble(),
      circulatingSupply: (json['circulatingSupply'] as num).toDouble(),
      dominance: (json['dominance'] as num).toDouble(),
      sentiment: json['sentiment'] as String,
      change7d: (json['change7d'] as num).toDouble(),
      change30d: (json['change30d'] as num).toDouble(),
      chartData: (json['chartData'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}



class HomeDataModel extends HomeData {
  const HomeDataModel({
    required super.title,
    required super.subtitle,
    required super.lastUpdated,
    super.isLoading,
    super.bitcoinData,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      bitcoinData: json['bitcoinData'] != null 
          ? BitcoinDataModel.fromJson(json['bitcoinData']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isLoading': isLoading,
    };
  }

  factory HomeDataModel.fromEntity(HomeData entity) {
    return HomeDataModel(
      title: entity.title,
      subtitle: entity.subtitle,
      lastUpdated: entity.lastUpdated,
      isLoading: entity.isLoading,
      bitcoinData: entity.bitcoinData,
    );
  }
}
