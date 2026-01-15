
class BitcoinHistoricalPoint {
  final DateTime timestamp;
  final double price;
  final double? marketCap;
  final double? volume;

  const BitcoinHistoricalPoint({
    required this.timestamp,
    required this.price,
    this.marketCap,
    this.volume,
  });

  
  factory BitcoinHistoricalPoint.fromPriceArray(List<dynamic> priceArray) {
    return BitcoinHistoricalPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(priceArray[0] as int),
      price: (priceArray[1] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BitcoinHistoricalPoint(timestamp: $timestamp, price: $price)';
  }
}


class BitcoinHistoricalDataModel {
  final List<BitcoinHistoricalPoint> prices;
  final List<BitcoinHistoricalPoint> marketCaps;
  final List<BitcoinHistoricalPoint> totalVolumes;

  const BitcoinHistoricalDataModel({
    required this.prices,
    required this.marketCaps,
    required this.totalVolumes,
  });

  
  factory BitcoinHistoricalDataModel.fromJson(Map<String, dynamic> json) {
    return BitcoinHistoricalDataModel(
      prices: (json['prices'] as List<dynamic>)
          .map((priceArray) => BitcoinHistoricalPoint.fromPriceArray(priceArray))
          .toList(),
      marketCaps: (json['market_caps'] as List<dynamic>)
          .map((capArray) => BitcoinHistoricalPoint.fromPriceArray(capArray))
          .toList(),
      totalVolumes: (json['total_volumes'] as List<dynamic>)
          .map((volumeArray) => BitcoinHistoricalPoint.fromPriceArray(volumeArray))
          .toList(),
    );
  }

  
  List<double> get chartData => prices.map((point) => point.price).toList();

  @override
  String toString() {
    return 'BitcoinHistoricalDataModel(prices: ${prices.length} points, '
           'marketCaps: ${marketCaps.length} points, '
           'volumes: ${totalVolumes.length} points)';
  }
}