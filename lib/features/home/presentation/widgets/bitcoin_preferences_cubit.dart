import 'package:btc_cycle_monitor/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/home_data.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';
import '../../../../core/services/preferences_service.dart';


class CommaToDecimalFormatter extends TextInputFormatter {
  final int maxDecimalPlaces;
  final int maxIntegerDigits;

  CommaToDecimalFormatter({
    this.maxDecimalPlaces = 8,
    this.maxIntegerDigits = 10, 
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    
    String newText = newValue.text.replaceAll(',', '.');

    
    if (newText.split('.').length > 2) {
      return oldValue;
    }

    
    if (newText.contains('.')) {
      List<String> parts = newText.split('.');

      
      if (parts[0].length > maxIntegerDigits) {
        parts[0] = parts[0].substring(0, maxIntegerDigits);
      }

      
      if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
        parts[1] = parts[1].substring(0, maxDecimalPlaces);
      }

      newText = parts.join('.');
    } else {
      
      if (newText.length > maxIntegerDigits) {
        
        newText = '${newText.substring(0, maxIntegerDigits)}.${newText.substring(maxIntegerDigits)}';

        
        List<String> parts = newText.split('.');
        if (parts[1].length > maxDecimalPlaces) {
          parts[1] = parts[1].substring(0, maxDecimalPlaces);
          newText = parts.join('.');
        }
      }
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}


class FiatCurrencyFormatter extends TextInputFormatter {
  final int maxDigits;

  FiatCurrencyFormatter({this.maxDigits = 15}); 

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    
    newText = newText.replaceAll(RegExp(r'[^\d]'), '');

    
    if (newText.isEmpty) {
      return const TextEditingValue(text: '0,00', selection: TextSelection.collapsed(offset: 4));
    }

    
    if (newText.length > maxDigits) {
      newText = newText.substring(0, maxDigits);
    }

    
    newText = newText.replaceFirst(RegExp(r'^0+'), '');
    if (newText.isEmpty) {
      newText = '0';
    }

    try {
      
      int number = int.parse(newText);
      double value = number / 100.0;

      
      final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');
      String formatted = formatter.format(value).trim();

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      
      debugPrint('⚠️ Erro ao formatar valor: $e');
      return oldValue;
    }
  }
}


class AppPreferencesWithCubit extends StatelessWidget {
  final BitcoinData bitcoinData;

  const AppPreferencesWithCubit({super.key, required this.bitcoinData});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(AppColors.cardColor), borderRadius: BorderRadius.circular(16)),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PreferencesState state) {
    if (state is PreferencesLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFB800)),
            SizedBox(height: 16),
            Text('Carregando preferências...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (state is PreferencesError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro: ${state.message}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<PreferencesCubit>().loadPreferences(),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (state is PreferencesLoaded) {
      return _PreferencesContent(bitcoinData: bitcoinData, preferences: state);
    }

    return const SizedBox.shrink();
  }
}


class _PreferencesContent extends StatefulWidget {
  final BitcoinData bitcoinData;
  final PreferencesLoaded preferences;

  const _PreferencesContent({required this.bitcoinData, required this.preferences});

  @override
  State<_PreferencesContent> createState() => _PreferencesContentState();
}

class _PreferencesContentState extends State<_PreferencesContent> {
  String selectedTab = 'Alertas';
  String selectedCurrency = 'USD'; 
  double oscillationPercentage = 0.0; 

  
  late TextEditingController _priceAlertController;
  late FocusNode _priceAlertFocusNode;
  bool _isPriceAlertEditable = false; 
  bool _isPriceAlertEnabled = false; 
  bool _isCreatingNewAlert = false; 

  
  late TextEditingController _oscillationController;
  late FocusNode _oscillationFocusNode;
  bool _isOscillationAlertEnabled = false; 
  bool _isCreatingNewOscillationAlert = false; 
  bool _isOscillationEditable = false; 

