import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/fear_greed_model.dart';

class FearGreedApi {
  static const String _baseUrl = 'https://api.alternative.me';
  static const Duration _timeout = Duration(seconds: 30);

  Future<FearGreedResponse> getFearGreedIndex({int limit = 1, String? dateFormat}) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (dateFormat != null) 'date_format': dateFormat,
      };

      final uri = Uri.parse('$_baseUrl/fng/').replace(queryParameters: queryParams);

      debugPrint('🔄 Buscando Fear & Greed Index: $uri');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final fearGreedResponse = FearGreedResponse.fromJson(jsonData);

        debugPrint(
          '✅ Fear & Greed Index obtido: ${fearGreedResponse.latest?.value} (${fearGreedResponse.latest?.valueClassification})',
        );

        return fearGreedResponse;
      } else {
        throw Exception('Erro ao buscar Fear & Greed Index: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar Fear & Greed Index: $e');
      rethrow;
    }
  }

  Future<FearGreedResponse> getFearGreedHistory({int days = 30}) async {
    return getFearGreedIndex(limit: days);
  }

  Future<FearGreedResponse> getAllFearGreedData() async {
    return getFearGreedIndex(limit: 0);
  }
}
