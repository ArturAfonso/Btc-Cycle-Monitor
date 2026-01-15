/// Estados possíveis para as preferências do usuário
abstract class PreferencesState {}

/// Estado inicial - carregando preferências
class PreferencesLoading extends PreferencesState {}

/// Estado com preferências carregadas
class PreferencesLoaded extends PreferencesState {
  final String selectedCurrency;
  final String selectedLocale;
  final String selectedInterval;
  final String selectedTheme;
  final bool startWithSystem;
  final bool showNotifications;
  final bool alertRecurring;
  
  // Alertas
  final double? alertTargetBtc;
  final double? alertTargetFiat;
  final double alertOscillation;

  PreferencesLoaded({
    required this.selectedCurrency,
    required this.selectedLocale,
    required this.selectedInterval,
    required this.selectedTheme,
    required this.startWithSystem,
    required this.showNotifications,
    required this.alertRecurring,
    this.alertTargetBtc,
    this.alertTargetFiat,
    this.alertOscillation = 0.0,
  });

  /// Cria uma cópia com alguns valores alterados
  PreferencesLoaded copyWith({
    String? selectedCurrency,
    String? selectedLocale,
    String? selectedInterval,
    String? selectedTheme,
    bool? startWithSystem,
    bool? showNotifications,
    bool? alertRecurring,
    double? alertTargetBtc,
    double? alertTargetFiat,
    double? alertOscillation,
  }) {
    final newState = PreferencesLoaded(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      selectedLocale: selectedLocale ?? this.selectedLocale,
      selectedInterval: selectedInterval ?? this.selectedInterval,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      startWithSystem: startWithSystem ?? this.startWithSystem,
      showNotifications: showNotifications ?? this.showNotifications,
      alertRecurring: alertRecurring ?? this.alertRecurring,
      alertTargetBtc: alertTargetBtc ?? this.alertTargetBtc,
      alertTargetFiat: alertTargetFiat ?? this.alertTargetFiat,
      alertOscillation: alertOscillation ?? this.alertOscillation,
    );
    
    print('🔄 PreferencesLoaded.copyWith: Novo estado criado com locale=${newState.selectedLocale}');
    
    return newState;
  }

  @override
  String toString() {
    return 'PreferencesLoaded(currency: $selectedCurrency, locale: $selectedLocale, interval: $selectedInterval, theme: $selectedTheme, startWithSystem: $startWithSystem, showNotifications: $showNotifications, alertRecurring: $alertRecurring, alertBtc: $alertTargetBtc, alertFiat: $alertTargetFiat, alertOscillation: $alertOscillation)';
  }
}

/// Estado de erro ao carregar/salvar preferências
class PreferencesError extends PreferencesState {
  final String message;

  PreferencesError(this.message);

  @override
  String toString() => 'PreferencesError(message: $message)';
}