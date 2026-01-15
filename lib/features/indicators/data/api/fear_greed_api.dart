import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fear_greed_model.dart';

/// API client para o Fear and Greed Index
/// Fonte: https://api.alternative.me/
class FearGreedApi {
  static const String _baseUrl = 'https://api.alternative.me';
  static const Duration _timeout = Duration(seconds: 30);

  /// Busca o índice de medo e ganância
  /// 
  /// [limit]: Número de resultados (padrão: 1 para o mais recente)
  /// [dateFormat]: Formato da data ('us', 'cn', 'kr', 'world', ou vazio para unix timestamp)
  Future<FearGreedResponse> getFearGreedIndex({
    int limit = 1,
    String? dateFormat,
  }) async {
    try {
      // Monta a URL com parâmetros opcionais
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (dateFormat != null) 'date_format': dateFormat,
      };

      final uri = Uri.parse('$_baseUrl/fng/').replace(
        queryParameters: queryParams,
      );

      print('🔄 Buscando Fear & Greed Index: $uri');

      final response = await http
          .get(uri)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final fearGreedResponse = FearGreedResponse.fromJson(jsonData);
        
        print('✅ Fear & Greed Index obtido: ${fearGreedResponse.latest?.value} (${fearGreedResponse.latest?.valueClassification})');
        
        return fearGreedResponse;
      } else {
        throw Exception(
          'Erro ao buscar Fear & Greed Index: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erro ao buscar Fear & Greed Index: $e');
      rethrow;
    }
  }

  /// Busca histórico do índice (últimos N dias)
  Future<FearGreedResponse> getFearGreedHistory({
    int days = 30,
  }) async {
    return getFearGreedIndex(limit: days);
  }

  /// Busca todos os dados disponíveis
  Future<FearGreedResponse> getAllFearGreedData() async {
    return getFearGreedIndex(limit: 0);
  }
}
