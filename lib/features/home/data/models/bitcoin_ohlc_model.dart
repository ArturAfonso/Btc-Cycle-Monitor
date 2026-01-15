
class BitcoinOHLCCandle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  const BitcoinOHLCCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  
  
  factory BitcoinOHLCCandle.fromJson(List<dynamic> ohlcArray) {
    if (ohlcArray.length != 5) {
      throw FormatException('OHLC array deve ter 5 elementos: [timestamp, open, high, low, close]');
    }

    return BitcoinOHLCCandle(
      timestamp: DateTime.fromMillisecondsSinceEpoch(ohlcArray[0] as int),
      open: (ohlcArray[1] as num).toDouble(),
      high: (ohlcArray[2] as num).toDouble(),
      low: (ohlcArray[3] as num).toDouble(),
      close: (ohlcArray[4] as num).toDouble(),
    );
  }

  
  double get closePrice => close;

  
  double get changePercent => ((close - open) / open) * 100;

  
  bool get isBullish => close > open;

  
  bool get isBearish => close < open;

  @override
  String toString() {
    return 'BitcoinOHLCCandle('
           'timestamp: $timestamp, '
           'open: ${open.toStringAsFixed(2)}, '
           'high: ${high.toStringAsFixed(2)}, '
           'low: ${low.toStringAsFixed(2)}, '
           'close: ${close.toStringAsFixed(2)}'
           ')';
  }

  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
    };
  }
}


class BitcoinOHLCModel {
  final List<BitcoinOHLCCandle> candles;

  const BitcoinOHLCModel({required this.candles});

  
  
  factory BitcoinOHLCModel.fromJson(List<dynamic> json) {
    return BitcoinOHLCModel(
      candles: json
          .map((candleArray) => BitcoinOHLCCandle.fromJson(candleArray))
          .toList(),
    );
  }

  
  List<double> get closePrices => candles.map((c) => c.close).toList();

  
  BitcoinOHLCCandle? get latest => candles.isNotEmpty ? candles.last : null;

  
  BitcoinOHLCCandle? get oldest => candles.isNotEmpty ? candles.first : null;

  
  int get length => candles.length;

  
  List<BitcoinOHLCCandle> getLastN(int n) {
    if (candles.length <= n) return candles;
    return candles.sublist(candles.length - n);
  }

  
  List<double> getLastNClosePrices(int n) {
    final lastCandles = getLastN(n);
    return lastCandles.map((c) => c.close).toList();
  }

  @override
  String toString() {
    return 'BitcoinOHLCModel(candles: ${candles.length}, '
           'range: ${oldest?.timestamp} → ${latest?.timestamp})';
  }
}
