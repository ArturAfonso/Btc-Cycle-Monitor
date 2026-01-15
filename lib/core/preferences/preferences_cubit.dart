import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/preferences_service.dart';
import 'preferences_state.dart';


class PreferencesCubit extends Cubit<PreferencesState> {
  
  Function(String currency)? onCurrencyChanged;
  
  PreferencesCubit() : super(PreferencesLoading());

  
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

  
  Future<void> updateCurrency(String currency) async {
    try {
      debugPrint('🔄 PreferencesCubit: Atualizando moeda para: $currency');
      
      
      await PreferencesService.setSelectedCurrency(currency);
      
      
      final locale = await PreferencesService.getSelectedLocale();
      
      debugPrint('✅ PreferencesCubit: Locale recuperado: $locale');
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(
          selectedCurrency: currency,
          selectedLocale: locale,
        ));
        
        debugPrint('✅ PreferencesCubit: Estado emitido com currency=$currency e locale=$locale');
        
        
        onCurrencyChanged?.call(currency);
      }
    } catch (e) {
      debugPrint('❌ PreferencesCubit: Erro ao salvar moeda: $e');
      emit(PreferencesError('Erro ao salvar moeda: $e'));
    }
  }

  
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

  
  Future<void> updateAlertRecurring(bool recurring) async {
    try {
      await PreferencesService.setAlertRecurring(recurring);
      
      
      if (recurring) {
        final currentAlert = await PreferencesService.getAlertTargetFiat();
        if (currentAlert == null) {
          final lastTriggered = await PreferencesService.getLastTriggeredAlertFiat();
          if (lastTriggered != null && lastTriggered > 0.0) {
            await PreferencesService.setAlertTargetFiat(lastTriggered);
            debugPrint('🔄 PreferencesCubit: Alerta recorrente ativado - Restaurando último alerta: $lastTriggered');
            
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
        
        await PreferencesService.setLastTriggeredAlertFiat(null);
        debugPrint('🗑️ PreferencesCubit: Alerta recorrente desativado - Limpando histórico');
      }
      
      if (state is PreferencesLoaded) {
        final currentState = state as PreferencesLoaded;
        emit(currentState.copyWith(alertRecurring: recurring));
      }
    } catch (e) {
      emit(PreferencesError('Erro ao salvar alerta recorrente: $e'));
    }
  }

  

  
  
  Future<void> updateAlertTargetBtc(double? value, {String? trend}) async {
    try {
      await PreferencesService.setAlertTargetBtc(value);
      
      
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

  
  
  Future<void> updateAlertTargetFiat(double? value, {String? trend}) async {
    try {
      debugPrint('🔔 PreferencesCubit.updateAlertTargetFiat - Valor: $value, Trend: $trend');
      
      await PreferencesService.setAlertTargetFiat(value);
      debugPrint('🔔 PreferencesCubit.updateAlertTargetFiat - Salvo no SharedPreferences');
      
      
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
        
        debugPrint('🔔 PreferencesCubit.updateAlertTargetFiat - Novo estado:');
        debugPrint('   alertTargetFiat: ${newState.alertTargetFiat}');
        debugPrint('   alertTargetBtc: ${newState.alertTargetBtc}');
        
        emit(newState);
        debugPrint('🔔 PreferencesCubit.updateAlertTargetFiat - Estado emitido');
      }
    } catch (e) {
      debugPrint('❌ PreferencesCubit.updateAlertTargetFiat - Erro: $e');
      emit(PreferencesError('Erro ao salvar alerta Fiat: $e'));
    }
  }

  
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
        
        
        if (currency != null) await PreferencesService.setSelectedCurrency(currency);
        if (interval != null) await PreferencesService.setSelectedInterval(interval);
        if (theme != null) await PreferencesService.setSelectedTheme(theme);
        if (startWithSystem != null) await PreferencesService.setStartWithSystem(startWithSystem);
        if (showNotifications != null) await PreferencesService.setShowNotifications(showNotifications);
        
        
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

  
  Future<void> resetToDefaults() async {
    try {
      await PreferencesService.clearAllPreferences();
      
      emit(PreferencesLoaded(
        selectedCurrency: 'USD',
        selectedLocale: 'ru_RU', 
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