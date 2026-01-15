import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/bitcoin_price_model.dart';
import '../models/bitcoin_historical_data_model.dart';
import '../models/bitcoin_ohlc_model.dart';
import '../../../indicators/data/models/bitcoin_dominance_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

class CoinGeckoApi {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static final String _apiKey = dotenv.env['COINGECKO_API_KEY'] ?? '';
  static const Duration _timeout = Duration(seconds: 30);

  static const Map<String, String> _supportedCurrencies = {
    'USD': 'usd',
    'EUR': 'eur',
    'BRL': 'brl',
    'GBP': 'gbp',
    'JPY': 'jpy',
  };

  static const Map<String, String> _currencySymbols = {'USD': '\$', 'EUR': '€', 'BRL': 'R\$', 'GBP': '£', 'JPY': '¥'};

  final http.Client _httpClient;

  CoinGeckoApi({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> get _defaultHeaders => {'Content-Type': 'application/json', 'x-cg-demo-api-key': _apiKey};

  Future<BitcoinPriceModel> getBitcoinPrice({String currency = 'usd'}) async {
    try {
      debugPrint('📊 [API] Buscando cotação atual do Bitcoin em ${currency.toUpperCase()}...');

      final currencies = _getSupportedCurrencies(currency);
      final url = Uri.parse(
        '$_baseUrl/simple/price?ids=bitcoin&vs_currencies=$currencies&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_24hr_high_low=true',
      );

      final response = await _httpClient.get(url, headers: _defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final bitcoinPrice = BitcoinPriceModel.fromJson(jsonData, baseCurrency: currency);

        final symbol = _getCurrencySymbol(currency);
        final price = _getPriceInCurrency(bitcoinPrice, currency);
        final change = _getChangeInCurrency(bitcoinPrice, currency);
        debugPrint(
          '✅ [API] Cotação atual obtida: $symbol${price.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)',
        );

        return bitcoinPrice;
      } else if (response.statusCode == 429) {
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        throw ApiException('Erro ao buscar dados do Bitcoin: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      debugPrint('⏰ [API] Timeout ao buscar cotação atual');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      debugPrint('🌐 [API] Erro de conexão ao buscar cotação atual');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      debugPrint('⚠️ [API] Erro ao processar resposta da cotação: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      debugPrint('❌ [API] Erro inesperado ao buscar cotação: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<BitcoinHistoricalDataModel> getBitcoinHistoricalData({required String days, String currency = 'usd'}) async {
    try {
      debugPrint('📈 [API] Buscando dados históricos do Bitcoin para período: $days dias...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin/market_chart?vs_currency=$currency&days=$days');

      final response = await _httpClient.get(url, headers: _defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final historicalData = BitcoinHistoricalDataModel.fromJson(jsonData);

        debugPrint('✅ [API] Dados históricos obtidos: ${historicalData.prices.length} pontos de preço para $days dias');
        if (historicalData.prices.isNotEmpty) {
          final firstPrice = historicalData.prices.first.price;
          final lastPrice = historicalData.prices.last.price;
          final change = ((lastPrice - firstPrice) / firstPrice * 100);
          debugPrint(
            '📊 [API] Range: \$${firstPrice.toStringAsFixed(2)} → \$${lastPrice.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)',
          );
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
      debugPrint('⏰ [API] Timeout ao buscar dados históricos');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      debugPrint('🌐 [API] Erro de conexão ao buscar dados históricos');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      debugPrint('⚠️ [API] Erro ao processar resposta dos dados históricos: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      debugPrint('❌ [API] Erro inesperado ao buscar dados históricos: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<BitcoinOHLCModel> getBitcoinOHLC({required int days, String currency = 'usd'}) async {
    try {
      debugPrint('🕯️ [API] Buscando dados OHLC do Bitcoin para $days dias...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin/ohlc?vs_currency=$currency&days=$days');

      final response = await _httpClient.get(url, headers: _defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List<dynamic>;
        final ohlcData = BitcoinOHLCModel.fromJson(jsonData);

        debugPrint('✅ [API] Dados OHLC obtidos: ${ohlcData.length} candles para $days dias');
        if (ohlcData.latest != null && ohlcData.oldest != null) {
          final latestClose = ohlcData.latest!.close;
          final oldestClose = ohlcData.oldest!.close;
          final change = ((latestClose - oldestClose) / oldestClose * 100);
          debugPrint(
            '📊 [API] Range Close: \$${oldestClose.toStringAsFixed(2)} → \$${latestClose.toStringAsFixed(2)} (${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%)',
          );
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
      debugPrint('⏰ [API] Timeout ao buscar dados OHLC');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      debugPrint('🌐 [API] Erro de conexão ao buscar dados OHLC');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      debugPrint('⚠️ [API] Erro ao processar resposta dos dados OHLC: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      debugPrint('❌ [API] Erro inesperado ao buscar dados OHLC: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  Future<BitcoinDominanceModel> getGlobalMarketData() async {
    try {
      debugPrint('🌍 [API] Buscando dados globais do mercado...');
      final url = Uri.parse('$_baseUrl/global');

      final response = await _httpClient.get(url, headers: _defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final globalData = BitcoinDominanceModel.fromJson(jsonData);

        debugPrint('✅ [API] Dados globais obtidos: BTC Dominance ${globalData.btcDominance.toStringAsFixed(2)}%');
        debugPrint('📊 [API] Status interpretado: ${globalData.dominanceMessage}');

        return globalData;
      } else if (response.statusCode == 429) {
        throw ApiException('Limite de requisições excedido. Tente novamente em alguns minutos.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Erro no servidor da CoinGecko. Tente novamente mais tarde.', response.statusCode);
      } else {
        throw ApiException('Erro ao buscar dados globais: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      debugPrint('⏰ [API] Timeout ao buscar dados globais');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      debugPrint('🌐 [API] Erro de conexão ao buscar dados globais');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } on FormatException catch (e) {
      debugPrint('⚠️ [API] Erro ao processar resposta dos dados globais: ${e.message}');
      throw ApiException('Erro ao processar resposta da API: ${e.message}');
    } catch (e) {
      debugPrint('❌ [API] Erro inesperado ao buscar dados globais: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }

  Future<Map<String, dynamic>> getBitcoinDetailedInfo() async {
    try {
      debugPrint('📊 [API] Buscando informações detalhadas do Bitcoin...');
      final url = Uri.parse('$_baseUrl/coins/bitcoin');

      final response = await _httpClient.get(url, headers: _defaultHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final marketData = jsonData['market_data'] as Map<String, dynamic>;

        final circulatingSupply = (marketData['circulating_supply'] as num?)?.toDouble();
        final totalSupply = (marketData['total_supply'] as num?)?.toDouble();

        debugPrint(
          '✅ [API] Fornecimento circulante: ${circulatingSupply != null ? (circulatingSupply / 1e6).toStringAsFixed(2) : 'N/A'}M BTC',
        );

        return {'circulating_supply': circulatingSupply, 'total_supply': totalSupply};
      } else {
        throw ApiException('Erro ao buscar informações detalhadas: ${response.reasonPhrase}', response.statusCode);
      }
    } on TimeoutException {
      debugPrint('⏰ [API] Timeout ao buscar informações detalhadas');
      throw TimeoutApiException('Timeout ao conectar com a API. Verifique sua conexão.');
    } on http.ClientException {
      debugPrint('🌐 [API] Erro de conexão ao buscar informações detalhadas');
      throw NetworkException('Erro de conexão. Verifique sua internet.');
    } catch (e) {
      debugPrint('❌ [API] Erro inesperado ao buscar informações detalhadas: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Erro inesperado: $e');
    }
  }

  String _getSupportedCurrencies(String baseCurrency) {
    final normalizedCurrency = baseCurrency.toUpperCase();
    if (_supportedCurrencies.containsKey(normalizedCurrency)) {
      final currencies = <String>{_supportedCurrencies[normalizedCurrency]!, 'usd', 'brl'};
      return currencies.join(',');
    }

    return 'usd,brl';
  }

  String _getCurrencySymbol(String currency) {
    final normalizedCurrency = currency.toUpperCase();
    return _currencySymbols[normalizedCurrency] ?? '\$';
  }

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
