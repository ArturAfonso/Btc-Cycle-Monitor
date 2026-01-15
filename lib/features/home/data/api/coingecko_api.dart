import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/bitcoin_price_model.dart';
import '../models/bitcoin_historical_data_model.dart';
import '../models/bitcoin_ohlc_model.dart';
import '../../../indicators/data/models/bitcoin_dominance_model.dart';

/// Exceções específicas da API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class TimeoutApiException extends ApiException {
  const TimeoutApiException(super.message);
}

/// Client para comunicação com a API do CoinGecko
class CoinGeckoApi {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const String _apiKey = 'CG-zUhZDFh5BmiyNckxtu1NnmN6';
  static const Duration _timeout = Duration(seconds: 30);

  // Mapeamento de moedas suportadas
  static const Map<String, String> _supportedCurrencies = {
    'USD': 'usd',
    'EUR': 'eur',
    'BRL': 'brl',
    'GBP': 'gbp',
    'JPY': 'jpy',
  };
  
  // Símbolos das moedas
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'BRL': 'R\$',
    'GBP': '£',
    'JPY': '¥',
  };

  final http.Client _httpClient;

  CoinGeckoApi({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Headers padrão para todas as requisições
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'x-cg-demo-api-key': _apiKey,
  };

  /// Busca o preço atual do Bitcoin na moeda especificada com market cap e volume
  Future<BitcoinPriceModel> getBitcoinPrice({String currency = 'usd'}) async {
    try {
      print('📊 [API] Buscando cotação atual do Bitcoin em ${currency.toUpperCase()}...');
      
      // Suporte para múltiplas moedas
      final currencies = _getSupportedCurrencies(currency);
      final url = Uri.parse('$_baseUrl/simple/price?ids=bitcoin&vs_currencies=$currencies&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_24hr_high_low=true');
      
      final response = await _httpClient
          .get(url, headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final bitcoinPrice = BitcoinPriceModel.fromJson(jsonData, baseCurrency: currency);
        
        // Log com o valor atual na moeda selecionada
        final symbol = _getCurrencySymbol(currency);
        final price = _getPriceInCurrency(bitcoinPrice, currency);
        final change = _getChangeInCurrency(bitcoinPrice, currency);
        print('✅ [API] Cotação atual obtida: $symbol${price.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)');
        
        return bitcoinPrice;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        // Server error
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        // Other client errors
        throw ApiException('Erro ao buscar dados do Bitcoin: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      print('⏰ [API] Timeout ao buscar cotação atual');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      print('🌐 [API] Erro de conexão ao buscar cotação atual');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      print('⚠️ [API] Erro ao processar resposta da cotação: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      print('❌ [API] Erro inesperado ao buscar cotação: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  /// Busca dados históricos do Bitcoin para gráficos
  /// [days] - período em dias: 1, 7, 30, 365, 'max'
  /// [currency] - moeda de referência (padrão: usd)
  Future<BitcoinHistoricalDataModel> getBitcoinHistoricalData({
    required String days,
    String currency = 'usd',
  }) async {
    try {
      print('📈 [API] Buscando dados históricos do Bitcoin para período: $days dias...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin/market_chart?vs_currency=$currency&days=$days');
      
      final response = await _httpClient
          .get(url, headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final historicalData = BitcoinHistoricalDataModel.fromJson(jsonData);
        
        // Log dos dados históricos
        print('✅ [API] Dados históricos obtidos: ${historicalData.prices.length} pontos de preço para $days dias');
        if (historicalData.prices.isNotEmpty) {
          final firstPrice = historicalData.prices.first.price;
          final lastPrice = historicalData.prices.last.price;
          final change = ((lastPrice - firstPrice) / firstPrice * 100);
          print('📊 [API] Range: \$${firstPrice.toStringAsFixed(2)} → \$${lastPrice.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)');
        }
        
        return historicalData;
      } else if (response.statusCode == 429) {
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        throw ApiException('Erro ao buscar dados históricos: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      print('⏰ [API] Timeout ao buscar dados históricos');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      print('🌐 [API] Erro de conexão ao buscar dados históricos');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      print('⚠️ [API] Erro ao processar resposta dos dados históricos: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      print('❌ [API] Erro inesperado ao buscar dados históricos: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  /// Busca dados OHLC (Open, High, Low, Close) do Bitcoin
  /// 
  /// Intervalos de candles baseado em dias solicitados:
  /// - 1-2 dias: candles de 30 minutos (~48-96 pontos)
  /// - 3-30 dias: candles de 4 horas (~72-720 pontos)
  /// - 31-90 dias: candles de 4 horas (~186-540 pontos)
  /// - 91+ dias: candles de 4 dias (~23+ pontos por 90 dias)
  /// 
  /// [days] - período em dias
  /// [currency] - moeda de referência (padrão: usd)
  /// 
  /// Recomendação: Use days=90 para obter ~540 pontos (ideal para Pi Cycle Top com SMA 350)
  Future<BitcoinOHLCModel> getBitcoinOHLC({
    required int days,
    String currency = 'usd',
  }) async {
    try {
      print('🕯️ [API] Buscando dados OHLC do Bitcoin para $days dias...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin/ohlc?vs_currency=$currency&days=$days');
      
      final response = await _httpClient
          .get(url, headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List<dynamic>;
        final ohlcData = BitcoinOHLCModel.fromJson(jsonData);
        
        // Log dos dados OHLC
        print('✅ [API] Dados OHLC obtidos: ${ohlcData.length} candles para $days dias');
        if (ohlcData.latest != null && ohlcData.oldest != null) {
          final latestClose = ohlcData.latest!.close;
          final oldestClose = ohlcData.oldest!.close;
          final change = ((latestClose - oldestClose) / oldestClose * 100);
          print('📊 [API] Range Close: \$${oldestClose.toStringAsFixed(2)} → \$${latestClose.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)');
        }
        
        return ohlcData;
      } else if (response.statusCode == 429) {
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        throw ApiException('Erro ao buscar dados OHLC: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      print('⏰ [API] Timeout ao buscar dados OHLC');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      print('🌐 [API] Erro de conexão ao buscar dados OHLC');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      print('⚠️ [API] Erro ao processar resposta dos dados OHLC: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      print('❌ [API] Erro inesperado ao buscar dados OHLC: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  /// Busca dados globais do mercado de criptomoedas (dominância do Bitcoin)
  Future<BitcoinDominanceModel> getGlobalMarketData() async {
    try {
      print('🌍 [API] Buscando dados globais do mercado...');
      final url = Uri.parse('$_baseUrl/global');
      
      final response = await _httpClient
          .get(url, headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final globalData = BitcoinDominanceModel.fromJson(jsonData);
        
        // Log dos dados globais
        print('✅ [API] Dados globais obtidos: BTC Dominance ${globalData.btcDominance.toStringAsFixed(2)}%');
        print('📊 [API] Status interpretado: ${globalData.dominanceMessage}');
        
        return globalData;
      } else if (response.statusCode == 429) {
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        throw ApiException('Erro ao buscar dados globais: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      print('⏰ [API] Timeout ao buscar dados globais');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      print('🌐 [API] Erro de conexão ao buscar dados globais');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      print('⚠️ [API] Erro ao processar resposta dos dados globais: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      print('❌ [API] Erro inesperado ao buscar dados globais: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  /// Método para liberar recursos
  void dispose() {
    _httpClient.close();
  }

  /// Busca informações detalhadas do Bitcoin incluindo fornecimento circulante
  Future<Map<String, dynamic>> getBitcoinDetailedInfo() async {
    try {
      print('📊 [API] Buscando informações detalhadas do Bitcoin...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin');
      
      final response = await _httpClient
          .get(url, headers: _defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final marketData = jsonData['market_data'] as Map<String, dynamic>;
        
        final circulatingSupply = (marketData['circulating_supply'] as num?)?.toDouble();
        final totalSupply = (marketData['total_supply'] as num?)?.toDouble();
        
        print('✅ [API] Fornecimento circulante: ${circulatingSupply != null ? (circulatingSupply / 1e6).toStringAsFixed(2) : 'N/A'}M BTC');
        
        return {
          'circulating_supply': circulatingSupply,
          'total_supply': totalSupply,
        };
      } else {
        throw ApiException('Erro ao buscar informações detalhadas: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      print('⏰ [API] Timeout ao buscar informações detalhadas');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      print('🌐 [API] Erro de conexão ao buscar informações detalhadas');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      print('❌ [API] Erro inesperado ao buscar informações detalhadas: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  // Métodos auxiliares para suporte a múltiplas moedas

  /// Retorna as moedas suportadas em formato de string para a API
  String _getSupportedCurrencies(String baseCurrency) {
    final normalizedCurrency = baseCurrency.toUpperCase();
    if (_supportedCurrencies.containsKey(normalizedCurrency)) {
      // Retorna a moeda principal + USD e BRL para compatibilidade
      final currencies = <String>{
        _supportedCurrencies[normalizedCurrency]!,
        'usd',
        'brl'
      };
      return currencies.join(',');
    }
    // Fallback para USD se moeda não suportada
    return 'usd,brl';
  }

  /// Retorna o símbolo da moeda
  String _getCurrencySymbol(String currency) {
    final normalizedCurrency = currency.toUpperCase();
    return _currencySymbols[normalizedCurrency] ?? '\$';
  }

  /// Extrai o preço na moeda especificada do modelo
  double _getPriceInCurrency(BitcoinPriceModel model, String currency) {
    final normalizedCurrency = currency.toLowerCase();
    switch (normalizedCurrency) {
      case 'usd':
        return model.usd;
      case 'brl':
        return model.brl;
      case 'eur':
        return model.eur ?? model.usd;
      case 'gbp':
        return model.gbp ?? model.usd;
      case 'jpy':
        return model.jpy ?? model.usd;
      default:
        return model.usd;
    }
  }

  /// Extrai a mudança percentual na moeda especificada do modelo
  double _getChangeInCurrency(BitcoinPriceModel model, String currency) {
    final normalizedCurrency = currency.toLowerCase();
    switch (normalizedCurrency) {
      case 'usd':
        return model.usd24hChange;
      case 'brl':
        return model.brl24hChange;
      case 'eur':
        return model.eur24hChange ?? model.usd24hChange;
      case 'gbp':
        return model.gbp24hChange ?? model.usd24hChange;
      case 'jpy':
        return model.jpy24hChange ?? model.usd24hChange;
      default:
        return model.usd24hChange;
    }
  }
}