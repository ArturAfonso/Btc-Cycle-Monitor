/// Modelo para um candle OHLC (Open, High, Low, Close)
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

  /// Factory para criar a partir do array da API CoinGecko
  /// Formato: [timestamp_ms, open, high, low, close]
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

  /// Retorna apenas o preço de fechamento (usado para cálculos de SMA)
  double get closePrice => close;

  /// Retorna a variação percentual do candle
  double get changePercent => ((close - open) / open) * 100;

  /// Retorna se o candle é bullish (alta)
  bool get isBullish => close > open;

  /// Retorna se o candle é bearish (baixa)
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

  /// Converte para JSON
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

/// Modelo para resposta completa de dados OHLC
class BitcoinOHLCModel {
  final List<BitcoinOHLCCandle> candles;

  const BitcoinOHLCModel({required this.candles});

  /// Factory para criar a partir da resposta JSON da API
  /// Response é uma lista de arrays: [[timestamp, o, h, l, c], ...]
  factory BitcoinOHLCModel.fromJson(List<dynamic> json) {
    return BitcoinOHLCModel(
      candles: json
          .map((candleArray) => BitcoinOHLCCandle.fromJson(candleArray))
          .toList(),
    );
  }

  /// Retorna apenas os preços de fechamento (útil para cálculos de SMA)
  List<double> get closePrices => candles.map((c) => c.close).toList();

  /// Retorna o candle mais recente
  BitcoinOHLCCandle? get latest => candles.isNotEmpty ? candles.last : null;

  /// Retorna o candle mais antigo
  BitcoinOHLCCandle? get oldest => candles.isNotEmpty ? candles.first : null;

  /// Retorna a quantidade de candles
  int get length => candles.length;

  /// Retorna os últimos N candles
  List<BitcoinOHLCCandle> getLastN(int n) {
    if (candles.length <= n) return candles;
    return candles.sublist(candles.length - n);
  }

  /// Retorna os últimos N preços de fechamento
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
