/// Utilitários para formatação de números
class NumberFormatter {
  /// Formata números grandes com sufixos (K, M, B, T)
  static String formatLargeNumber(double? value, {int decimals = 2, String? fiat = 'USD'}) {
    if (value == null) return 'N/A';
    String symbol = _getCurrencySymbol(fiat);
    if (value >= 1e12) {
      return '$symbol${(value / 1e12).toStringAsFixed(decimals)}T';
    } else if (value >= 1e9) {
      return '$symbol${(value / 1e9).toStringAsFixed(decimals)}B';
    } else if (value >= 1e6) {
      return '$symbol${(value / 1e6).toStringAsFixed(decimals)}M';
    } else if (value >= 1e3) {
      return '$symbol${(value / 1e3).toStringAsFixed(decimals)}K';
    } else {
      return '$symbol${value.toStringAsFixed(decimals)}';
    }
  }

  static String _getCurrencySymbol(String? currencyCode) {
    // Mapa constante que associa o código da moeda ao seu símbolo
    const Map<String, String> currencySymbolMap = {
      'USD': '\$', // Dólar Americano
      'EUR': '€', // Euro
      'BRL': 'R\$', // Real Brasileiro
      'GBP': '£', // Libra Esterlina
      'JPY': '¥', // Iene Japonês
    };

    // Tenta obter o símbolo.
    // O .?? retorna um valor padrão (ex: string vazia) se a chave não for encontrada.
    String result = currencySymbolMap[currencyCode ?? 'USD'] ?? '\$';
    return result;
  }

  /// Formata valores monetários simples
  static String formatCurrency(double value, {String symbol = '\$', int decimals = 2}) {
    return '$symbol${value.toStringAsFixed(decimals)}';
  }

  /// Formata percentuais com sinal
  static String formatPercentage(double value, {int decimals = 2}) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}%';
  }

  /// Formata valores em real brasileiro
  static String formatBRL(double value, {int decimals = 2}) {
    return 'R\$ ${value.toStringAsFixed(decimals)}';
  }
}
