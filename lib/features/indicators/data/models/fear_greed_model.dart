/// Modelo para o Índice de Medo e Ganância (Fear and Greed Index)
class FearGreedModel {
  final int value;
  final String valueClassification;
  final String timestamp;
  final String? timeUntilUpdate;

  FearGreedModel({
    required this.value,
    required this.valueClassification,
    required this.timestamp,
    this.timeUntilUpdate,
  });

  factory FearGreedModel.fromJson(Map<String, dynamic> json) {
    return FearGreedModel(
      value: int.parse(json['value'] as String),
      valueClassification: json['value_classification'] as String,
      timestamp: json['timestamp'] as String,
      timeUntilUpdate: json['time_until_update'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value.toString(),
      'value_classification': valueClassification,
      'timestamp': timestamp,
      if (timeUntilUpdate != null) 'time_until_update': timeUntilUpdate,
    };
  }

  /// Retorna a data formatada a partir do timestamp Unix
  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(timestamp) * 1000,
    );
  }

  /// Retorna a cor baseada no valor
  /// 0-24: Extreme Fear (vermelho escuro)
  /// 25-44: Fear (vermelho)
  /// 45-55: Neutral (amarelo)
  /// 56-75: Greed (verde claro)
  /// 76-100: Extreme Greed (verde escuro)
  String get colorHex {
    if (value <= 24) return '#C53030'; // Extreme Fear
    if (value <= 44) return '#E53E3E'; // Fear
    if (value <= 55) return '#FFB800'; // Neutral
    if (value <= 75) return '#48BB78'; // Greed
    return '#22C55E'; // Extreme Greed
  }

  /// Retorna a classificação traduzida para português
  /// Valores possíveis da API:
  /// - "Extreme Fear" → "Medo Extremo"
  /// - "Fear" → "Medo"
  /// - "Neutral" → "Neutro"
  /// - "Greed" → "Ganância"
  /// - "Extreme Greed" → "Ganância Extrema"
  String get classificationPtBr {
    final Map<String, String> translations = {
      'Extreme Fear': 'Medo Extremo',
      'Fear': 'Medo',
      'Neutral': 'Neutro',
      'Greed': 'Ganância',
      'Extreme Greed': 'Ganância Extrema',
    };

    return translations[valueClassification] ?? valueClassification;
  }

  @override
  String toString() {
    return 'FearGreedModel(value: $value, classification: $valueClassification)';
  }
}

/// Response wrapper da API
class FearGreedResponse {
  final String name;
  final List<FearGreedModel> data;
  final Map<String, dynamic> metadata;

  FearGreedResponse({
    required this.name,
    required this.data,
    required this.metadata,
  });

  factory FearGreedResponse.fromJson(Map<String, dynamic> json) {
    return FearGreedResponse(
      name: json['name'] as String,
      data: (json['data'] as List)
          .map((item) => FearGreedModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  /// Retorna o dado mais recente (primeiro da lista)
  FearGreedModel? get latest => data.isNotEmpty ? data.first : null;
}
