/// Modelo de dados que representa a resposta da API do CoinGecko
class BitcoinPriceModel {
  final double usd;
  final double brl;
  final double? eur;
  final double? gbp;
  final double? jpy;
  final double usd24hChange; // Mudança percentual em 24h
  final double brl24hChange; // Mudança percentual em 24h (BRL)
  final double? eur24hChange; // Mudança percentual em 24h (EUR)
  final double? gbp24hChange; // Mudança percentual em 24h (GBP)
  final double? jpy24hChange; // Mudança percentual em 24h (JPY)
  final double? marketCap;   // Market Cap em USD
  final double? volume24h;   // Volume 24h em USD
  final double? high24h;     // Máxima 24h
  final double? low24h;      // Mínima 24h
  final String baseCurrency; // Moeda base para exibição

  const BitcoinPriceModel({
    required this.usd,
    required this.brl,
    this.eur,
    this.gbp,
    this.jpy,
    required this.usd24hChange,
    required this.brl24hChange,
    this.eur24hChange,
    this.gbp24hChange,
    this.jpy24hChange,
    this.marketCap,
    this.volume24h,
    this.high24h,
    this.low24h,
    this.baseCurrency = 'USD',
  });

  /// Factory constructor para criar uma instância a partir do JSON da API
  factory BitcoinPriceModel.fromJson(Map<String, dynamic> json, {String baseCurrency = 'USD'}) {
    final bitcoinData = json['bitcoin'] as Map<String, dynamic>;
    
    return BitcoinPriceModel(
      usd: (bitcoinData['usd'] as num).toDouble(),
      brl: (bitcoinData['brl'] as num).toDouble(),
      eur: (bitcoinData['eur'] as num?)?.toDouble(),
      gbp: (bitcoinData['gbp'] as num?)?.toDouble(),
      jpy: (bitcoinData['jpy'] as num?)?.toDouble(),
      usd24hChange: (bitcoinData['usd_24h_change'] as num?)?.toDouble() ?? 0.0,
      brl24hChange: (bitcoinData['brl_24h_change'] as num?)?.toDouble() ?? 0.0,
      eur24hChange: (bitcoinData['eur_24h_change'] as num?)?.toDouble(),
      gbp24hChange: (bitcoinData['gbp_24h_change'] as num?)?.toDouble(),
      jpy24hChange: (bitcoinData['jpy_24h_change'] as num?)?.toDouble(),
      marketCap: (bitcoinData['usd_market_cap'] as num?)?.toDouble(),
      volume24h: (bitcoinData['usd_24h_vol'] as num?)?.toDouble(),
      high24h: (bitcoinData['usd_24h_high'] as num?)?.toDouble(),
      low24h: (bitcoinData['usd_24h_low'] as num?)?.toDouble(),
      baseCurrency: baseCurrency,
    );
  }

