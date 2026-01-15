import 'package:flutter/material.dart';

/// Modelo para dados de dominância do Bitcoin
class BitcoinDominanceModel {
  final double btcDominance;
  final double ethDominance;
  final int activeCryptocurrencies;
  final int markets;
  final DateTime lastUpdated;

  const BitcoinDominanceModel({
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCryptocurrencies,
    required this.markets,
    required this.lastUpdated,
  });

  factory BitcoinDominanceModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final marketCapPercentage = data['market_cap_percentage'] as Map<String, dynamic>;
    
    return BitcoinDominanceModel(
      btcDominance: (marketCapPercentage['btc'] as num).toDouble(),
      ethDominance: (marketCapPercentage['eth'] as num).toDouble(),
      activeCryptocurrencies: data['active_cryptocurrencies'] as int,
      markets: data['markets'] as int,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch((data['updated_at'] as int) * 1000),
    );
  }

  /// Retorna a interpretação do estado da dominância
  String get dominanceStatus {
    if (btcDominance >= 65) {
      return 'extreme_fear'; // Medo extremo - todos fugindo para BTC
    } else if (btcDominance >= 55) {
      return 'fear'; // Medo - preferência pelo BTC
    } else if (btcDominance >= 45) {
      return 'neutral'; // Neutro
    } else if (btcDominance >= 35) {
      return 'greed'; // Ganância - dinheiro indo para altcoins
    } else {
      return 'extreme_greed'; // Ganância extrema - altseason total
    }
  }

  /// Retorna a mensagem interpretativa
  String get dominanceMessage {
    switch (dominanceStatus) {
      case 'extreme_fear':
        return 'Medo Extremo - Fuga para Bitcoin';
      case 'fear':
        return 'Medo - Preferência pelo Bitcoin';
      case 'neutral':
        return 'Neutro - Equilíbrio no mercado';
      case 'greed':
        return 'Ganância - Dinheiro fluindo para altcoins';
      case 'extreme_greed':
        return 'Ganância Extrema - Altseason';
      default:
        return 'Análise indisponível';
    }
  }

  /// Retorna a cor correspondente ao status
  Color get statusColor {
    switch (dominanceStatus) {
      case 'extreme_fear':
        return const Color(0xFF3B82F6); // Azul
      case 'fear':
        return const Color(0xFF06B6D4); // Ciano
      case 'neutral':
        return const Color(0xFFFFB800); // Amarelo
      case 'greed':
        return const Color(0xFFEAB308); // Laranja
      case 'extreme_greed':
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF6B7280); // Cinza
    }
  }

  /// Converte dominância para porcentagem de proximidade ao ciclo
  /// Dominância alta = início de ciclo (0%), dominância baixa = fim de ciclo (100%)
  double get cycleProximityPercentage {
    // Inverte a lógica: dominância alta = baixa proximidade ao topo
    // Dominância baixa = alta proximidade ao topo
    if (btcDominance >= 70) return 0; // Muito longe do topo
    if (btcDominance <= 30) return 100; // Muito próximo do topo
    
    // Mapeia 70% -> 0% e 30% -> 100%
    return ((70 - btcDominance) / 40) * 100;
  }

  @override
  String toString() {
    return 'BitcoinDominanceModel(btcDominance: $btcDominance%, ethDominance: $ethDominance%, status: $dominanceStatus)';
  }
}