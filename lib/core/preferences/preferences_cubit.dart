import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/preferences_service.dart';
import 'preferences_state.dart';

/// Cubit que gerencia o estado global das preferências do usuário
class PreferencesCubit extends Cubit<PreferencesState> {
  // Callback para notificar mudanças que requerem atualizações de dados
  Function(String currency)? onCurrencyChanged;
  
  PreferencesCubit() : super(PreferencesLoading());

  /// Carrega todas as preferências do SharedPreferences
  Future<void> loadPreferences() async {
    try {
      emit(PreferencesLoading());
      
      final prefs = await PreferencesService.loadAllPreferences();
      final alertTargetBtc = await PreferencesService.getAlertTargetBtc();
      final alertTargetFiat = await PreferencesService.getAlertTargetFiat();
      final alertOscillation = await PreferencesService.getAlertOscillation();
      final alertRecurring = await PreferencesService.getAlertRecurring();
      
      emit(PreferencesLoaded(
        selectedCurrency: prefs['currency'],
        selectedLocale: prefs['locale'],
        selectedInterval: prefs['interval'],
        selectedTheme: prefs['theme'],
        startWithSystem: prefs['startWithSystem'],
        showNotifications: prefs['showNotifications'],
        alertRecurring: alertRecurring,
        alertTargetBtc: alertTargetBtc,
        alertTargetFiat: alertTargetFiat,
        alertOscillation: alertOscillation,
      ));
    } catch (e) {
      emit(PreferencesError('Erro ao carregar preferências: $e'));
    }
  }

