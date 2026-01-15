
class BitcoinPriceModel {
  final double usd;
  final double brl;
  final double? eur;
  final double? gbp;
  final double? jpy;
  final double usd24hChange; 
  final double brl24hChange; 
  final double? eur24hChange; 
  final double? gbp24hChange; 
  final double? jpy24hChange; 
  final double? marketCap;   
  final double? volume24h;   
  final double? high24h;     
  final double? low24h;      
  final String baseCurrency; 

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

  
  double get baseCurrencyVolume24h {
    if (volume24h == null) return 0.0;
    
    
    final volumeUSD = volume24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return volumeUSD;
      case 'brl':
        
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return volumeUSD * usdToBrlRate;
        }
        return volumeUSD;
      case 'eur':
        
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return volumeUSD * usdToEurRate;
        }
        return volumeUSD;
      case 'gbp':
        
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return volumeUSD * usdToGbpRate;
        }
        return volumeUSD;
      case 'jpy':
        
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return volumeUSD * usdToJpyRate;
        }
        return volumeUSD;
      default:
        return volumeUSD;
    }
  }

  
  double get baseCurrencyMarketCap {
    if (marketCap == null) return 0.0;
    
    
    final marketCapUSD = marketCap!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return marketCapUSD;
      case 'brl':
        
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return marketCapUSD * usdToBrlRate;
        }
        return marketCapUSD;
      case 'eur':
        
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return marketCapUSD * usdToEurRate;
        }
        return marketCapUSD;
      case 'gbp':
        
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return marketCapUSD * usdToGbpRate;
        }
        return marketCapUSD;
      case 'jpy':
        
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return marketCapUSD * usdToJpyRate;
        }
        return marketCapUSD;
      default:
        return marketCapUSD;
    }
  }

  
  double? get baseCurrencyHigh24h {
    if (high24h == null) return null;
    
    
    final high24hUSD = high24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return high24hUSD;
      case 'brl':
        
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return high24hUSD * usdToBrlRate;
        }
        return high24hUSD;
      case 'eur':
        
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return high24hUSD * usdToEurRate;
        }
        return high24hUSD;
      case 'gbp':
        
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return high24hUSD * usdToGbpRate;
        }
        return high24hUSD;
      case 'jpy':
        
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return high24hUSD * usdToJpyRate;
        }
        return high24hUSD;
      default:
        return high24hUSD;
    }
  }

  
  double? get baseCurrencyLow24h {
    if (low24h == null) return null;
    
    
    final low24hUSD = low24h!;
    
    switch (baseCurrency.toLowerCase()) {
      case 'usd':
        return low24hUSD;
      case 'brl':
        
        if (brl > 0 && usd > 0) {
          final usdToBrlRate = brl / usd;
          return low24hUSD * usdToBrlRate;
        }
        return low24hUSD;
      case 'eur':
        
        if (eur != null && eur! > 0 && usd > 0) {
          final usdToEurRate = eur! / usd;
          return low24hUSD * usdToEurRate;
        }
        return low24hUSD;
      case 'gbp':
        
        if (gbp != null && gbp! > 0 && usd > 0) {
          final usdToGbpRate = gbp! / usd;
          return low24hUSD * usdToGbpRate;
        }
        return low24hUSD;
      case 'jpy':
        
        if (jpy != null && jpy! > 0 && usd > 0) {
          final usdToJpyRate = jpy! / usd;
          return low24hUSD * usdToJpyRate;
        }
        return low24hUSD;
      default:
        return low24hUSD;
    }
  }

  
  bool get isPositive => baseCurrencyChange > 0;

  
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