  @override
  void initState() {
    super.initState();
    
    selectedCurrency = widget.preferences.selectedCurrency;

    
    _priceAlertController = TextEditingController();
    _priceAlertFocusNode = FocusNode();

    
    _oscillationController = TextEditingController();
    _oscillationFocusNode = FocusNode();

    
    _loadSavedAlerts();

    
    _oscillationFocusNode.addListener(() {
      if (!_oscillationFocusNode.hasFocus) {
        
        _saveOscillationAlert();
        setState(() {
          debugPrint('🔒 Campo de oscilação desabilitado');
        });
      }
    });
  }

  
  void _loadSavedAlerts() async {
    final prefs = widget.preferences;

    debugPrint('📥 _loadSavedAlerts iniciado');
    debugPrint('📥 Fiat ativo: ${prefs.alertTargetFiat}');
    debugPrint('📥 Oscilação ativa (prefs.alertOscillation): ${prefs.alertOscillation}');

    
    final savedOscillationValue = await PreferencesService.getSavedOscillationValue();
    debugPrint('📥 Valor salvo de oscilação (getSavedOscillationValue): $savedOscillationValue');
    
    
    if (savedOscillationValue != null && savedOscillationValue != 0.0) {
      oscillationPercentage = savedOscillationValue;
      _oscillationController.text = oscillationPercentage.toStringAsFixed(1);
      debugPrint('📥 Valor salvo de oscilação carregado: $savedOscillationValue%');
      
      
      _isOscillationEditable = false;
    } else if (prefs.alertOscillation != 0.0) {
      
      oscillationPercentage = prefs.alertOscillation;
      _oscillationController.text = oscillationPercentage.toStringAsFixed(1);
      debugPrint('📥 Alerta de oscilação ativo carregado: ${prefs.alertOscillation}%');
      
      
      _isOscillationEditable = false;
    } else {
      
      oscillationPercentage = 0.0;
      _oscillationController.text = '0.0';
      _isOscillationEditable = false;
    }
    
    
    _isOscillationAlertEnabled = prefs.alertOscillation != 0.0;
    
    debugPrint('📥 Estado de oscilação: valor=$oscillationPercentage%, ativado=$_isOscillationAlertEnabled, editável=$_isOscillationEditable');

    
    final savedFieldValue = await PreferencesService.getSavedAlertValueFiat();
    debugPrint('📥 Valor salvo do campo: $savedFieldValue');

    
    final isAlertActive = prefs.alertTargetFiat != null && prefs.alertTargetFiat! > 0.0;
    
    
    if (savedFieldValue != null && savedFieldValue > 0.0) {
      debugPrint('📥 Preenchendo campo com valor salvo: $savedFieldValue');
      final value = (savedFieldValue * 100).toInt().toString();
      _priceAlertController.text = FiatCurrencyFormatter()
          .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
          .text;
      debugPrint('📥 Texto no controller: ${_priceAlertController.text}');
    } else if (isAlertActive) {
      
      debugPrint('📥 Preenchendo campo com alerta ativo: ${prefs.alertTargetFiat}');
      final value = (prefs.alertTargetFiat! * 100).toInt().toString();
      _priceAlertController.text = FiatCurrencyFormatter()
          .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
          .text;
      debugPrint('📥 Texto no controller: ${_priceAlertController.text}');
    }

    
    _isPriceAlertEnabled = isAlertActive;

    debugPrint(
      '🔔 Alertas carregados: Campo=$savedFieldValue, Ativo=${prefs.alertTargetFiat}, Oscilação=${prefs.alertOscillation}%, Switch=$_isPriceAlertEnabled',
    );
    
    
    setState(() {
      debugPrint('🔄 Widget reconstruído com valores carregados');
    });
  }

  
  Future<void> _saveOscillationAlert() async {
    final newValue = double.tryParse(_oscillationController.text.replaceAll('%', '').trim()) ?? oscillationPercentage;

    
    await PreferencesService.setSavedOscillationValue(newValue);
    
    
    oscillationPercentage = newValue;
    
    
    if (newValue != 0.0 && !_isOscillationAlertEnabled) {
      setState(() {
        _isOscillationAlertEnabled = true;
      });
      await context.read<PreferencesCubit>().updateAlertOscillation(newValue);
      debugPrint('💾 Alerta de oscilação salvo e ativado: $newValue%');
    } else if (_isOscillationAlertEnabled) {
      
      await context.read<PreferencesCubit>().updateAlertOscillation(newValue);
      debugPrint('💾 Alerta de oscilação salvo: $newValue%');
    } else {
      
      debugPrint('💾 Valor de oscilação atualizado localmente: $newValue%');
    }
  }

  
  void _toggleOscillationEdit() async {
    if (_isOscillationEditable) {
      
      
      if (oscillationPercentage != 0.0 && !_isOscillationAlertEnabled) {
        setState(() {
          _isOscillationAlertEnabled = true;
        });
      }
      
      
      await _saveOscillationAlert();
      
      setState(() {
        _isOscillationEditable = false;
      });
      debugPrint('✅ Alerta de oscilação salvo: $oscillationPercentage%, ativado: $_isOscillationAlertEnabled');
    } else {
      
      setState(() {
        _isOscillationEditable = true;
      });
      debugPrint('✏️ Modo de edição de oscilação ativado');
    }
  }

  
  void _togglePriceAlertEdit() async {
    if (_isPriceAlertEditable) {
      
      await _savePriceAlertManually();
      setState(() {
        _isPriceAlertEditable = false;
      });
    } else {
      
      setState(() {
        _isPriceAlertEditable = true;
      });
      
      _priceAlertFocusNode.requestFocus();
    }
  }

  
  Future<void> _savePriceAlertManually() async {
    final cubit = context.read<PreferencesCubit>();
    final text = _priceAlertController.text.trim();
    final prefs = widget.preferences;

    debugPrint('💾 _savePriceAlertManually - Texto no campo: "$text"');

    
    final numericText = text.replaceAll(RegExp(r'[^\d]'), '');
    final newValue = numericText.isNotEmpty ? int.parse(numericText) / 100.0 : 0.0;
    final savedValue = prefs.alertTargetFiat;

    debugPrint('💾 Fiat - Texto numérico: "$numericText"');
    debugPrint('💾 Fiat - Novo valor: $newValue, Salvo: $savedValue');

    
    if (text.isEmpty || text == '0,00' || newValue <= 0.0) {
      debugPrint('⚠️ Tentativa de salvar valor vazio ou zero');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um valor válido para o alerta'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return; 
    }

    
    await PreferencesService.setSavedAlertValueFiat(newValue);

    
    if (newValue == savedValue) {
      debugPrint('ℹ️ Valor não mudou, mantendo: $savedValue $selectedCurrency');
      return;
    }

    
    await cubit.updateAlertTargetFiat(newValue);
    setState(() {
      _isPriceAlertEnabled = true;
    });
    debugPrint('💾 Alerta de preço Fiat salvo: $newValue $selectedCurrency');
  }

  
  void _deleteAlert() async {
    
    await context.read<PreferencesCubit>().updateAlertTargetFiat(null);
    await PreferencesService.setSavedAlertValueFiat(null);
    await PreferencesService.setLastTriggeredAlertFiat(null);
    
    
    _priceAlertController.clear();
    
    setState(() {
      _isPriceAlertEnabled = false;
      _isPriceAlertEditable = false;
      _isCreatingNewAlert = false; 
    });
    
    debugPrint('🗑️ Alerta excluído completamente');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta excluído'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  
  void _startCreatingNewAlert() {
    setState(() {
      _isCreatingNewAlert = true;
      _isPriceAlertEditable = true;
    });
    
    _priceAlertFocusNode.requestFocus();
  }

  
  void _startCreatingNewOscillationAlert() {
    setState(() {
      _isCreatingNewOscillationAlert = true;
      _isOscillationEditable = true; 
    });
  }

  
  void _deleteOscillationAlert() async {
    
    await context.read<PreferencesCubit>().updateAlertOscillation(0.0);
    
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_oscillation_value');
    
    
    setState(() {
      oscillationPercentage = 0.0;
      _oscillationController.text = '0.0';
      _isOscillationAlertEnabled = false;
      _isCreatingNewOscillationAlert = false;
      _isOscillationEditable = false;
    });
    
    debugPrint('🗑️ Alerta de oscilação excluído completamente');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de oscilação excluído'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  
  void _toggleOscillationAlertEnabled(bool value) async {
    
    final hasValue = oscillationPercentage != 0.0;

    
    if (value && !hasValue) {
      debugPrint('⚠️ Não é possível ativar alerta de oscilação sem valor definido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure um valor de oscilação primeiro'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isOscillationAlertEnabled = value;
    });

    if (!value) {
      
      await PreferencesService.setSavedOscillationValue(oscillationPercentage);
      
      await context.read<PreferencesCubit>().updateAlertOscillation(0.0);
      debugPrint('🔕 Alerta de oscilação desativado (valor salvo: $oscillationPercentage%)');
    } else {
      
      await PreferencesService.setSavedOscillationValue(oscillationPercentage);
      await context.read<PreferencesCubit>().updateAlertOscillation(oscillationPercentage);
      debugPrint('🔔 Alerta de oscilação ativado: $oscillationPercentage%');
    }
  }

  
  void _togglePriceAlertEnabled(bool value) async {
    final text = _priceAlertController.text.trim();
    final prefs = widget.preferences;

    
    final numericText = text.replaceAll(RegExp(r'[^\d]'), '');
    final fieldValue = numericText.isNotEmpty ? int.parse(numericText) / 100.0 : 0.0;
    
    
    final savedFieldValue = await PreferencesService.getSavedAlertValueFiat() ?? 0.0;
    final savedValue = prefs.alertTargetFiat ?? 0.0;
    final hasValue = fieldValue > 0.0 || savedValue > 0.0 || savedFieldValue > 0.0;

    
    if (value && !hasValue) {
      debugPrint('⚠️ Não é possível ativar alerta sem valor definido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um valor de alerta primeiro'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isPriceAlertEnabled = value;
    });

    if (!value) {
      
      
      if (fieldValue > 0.0) {
        await PreferencesService.setSavedAlertValueFiat(fieldValue);
      } else if (savedValue > 0.0) {
        await PreferencesService.setSavedAlertValueFiat(savedValue);
      }
      
      
      if (savedValue > 0.0) {
        await PreferencesService.setLastTriggeredAlertFiat(savedValue);
      }
      
      await context.read<PreferencesCubit>().updateAlertTargetFiat(null);
      debugPrint('🔕 Alerta de preço Fiat desativado (valor salvo: ${fieldValue > 0.0 ? fieldValue : savedValue})');
    } else {
      
      
      final valueToSave = fieldValue > 0.0 ? fieldValue : (savedFieldValue > 0.0 ? savedFieldValue : savedValue);
      
      if (valueToSave > 0.0) {
        
        await PreferencesService.setSavedAlertValueFiat(valueToSave);
        
        
        await context.read<PreferencesCubit>().updateAlertTargetFiat(valueToSave);
        
        
        if (fieldValue == 0.0) {
          final value = (valueToSave * 100).toInt().toString();
          _priceAlertController.text = FiatCurrencyFormatter()
              .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
              .text;
        }
        
        debugPrint('🔔 Alerta de preço Fiat ativado: $valueToSave $selectedCurrency');
      }
    }
  }

  
  @override
  void dispose() {
    _priceAlertController.dispose();
    _priceAlertFocusNode.dispose();
    _oscillationController.dispose();
    _oscillationFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PreferencesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    
    if (oldWidget.preferences.selectedCurrency != widget.preferences.selectedCurrency) {
      setState(() {
        selectedCurrency = widget.preferences.selectedCurrency;
      });
    }
    
    
    if (oldWidget.preferences.alertTargetFiat != widget.preferences.alertTargetFiat ||
        oldWidget.preferences.alertOscillation != widget.preferences.alertOscillation) {
      debugPrint('🔄 Preferências de alerta mudaram, recarregando...');
      _loadSavedAlerts();
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        const Text(
          'Preferências',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(child: _buildTabButton('Alertas', selectedTab == 'Alertas')),
              const SizedBox(width: 12),
              Expanded(child: _buildTabButton('Configurações', selectedTab == 'Configurações')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        selectedTab == 'Alertas' ? _buildAlertsContent() : _buildSettingsContent(),
      ],
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppColors.selectedButton) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Color(AppColors.textPrimary) : const Color(AppColors.textSecondary),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsContent() {
    
    final bool showControls = (_priceAlertController.text.isNotEmpty && _priceAlertController.text != '0,00') || _isCreatingNewAlert;
    
    return Container(
      child: Column(
        children: [
          _buildAlertsItem(
            'Alertas de preço',
            iconTitle: showControls ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isPriceAlertEnabled,
                    
                    onChanged: (_priceAlertController.text.isNotEmpty && _priceAlertController.text != '0,00')
                        ? _togglePriceAlertEnabled
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                
                const Spacer(),
                
                
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[300],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _deleteAlert,
                  tooltip: 'Excluir alerta',
                ),
              ],
            ) : null,
            
            
            showControls ?
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Color(AppColors.cardIndicator), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                 

                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceAlertController,
                          focusNode: _priceAlertFocusNode,
                          enabled: _isPriceAlertEditable,
                          inputFormatters: [FiatCurrencyFormatter()],
                          decoration: InputDecoration(
                            hintText: 'Valor em $selectedCurrency',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixText: selectedCurrency == 'USD'
                                ? '\$ '
                                : selectedCurrency == 'EUR'
                                ? '€ '
                                : selectedCurrency == 'GBP'
                                ? '£ '
                                : selectedCurrency == 'JPY'
                                ? '¥ '
                                : 'R\$ ',
                            prefixStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            debugPrint('💰 [Alerta de Preço] Valor digitado: $value');
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _togglePriceAlertEdit,
                        icon: Icon(
                          _isPriceAlertEditable ? Icons.save : Icons.edit,
                          color: Color(AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ) 
                ],
              ),
            ) : 
            
            InkWell(
              onTap: _startCreatingNewAlert,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(AppColors.textSecondary).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(AppColors.textSecondary), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Novo alerta de preço',
                      style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Colors.green,
          ),
          SizedBox(height: 12),
          
          
          _buildAlertsItem(
            'Alertas de oscilação (%)',
            ((oscillationPercentage != 0.0) || _isCreatingNewOscillationAlert || _isOscillationAlertEnabled) ?
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(AppColors.cardIndicator), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Visibility(
                              visible: oscillationPercentage != 0.0,
                              child: IconButton(
                                onPressed: oscillationPercentage != 0.0 ? _toggleOscillationEdit : null,
                                icon: Icon(_isOscillationEditable ? Icons.save : Icons.edit),
                                color: Color(AppColors.textSecondary),
                              ),
                            ),
                            IconButton(
                              iconSize: 15,
                              onPressed: () {
                                setState(() {
                                  oscillationPercentage = 0.0;
                                  _oscillationController.text = '0.0';
                                });
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: oscillationPercentage >= 0
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                         
                        ),
                        child: Text(
                          oscillationPercentage == 0
                              ? '${oscillationPercentage.toStringAsFixed(1)}%'
                              : oscillationPercentage >= 0
                              ? '+${oscillationPercentage.toStringAsFixed(1)}%'
                              : '${oscillationPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: oscillationPercentage >= 0 ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: oscillationPercentage >= 0 ? Colors.green : Colors.red,
                          inactiveTrackColor: const Color(0xFF334155),
                          thumbColor: oscillationPercentage >= 0 ? Colors.green : Colors.red,
                          overlayColor: (oscillationPercentage >= 0 ? Colors.green : Colors.red).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: oscillationPercentage,
                          min: -100,
                          max: 100,
                          divisions: 200,
                          onChanged: _isOscillationEditable ? (value) {
                            setState(() {
                              oscillationPercentage = value;
                              
                              _oscillationController.text = value.toStringAsFixed(1);
                            });
                          } : null, 
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('-100%', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                            Text('0%', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                            Text('+100%', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ) : InkWell(
              onTap: _startCreatingNewOscillationAlert,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(AppColors.cardIndicator),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(AppColors.textSecondary).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(AppColors.textSecondary), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Novo alerta de oscilação diária',
                      style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Colors.green,
            iconTitle: ((oscillationPercentage != 0.0) || _isCreatingNewOscillationAlert || _isOscillationAlertEnabled) ? Row(
              children: [
              
                
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isOscillationAlertEnabled,
                    onChanged: oscillationPercentage != 0.0 ? _toggleOscillationAlertEnabled : null,
                    
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ), const Spacer(),
                
                
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color:  Colors.red[300],
                  onPressed: _deleteOscillationAlert,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ) : null,
          )
          
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    final preferences = widget.preferences;
    final cubit = context.read<PreferencesCubit>();

    return Column(
      children: [
        
        _buildPreferenceItem(
          'Moeda Fiat padrão',
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF475569), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: preferences.selectedCurrency,
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD - Dólar Americano')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                  DropdownMenuItem(value: 'BRL', child: Text('BRL - Real Brasileiro')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP - Libra Esterlina')),
                  DropdownMenuItem(value: 'JPY', child: Text('JPY - Iene Japonês')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    cubit.updateCurrency(newValue);
                  }
                },
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 15),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                dropdownColor: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        
        _buildPreferenceItem(
          "",
          _buildCheckbox(
            preferences.startWithSystem,
            'Iniciar junto com o sistema',
            (value) => cubit.updateStartWithSystem(value),
          ),
        ),
        const SizedBox(height: 5),

        
        _buildPreferenceItem(
          "",
          _buildCheckbox(
            preferences.showNotifications,
            'Exibir notificações',
            (value) => cubit.updateShowNotifications(value),
          ),
        ),
        const SizedBox(height: 5),

        
        _buildPreferenceItem(
          "",
          _buildCheckbox(
            preferences.alertRecurring,
            'Tornar alertas recorrentes',
            (value) => cubit.updateAlertRecurring(value),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String label, Widget widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 4),
        ],
        widget,
      ],
    );
  }

  Widget _buildCheckbox(bool value, String text, Function(bool) onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: value ? const Color(0xFF3B82F6) : const Color(0xFF475569), width: 2),
                color: value ? const Color(0xFF3B82F6) : Colors.transparent,
              ),
              child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsItem(String label, Widget widget, Color valueColor, {Widget? iconTitle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty && iconTitle == null)
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        if (label.isNotEmpty && iconTitle != null)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(child: iconTitle), 
              ],
            ),
          ),

        const SizedBox(height: 4),
        widget,
      ],
    );
  }
}
