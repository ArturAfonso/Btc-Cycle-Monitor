import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar preferências do usuário
class PreferencesService {
  static const String _currencyKey = 'selected_currency';
  static const String _localeKey = 'selected_locale';
  static const String _intervalKey = 'selected_interval';
  static const String _themeKey = 'selected_theme';
  static const String _startWithSystemKey = 'start_with_system';
  static const String _showNotificationsKey = 'show_notifications';
  static const String _alertRecurringKey = 'alert_recurring';
  
  // Chaves para alertas
  static const String _alertTargetBtcKey = 'alert_target_btc';
  static const String _alertTargetFiatKey = 'alert_target_fiat';
  static const String _alertOscillationKey = 'alert_oscillation';
  static const String _alertPriceTrendKey = 'alert_price_trend'; // 'up' ou 'down'
  static const String _lastTriggeredAlertFiatKey = 'last_triggered_alert_fiat'; // Último alerta disparado
  static const String _savedAlertValueFiatKey = 'saved_alert_value_fiat'; // Valor do campo (nunca removido)
  static const String _savedOscillationValueKey = 'saved_oscillation_value'; // Valor da oscilação salvo (nunca removido)

  /// Converte código da moeda para locale correspondente
  static String _currencyToLocale(String currency) {
    switch (currency) {
      case 'USD':
        return 'en_US';
      case 'BRL':
        return 'pt_BR';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'JPY':
        return 'ja_JP';
      default:
        return 'ru_RU'; // Rublo russo como padrão
    }
  }

  /// Salva a moeda selecionada e seu locale correspondente
  static Future<void> setSelectedCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    final locale = _currencyToLocale(currency);
    
    print('💾 PreferencesService: Salvando currency=$currency e locale=$locale');
    
    await prefs.setString(_currencyKey, currency);
    await prefs.setString(_localeKey, locale);
    