  /// Atualiza a moeda selecionada
  Future<void> updateCurrency(String currency) async {
    try {
      print('🔄 PreferencesCubit: Atualizando moeda para: $currency');
      
      // Primeiro salva no SharedPreferences (que também salva o locale)
      await PreferencesService.setSelectedCurrency(currency);
      
      // Depois recupera o locale que foi salvo
      final locale = await PreferencesService.getSelectedLocale();
      
      print('✅ PreferencesCubit: Locale recuperado: $locale');
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(
          selectedCurrency: currency,
          selectedLocale: locale,
        ));
        
        print('✅ PreferencesCubit: Estado emitido com currency=$currency e locale=$locale');
        
        // Notifica a mudança de moeda para recarregar dados das APIs
        onCurrencyChanged?.call(currency);
      }
    } catch (e) {
      print('❌ PreferencesCubit: Erro ao salvar moeda: $e');
      emit(PreferencesError('Erro ao salvar moeda: $e'));
    }
  }

  /// Atualiza o intervalo de atualização
  Future<void> updateInterval(String interval) async {
    try {
      await PreferencesService.setSelectedInterval(interval);
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(selectedInterval: interval));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar intervalo: $e'));
    }
  }

  /// Atualiza o tema selecionado
  Future<void> updateTheme(String theme) async {
    try {
      await PreferencesService.setSelectedTheme(theme);
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(selectedTheme: theme));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar tema: $e'));
    }
  }

  /// Atualiza se deve iniciar com o sistema
  Future<void> updateStartWithSystem(bool startWithSystem) async {
    try {
      await PreferencesService.setStartWithSystem(startWithSystem);
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(startWithSystem: startWithSystem));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar iniciar com sistema: $e'));
    }
  }

  /// Atualiza se deve exibir notificações
  Future<void> updateShowNotifications(bool showNotifications) async {
    try {
      await PreferencesService.setShowNotifications(showNotifications);
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(showNotifications: showNotifications));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar notificações: $e'));
    }
  }

  /// Atualiza se os alertas devem ser recorrentes
  Future<void> updateAlertRecurring(bool recurring) async {
    try {
      await PreferencesService.setAlertRecurring(recurring);
      
      // Se ativou recorrente e não há alerta ativo, tenta restaurar o último disparado
      if (recurring) {
        final currentAlert = await PreferencesService.getAlertTargetFiat();
        if (currentAlert == null) {
          final lastTriggered = await PreferencesService.getLastTriggeredAlertFiat();
          if (lastTriggered != null && lastTriggered > 0.0) {
            await PreferencesService.setAlertTargetFiat(lastTriggered);
            print('🔄 PreferencesCubit: Alerta recorrente ativado - Restaurando último alerta: $lastTriggered');
            
            if (state is PreferencesLoaded) {
              final currentState = state as PreferencesLoaded;
              emit(currentState.copyWith(
                alertRecurring: recurring,
                alertTargetFiat: lastTriggered,
              ));
              return;
            }
          }
        }
      } else {
        // Se desativou recorrente, limpa o histórico de último alerta
        await PreferencesService.setLastTriggeredAlertFiat(null);
        print('🗑️ PreferencesCubit: Alerta recorrente desativado - Limpando histórico');
      }
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(alertRecurring: recurring));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar alerta recorrente: $e'));
    }
  }

  // ========== ALERTAS ==========

  /// Atualiza o alvo de preço em BTC (null ou 0.0 desativa)
  /// Ao configurar BTC, remove o alvo Fiat automaticamente
  Future<void> updateAlertTargetBtc(double? value, {String? trend}) async {
    try {
      await PreferencesService.setAlertTargetBtc(value);
      
      // Se configurou BTC, remove Fiat e salva a tendência
      if (value != null && value > 0.0) {
        await PreferencesService.setAlertTargetFiat(null);
        if (trend != null) {
          await PreferencesService.setAlertPriceTrend(trend);
        }
      }
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(
          alertTargetBtc: value,
          alertTargetFiat: (value != null && value > 0.0) ? null : currentState.alertTargetFiat,
        ));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar alerta BTC: $e'));
    }
  }

  /// Atualiza o alvo de preço em Fiat (null ou 0.0 desativa)
  /// Ao configurar Fiat, remove o alvo BTC automaticamente
  Future<void> updateAlertTargetFiat(double? value, {String? trend}) async {
    try {
      print('🔔 PreferencesCubit.updateAlertTargetFiat - Valor: $value, Trend: $trend');
      
      await PreferencesService.setAlertTargetFiat(value);
      print('🔔 PreferencesCubit.updateAlertTargetFiat - Salvo no SharedPreferences');
      
      // Se configurou Fiat, remove BTC e salva a tendência
      if (value != null && value > 0.0) {
        await PreferencesService.setAlertTargetBtc(null);
        if (trend != null) {
          await PreferencesService.setAlertPriceTrend(trend);
        }
      }
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        final newState = currentState.copyWith(
          alertTargetFiat: value,
          alertTargetBtc: (value != null && value > 0.0) ? null : currentState.alertTargetBtc,
        );
        
        print('🔔 PreferencesCubit.updateAlertTargetFiat - Novo estado:');
        print('   alertTargetFiat: ${newState.alertTargetFiat}');
        print('   alertTargetBtc: ${newState.alertTargetBtc}');
        
        emit(newState);
        print('🔔 PreferencesCubit.updateAlertTargetFiat - Estado emitido');
      }
    } catch (e) {
      print('❌ PreferencesCubit.updateAlertTargetFiat - Erro: $e');
      emit(PreferencesError('Erro ao salvar alerta Fiat: $e'));
    }
  }

  /// Atualiza a porcentagem de oscilação (0.0 desativa)
  Future<void> updateAlertOscillation(double value) async {
    try {
      await PreferencesService.setAlertOscillation(value);
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(alertOscillation: value));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar alerta de oscilação: $e'));
    }
  }

  /// Atualiza múltiplas preferências de uma vez
  Future<void> updateMultiplePreferences({
    String? currency,
    String? interval,
    String? theme,
    bool? startWithSystem,
    bool? showNotifications,
  }) async {
    try {
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        
        // Salva no SharedPreferences
        if (currency != null) await PreferencesService.setSelectedCurrency(currency);
        if (interval != null) await PreferencesService.setSelectedInterval(interval);
        if (theme != null) await PreferencesService.setSelectedTheme(theme);
        if (startWithSystem != null) await PreferencesService.setStartWithSystem(startWithSystem);
        if (showNotifications != null) await PreferencesService.setShowNotifications(showNotifications);
        
        // Atualiza o estado
        emit(currentState.copyWith(
          selectedCurrency: currency,
          selectedInterval: interval,
          selectedTheme: theme,
          startWithSystem: startWithSystem,
          showNotifications: showNotifications,
        ));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar preferências: $e'));
    }
  }

  /// Reseta todas as preferências para os valores padrão
  Future<void> resetToDefaults() async {
    try {
      await PreferencesService.clearAllPreferences();
      
      emit(PreferencesLoaded(
        selectedCurrency: 'USD',
        selectedLocale: 'ru_RU', // Rublo russo como padrão
        selectedInterval: '30s',
        selectedTheme: 'dark',
        startWithSystem: false,
        showNotifications: false,
        alertRecurring: false,
      ));
    } catch (e) {
      emit(PreferencesError('Erro ao resetar preferências: $e'));
    }
  }
}