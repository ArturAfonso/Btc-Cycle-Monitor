/// Calculadora de Pi Cycle Top
/// 
/// O Pi Cycle Top é um indicador técnico que historicamente detectou
/// topos de mercado do Bitcoin com alta precisão.
/// 
/// Metodologia:
/// - SMA 111: Média móvel simples de 111 dias
/// - SMA 350 x 2: Média móvel simples de 350 dias multiplicada por 2
/// - Sinal de Topo: Quando SMA 111 cruza acima de SMA 350 x 2
/// 
/// Fonte: https://www.lookintobitcoin.com/charts/pi-cycle-top-indicator/
class PiCycleTopCalculator {
  /// Calcula a média móvel simples (SMA) de uma lista de preços
  /// 
  /// [prices] - Lista de preços de fechamento (mais recente no final)
  /// [period] - Período da média móvel (ex: 111, 350)
  /// 
  /// Retorna null se não houver dados suficientes
  static double? calculateSMA(List<double> prices, int period) {
    if (prices.isEmpty || prices.length < period) {
      return null;
    }

    // Pega os últimos N preços
    final lastNPrices = prices.sublist(prices.length - period);
    
    // Calcula a média
    final sum = lastNPrices.reduce((a, b) => a + b);
    return sum / period;
  }

  /// Calcula ambas as médias móveis necessárias para o Pi Cycle Top
  /// 
  /// [closePrices] - Lista de preços de fechamento (mais recente no final)
  /// 
  /// Retorna um mapa com as chaves:
  /// - 'sma111': SMA de 111 dias
  /// - 'sma350': SMA de 350 dias
  /// - 'sma350x2': SMA de 350 dias multiplicada por 2
  /// - 'isValid': true se ambas as médias foram calculadas
  static Map<String, dynamic> calculatePiCycleIndicators(List<double> closePrices) {
    final sma111 = calculateSMA(closePrices, 111);
    final sma350 = calculateSMA(closePrices, 350);
    
    final result = <String, dynamic>{
      'sma111': sma111,
      'sma350': sma350,
      'sma350x2': sma350 != null ? sma350 * 2 : null,
      'isValid': sma111 != null && sma350 != null,
    };

    return result;
  }

  /// Detecta se houve um cruzamento (crossover) do Pi Cycle Top
  /// 
  /// [currentSma111] - Valor atual da SMA 111
  /// [currentSma350x2] - Valor atual da SMA 350 x 2
  /// [previousSma111] - Valor anterior da SMA 111
  /// [previousSma350x2] - Valor anterior da SMA 350 x 2
  /// 
  /// Retorna:
  /// - 1: Cruzamento para cima (sinal de topo) 🔴
  /// - 0: Sem cruzamento
  /// - -1: Cruzamento para baixo (saindo do topo)
  static int detectCrossover({
    required double currentSma111,
    required double currentSma350x2,
    required double previousSma111,
    required double previousSma350x2,
  }) {
    final wasBelow = previousSma111 < previousSma350x2;
    final isAbove = currentSma111 > currentSma350x2;
    final wasAbove = previousSma111 > previousSma350x2;
    final isBelow = currentSma111 < currentSma350x2;

    if (wasBelow && isAbove) {
      return 1; // Cruzamento para cima - SINAL DE TOPO
    } else if (wasAbove && isBelow) {
      return -1; // Cruzamento para baixo - saindo do topo
    }
    
    return 0; // Sem cruzamento
  }

  /// Calcula a distância percentual entre SMA 111 e SMA 350 x 2
  /// 
  /// Útil para visualizar quão próximo está de um cruzamento
  /// 
  /// Retorna:
  /// - Valor positivo: SMA 111 está acima (possível topo)
  /// - Valor negativo: SMA 111 está abaixo (normal)
  static double calculateDistancePercentage({
    required double sma111,
    required double sma350x2,
  }) {
    return ((sma111 - sma350x2) / sma350x2) * 100;
  }

  /// Analisa o estado atual do indicador Pi Cycle Top
  /// 
  /// [closePrices] - Lista completa de preços de fechamento
  /// 
  /// Retorna um mapa com análise completa:
  /// - 'sma111': Valor atual da SMA 111
  /// - 'sma350x2': Valor atual da SMA 350 x 2
  /// - 'distance': Distância percentual entre as médias
  /// - 'status': 'top', 'approaching', 'normal', 'insufficient_data'
  /// - 'message': Mensagem descritiva em português
  static Map<String, dynamic> analyzeCurrentState(List<double> closePrices) {
    final indicators = calculatePiCycleIndicators(closePrices);
    
    if (!indicators['isValid']) {
      return {
        'status': 'insufficient_data',
        'message': 'Dados insuficientes. Necessário pelo menos 350 dias de histórico.',
        'sma111': null,
        'sma350x2': null,
        'distance': null,
      };
    }

    final sma111 = indicators['sma111'] as double;
    final sma350x2 = indicators['sma350x2'] as double;
    final distance = calculateDistancePercentage(
      sma111: sma111,
      sma350x2: sma350x2,
    );

    String status;
    String message;

    if (sma111 > sma350x2) {
      status = 'top';
      message = '🔴 SINAL DE TOPO! SMA 111 cruzou acima de SMA 350 x 2';
    } else if (distance > -5 && distance < 0) {
      status = 'approaching';
      message = '⚠️ Aproximando do topo. SMA 111 está ${distance.abs().toStringAsFixed(2)}% abaixo de SMA 350 x 2';
    } else {
      status = 'normal';
      message = '✅ Mercado normal. SMA 111 está ${distance.abs().toStringAsFixed(2)}% abaixo de SMA 350 x 2';
    }

    return {
      'status': status,
      'message': message,
      'sma111': sma111,
      'sma350x2': sma350x2,
      'distance': distance,
    };
  }
}