    print('✅ PreferencesService: Salvo com sucesso!');
  }

  /// Recupera a moeda selecionada (padrão: USD)
  static Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'USD';
  }

  /// Recupera o locale selecionado (padrão: ru_RU - Rublo russo)
  static Future<String> getSelectedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'ru_RU';
  }

  /// Salva o intervalo de atualização
  static Future<void> setSelectedInterval(String interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_intervalKey, interval);
  }

  /// Recupera o intervalo selecionado (padrão: 30s)
  static Future<String> getSelectedInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_intervalKey) ?? '30s';
  }

  /// Salva o tema selecionado
  static Future<void> setSelectedTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  /// Recupera o tema selecionado (padrão: dark)
  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'dark';
  }

  /// Salva se deve iniciar com o sistema
  static Future<void> setStartWithSystem(bool startWithSystem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startWithSystemKey, startWithSystem);
  }

  /// Recupera se deve iniciar com o sistema (padrão: false)
  static Future<bool> getStartWithSystem() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_startWithSystemKey) ?? false;
  }

  /// Salva se deve exibir notificações
  static Future<void> setShowNotifications(bool showNotifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNotificationsKey, showNotifications);
  }

  /// Recupera se deve exibir notificações (padrão: false)
  static Future<bool> getShowNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showNotificationsKey) ?? false;
  }

  /// Salva se os alertas devem ser recorrentes (padrão: false)
  static Future<void> setAlertRecurring(bool recurring) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertRecurringKey, recurring);
  }

  /// Recupera se os alertas devem ser recorrentes (padrão: false)
  static Future<bool> getAlertRecurring() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alertRecurringKey) ?? false;
  }

  // ========== ALERTAS ==========

  /// Salva o alvo de preço em BTC (null ou 0.0 desativa o alerta)
  static Future<void> setAlertTargetBtc(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value == 0.0) {
      await prefs.remove(_alertTargetBtcKey);
      print('🔔 PreferencesService: Alerta de BTC removido');
    } else {
      await prefs.setDouble(_alertTargetBtcKey, value);
      print('🔔 PreferencesService: Alerta de BTC salvo: $value');
    }
  }

  /// Recupera o alvo de preço em BTC (null se não configurado)
  static Future<double?> getAlertTargetBtc() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_alertTargetBtcKey);
  }

  /// Salva o alvo de preço em Fiat (null ou 0.0 desativa o alerta)
  static Future<void> setAlertTargetFiat(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value == 0.0) {
      await prefs.remove(_alertTargetFiatKey);
      print('🔔 PreferencesService: Alerta de Fiat removido');
    } else {
      await prefs.setDouble(_alertTargetFiatKey, value);
      print('🔔 PreferencesService: Alerta de Fiat salvo: $value');
    }
  }

  /// Recupera o alvo de preço em Fiat (null se não configurado)
  static Future<double?> getAlertTargetFiat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_alertTargetFiatKey);
  }

  /// Salva o último alerta de Fiat que foi disparado
  static Future<void> setLastTriggeredAlertFiat(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value == 0.0) {
      await prefs.remove(_lastTriggeredAlertFiatKey);
      print('🔔 PreferencesService: Último alerta disparado removido');
    } else {
      await prefs.setDouble(_lastTriggeredAlertFiatKey, value);
      print('🔔 PreferencesService: Último alerta disparado salvo: $value');
    }
  }

  /// Recupera o último alerta de Fiat que foi disparado
  static Future<double?> getLastTriggeredAlertFiat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lastTriggeredAlertFiatKey);
  }

  /// Salva o valor do campo de alerta Fiat (nunca é removido, apenas atualizado)
  static Future<void> setSavedAlertValueFiat(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value == 0.0) {
      await prefs.remove(_savedAlertValueFiatKey);
      print('🔔 PreferencesService: Valor salvo do campo removido');
    } else {
      await prefs.setDouble(_savedAlertValueFiatKey, value);
      print('🔔 PreferencesService: Valor do campo salvo: $value');
    }
  }

  /// Recupera o valor do campo de alerta Fiat (para preencher o campo mesmo quando desativado)
  static Future<double?> getSavedAlertValueFiat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_savedAlertValueFiatKey);
  }

  /// Salva o valor da oscilação (campo, nunca removido mesmo quando alerta desativado)
  static Future<void> setSavedOscillationValue(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_savedOscillationValueKey, value);
    print('💾 PreferencesService: Valor de oscilação salvo: $value%');
  }

  /// Recupera o valor salvo da oscilação (para restaurar o campo)
  static Future<double?> getSavedOscillationValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_savedOscillationValueKey);
  }

  /// Salva a porcentagem de oscilação (0.0 desativa o alerta)
  static Future<void> setAlertOscillation(double value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == 0.0) {
      await prefs.remove(_alertOscillationKey);
      print('🔔 PreferencesService: Alerta de oscilação removido');
    } else {
      await prefs.setDouble(_alertOscillationKey, value);
      print('🔔 PreferencesService: Alerta de oscilação salvo: $value%');
    }
  }

  /// Recupera a porcentagem de oscilação (0.0 se não configurado)
  static Future<double> getAlertOscillation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_alertOscillationKey) ?? 0.0;
  }

  /// Salva a tendência do alerta de preço ('up' ou 'down')
  static Future<void> setAlertPriceTrend(String trend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertPriceTrendKey, trend);
    print('🔔 PreferencesService: Tendência de preço salva: $trend');
  }

  /// Recupera a tendência do alerta de preço (null se não configurado)
  static Future<String?> getAlertPriceTrend() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_alertPriceTrendKey);
  }

  /// Limpa todas as preferências (útil para reset)
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Salva todas as preferências de uma vez
  static Future<void> saveAllPreferences({
    required String currency,
    required String interval,
    required String theme,
    required bool startWithSystem,
    required bool showNotifications,
  }) async {
    await Future.wait([
      setSelectedCurrency(currency),
      setSelectedInterval(interval),
      setSelectedTheme(theme),
      setStartWithSystem(startWithSystem),
      setShowNotifications(showNotifications),
    ]);
  }

  /// Carrega todas as preferências de uma vez
  static Future<Map<String, dynamic>> loadAllPreferences() async {
    final results = await Future.wait([
      getSelectedCurrency(),
      getSelectedLocale(),
      getSelectedInterval(),
      getSelectedTheme(),
      getStartWithSystem(),
      getShowNotifications(),
    ]);

    return {
      'currency': results[0],
      'locale': results[1],
      'interval': results[2],
      'theme': results[3],
      'startWithSystem': results[4],
      'showNotifications': results[5],
    };
  }
}