  /// Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'bitcoin': {
        'usd': usd,
        'brl': brl,
        'eur': eur,
        'gbp': gbp,
        'jpy': jpy,
        'usd_24h_change': usd24hChange,
        'brl_24h_change': brl24hChange,
        'eur_24h_change': eur24hChange,
        'gbp_24h_change': gbp24hChange,
        'jpy_24h_change': jpy24hChange,
        'usd_market_cap': marketCap,
        'usd_24h_vol': volume24h,
      },
      'base_currency': baseCurrency,
    };
  }

  /// Retorna o preço na moeda base
  double get baseCurrencyPrice {
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return usd;
      case 'brl':
        return brl;
      case 'eur':
        return eur ?? usd;
      case 'gbp':
        return gbp ?? usd;
      case 'jpy':
        return jpy ?? usd;
      default:
        return usd;
    }
  }

  /// Retorna a mudança percentual na moeda base
  double get baseCurrencyChange {
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return usd24hChange;
      case 'brl':
        return brl24hChange;
      case 'eur':
        return eur24hChange ?? usd24hChange;
      case 'gbp':
        return gbp24hChange ?? usd24hChange;
      case 'jpy':
        return jpy24hChange ?? usd24hChange;
      default:
        return usd24hChange;
    }
  }

  /// Retorna o volume 24h na moeda base selecionada
  double get baseCurrencyVolume24h {
    if (volume24h == null) return 0.0;
    
    // Volume está sempre em USD, então convertemos para a moeda base
    final volumeUSD = volume24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return volumeUSD;
      case 'brl':
        // Converte USD para BRL usando a taxa de câmbio atual
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return volumeUSD * usdToBrlRate;
        }
        return volumeUSD;
      case 'eur':
        // Converte USD para EUR usando a taxa de câmbio atual
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return volumeUSD * usdToEurRate;
        }
        return volumeUSD;
      case 'gbp':
        // Converte USD para GBP usando a taxa de câmbio atual
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return volumeUSD * usdToGbpRate;
        }
        return volumeUSD;
      case 'jpy':
        // Converte USD para JPY usando a taxa de câmbio atual
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return volumeUSD * usdToJpyRate;
        }
        return volumeUSD;
      default:
        return volumeUSD;
    }
  }

  /// Retorna o market cap na moeda base selecionada
  double get baseCurrencyMarketCap {
    if (marketCap == null) return 0.0;
    
    // Market Cap está sempre em USD, então convertemos para a moeda base
    final marketCapUSD = marketCap!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return marketCapUSD;
      case 'brl':
        // Converte USD para BRL usando a taxa de câmbio atual
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return marketCapUSD * usdToBrlRate;
        }
        return marketCapUSD;
      case 'eur':
        // Converte USD para EUR usando a taxa de câmbio atual
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return marketCapUSD * usdToEurRate;
        }
        return marketCapUSD;
      case 'gbp':
        // Converte USD para GBP usando a taxa de câmbio atual
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return marketCapUSD * usdToGbpRate;
        }
        return marketCapUSD;
      case 'jpy':
        // Converte USD para JPY usando a taxa de câmbio atual
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return marketCapUSD * usdToJpyRate;
        }
        return marketCapUSD;
      default:
        return marketCapUSD;
    }
  }

  /// Retorna a máxima 24h na moeda base selecionada
  double? get baseCurrencyHigh24h {
    if (high24h == null) return null;
    
    // High24h está sempre em USD, então convertemos para a moeda base
    final high24hUSD = high24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return high24hUSD;
      case 'brl':
        // Converte USD para BRL usando a taxa de câmbio atual
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return high24hUSD * usdToBrlRate;
        }
        return high24hUSD;
      case 'eur':
        // Converte USD para EUR usando a taxa de câmbio atual
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return high24hUSD * usdToEurRate;
        }
        return high24hUSD;
      case 'gbp':
        // Converte USD para GBP usando a taxa de câmbio atual
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return high24hUSD * usdToGbpRate;
        }
        return high24hUSD;
      case 'jpy':
        // Converte USD para JPY usando a taxa de câmbio atual
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return high24hUSD * usdToJpyRate;
        }
        return high24hUSD;
      default:
        return high24hUSD;
    }
  }

  /// Retorna a mínima 24h na moeda base selecionada
  double? get baseCurrencyLow24h {
    if (low24h == null) return null;
    
    // Low24h está sempre em USD, então convertemos para a moeda base
    final low24hUSD = low24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return low24hUSD;
      case 'brl':
        // Converte USD para BRL usando a taxa de câmbio atual
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return low24hUSD * usdToBrlRate;
        }
        return low24hUSD;
      case 'eur':
        // Converte USD para EUR usando a taxa de câmbio atual
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return low24hUSD * usdToEurRate;
        }
        return low24hUSD;
      case 'gbp':
        // Converte USD para GBP usando a taxa de câmbio atual
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return low24hUSD * usdToGbpRate;
        }
        return low24hUSD;
      case 'jpy':
        // Converte USD para JPY usando a taxa de câmbio atual
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return low24hUSD * usdToJpyRate;
        }
        return low24hUSD;
      default:
        return low24hUSD;
    }
  }

  /// Indica se o preço está em alta (positivo) na moeda base
  bool get isPositive => baseCurrencyChange > 0;

  /// Indica se o preço está em baixa (negativo) na moeda base
  bool get isNegative => baseCurrencyChange < 0;

  @override
  String toString() {
    return 'BitcoinPriceModel(baseCurrency: $baseCurrency, price: ${baseCurrencyPrice.toStringAsFixed(2)}, change: ${baseCurrencyChange.toStringAsFixed(2)}%, marketCap: $marketCap, volume24h: $volume24h)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BitcoinPriceModel && 
           other.usd == usd && 
           other.brl == brl &&
           other.eur == eur &&
           other.gbp == gbp &&
           other.jpy == jpy &&
           other.baseCurrency == baseCurrency &&
           other.marketCap == marketCap &&
           other.volume24h == volume24h;
  }

  @override
  int get hashCode => 
      usd.hashCode ^ 
      brl.hashCode ^ 
      (eur?.hashCode ?? 0) ^
      (gbp?.hashCode ?? 0) ^
      (jpy?.hashCode ?? 0) ^
      baseCurrency.hashCode ^
      (marketCap?.hashCode ?? 0) ^ 
      (volume24h?.hashCode ?? 0);
}