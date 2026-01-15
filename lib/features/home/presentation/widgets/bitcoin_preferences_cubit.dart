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

/// Formatter customizado que substitui vírgulas por pontos e limita casas decimais
class CommaToDecimalFormatter extends TextInputFormatter {
  final int maxDecimalPlaces;
  final int maxIntegerDigits;

  CommaToDecimalFormatter({
    this.maxDecimalPlaces = 8,
    this.maxIntegerDigits = 10, // Permite até 10 dígitos antes do ponto (mais que 21 milhões de BTC)
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Substitui vírgulas por pontos
    String newText = newValue.text.replaceAll(',', '.');

    // Evita múltiplos pontos decimais
    if (newText.split('.').length > 2) {
      return oldValue;
    }

    // Limita casas decimais e dígitos inteiros
    if (newText.contains('.')) {
      List<String> parts = newText.split('.');

      // Limita dígitos antes do ponto
      if (parts[0].length > maxIntegerDigits) {
        parts[0] = parts[0].substring(0, maxIntegerDigits);
      }

      // Limita casas decimais
      if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
        parts[1] = parts[1].substring(0, maxDecimalPlaces);
      }

      newText = parts.join('.');
    } else {
      // Se não tem ponto e atingiu o máximo de dígitos inteiros, adiciona o ponto automaticamente
      if (newText.length > maxIntegerDigits) {
        // Insere o ponto após os maxIntegerDigits
        newText = '${newText.substring(0, maxIntegerDigits)}.${newText.substring(maxIntegerDigits)}';

        // Limita as casas decimais que foram adicionadas automaticamente
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

/// Formatter customizado para moedas Fiat com formatação brasileira
class FiatCurrencyFormatter extends TextInputFormatter {
  final int maxDigits;

  FiatCurrencyFormatter({this.maxDigits = 15}); // Limita a ~999 trilhões

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Remove tudo que não for dígito
    newText = newText.replaceAll(RegExp(r'[^\d]'), '');

    // Se vazio, retorna 0,00
    if (newText.isEmpty) {
      return const TextEditingValue(text: '0,00', selection: TextSelection.collapsed(offset: 4));
    }

    // Limita o número de dígitos para evitar overflow
    if (newText.length > maxDigits) {
      newText = newText.substring(0, maxDigits);
    }

    // Remove zeros à esquerda desnecessários, mas mantém pelo menos um dígito
    newText = newText.replaceFirst(RegExp(r'^0+'), '');
    if (newText.isEmpty) {
      newText = '0';
    }

    try {
      // Converte para número e divide por 100 para ter centavos
      int number = int.parse(newText);
      double value = number / 100.0;

      // Formata usando NumberFormat
      final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');
      String formatted = formatter.format(value).trim();

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      // Se houver erro, retorna o valor anterior
      print('⚠️ Erro ao formatar valor: $e');
      return oldValue;
    }
  }
}

/// Widget que exibe as preferências do usuário com Cubit
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

/// Widget interno que contém o conteúdo das preferências
class _PreferencesContent extends StatefulWidget {
  final BitcoinData bitcoinData;
  final PreferencesLoaded preferences;

  const _PreferencesContent({required this.bitcoinData, required this.preferences});

  @override
  State<_PreferencesContent> createState() => _PreferencesContentState();
}

class _PreferencesContentState extends State<_PreferencesContent> {
  String selectedTab = 'Alertas';
  String selectedCurrency = 'USD'; // Moeda selecionada para alertas
  double oscillationPercentage = 0.0; // Porcentagem de oscilação (-100 a +100)

  // Controladores para o campo de alerta de preço Fiat
  late TextEditingController _priceAlertController;
  late FocusNode _priceAlertFocusNode;
  bool _isPriceAlertEditable = false; // Controla se o campo está editável
  bool _isPriceAlertEnabled = false; // Controla se o alerta está ativado
  bool _isCreatingNewAlert = false; // Controla se está no modo de criar novo alerta

  // Controladores e FocusNode para o TextField de oscilação
  late TextEditingController _oscillationController;
  late FocusNode _oscillationFocusNode;
  bool _isOscillationAlertEnabled = false; // Controla se o alerta de oscilação está ativado
  bool _isCreatingNewOscillationAlert = false; // Controla se está no modo de criar novo alerta de oscilação
  bool _isOscillationEditable = false; // Controla se o slider de oscilação está editável

  @override
  void initState() {
    super.initState();
    // Inicializa selectedCurrency com o valor atual das preferências
    selectedCurrency = widget.preferences.selectedCurrency;

    // Inicializa o controller de preço ANTES de carregar os alertas
    _priceAlertController = TextEditingController();
    _priceAlertFocusNode = FocusNode();

    // Inicializa o controller e FocusNode de oscilação
    _oscillationController = TextEditingController();
    _oscillationFocusNode = FocusNode();

    // Agora carrega os alertas salvos e preenche os campos
    _loadSavedAlerts();

    // Listener para detectar quando o campo de oscilação perde o foco
    _oscillationFocusNode.addListener(() {
      if (!_oscillationFocusNode.hasFocus) {
        // Quando perde o foco, salva se houver mudança
        _saveOscillationAlert();
        setState(() {
          print('🔒 Campo de oscilação desabilitado');
        });
      }
    });
  }

  /// Carrega os alertas salvos das preferências
  void _loadSavedAlerts() async {
    final prefs = widget.preferences;

    print('📥 _loadSavedAlerts iniciado');
    print('📥 Fiat ativo: ${prefs.alertTargetFiat}');
    print('📥 Oscilação ativa (prefs.alertOscillation): ${prefs.alertOscillation}');

    // Carrega o valor salvo da oscilação (independente de estar ativo)
    final savedOscillationValue = await PreferencesService.getSavedOscillationValue();
    print('📥 Valor salvo de oscilação (getSavedOscillationValue): $savedOscillationValue');
    
    // Se tem valor salvo, usa ele; senão usa o valor ativo
    if (savedOscillationValue != null && savedOscillationValue != 0.0) {
      oscillationPercentage = savedOscillationValue;
      _oscillationController.text = oscillationPercentage.toStringAsFixed(1);
      print('📥 Valor salvo de oscilação carregado: $savedOscillationValue%');
      
      // Se tem valor salvo, significa que não está em modo de edição
      _isOscillationEditable = false;
    } else if (prefs.alertOscillation != 0.0) {
      // Se não tem valor salvo mas tem alerta ativo, carrega do alerta ativo
      oscillationPercentage = prefs.alertOscillation;
      _oscillationController.text = oscillationPercentage.toStringAsFixed(1);
      print('📥 Alerta de oscilação ativo carregado: ${prefs.alertOscillation}%');
      
      // Se veio do alerta ativo, também não está editável
      _isOscillationEditable = false;
    } else {
      // Sem valor configurado
      oscillationPercentage = 0.0;
      _oscillationController.text = '0.0';
      _isOscillationEditable = false;
    }
    
    // Define se o alerta de oscilação está ativado (baseado no SharedPreferences, não no valor local)
    _isOscillationAlertEnabled = prefs.alertOscillation != 0.0;
    
    print('📥 Estado de oscilação: valor=$oscillationPercentage%, ativado=$_isOscillationAlertEnabled, editável=$_isOscillationEditable');

    // Sempre carrega o valor salvo do campo (independente do alerta estar ativo)
    final savedFieldValue = await PreferencesService.getSavedAlertValueFiat();
    print('📥 Valor salvo do campo: $savedFieldValue');

    // Verifica se o alerta está ativo (no SharedPreferences)
    final isAlertActive = prefs.alertTargetFiat != null && prefs.alertTargetFiat! > 0.0;
    
    // Se tem valor salvo no campo, sempre preenche
    if (savedFieldValue != null && savedFieldValue > 0.0) {
      print('📥 Preenchendo campo com valor salvo: $savedFieldValue');
      final value = (savedFieldValue * 100).toInt().toString();
      _priceAlertController.text = FiatCurrencyFormatter()
          .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
          .text;
      print('📥 Texto no controller: ${_priceAlertController.text}');
    } else if (isAlertActive) {
      // Se não tem valor salvo mas tem alerta ativo, usa o valor do alerta
      print('📥 Preenchendo campo com alerta ativo: ${prefs.alertTargetFiat}');
      final value = (prefs.alertTargetFiat! * 100).toInt().toString();
      _priceAlertController.text = FiatCurrencyFormatter()
          .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
          .text;
      print('📥 Texto no controller: ${_priceAlertController.text}');
    }

    // Define se o alerta está ativado baseado no SharedPreferences
    _isPriceAlertEnabled = isAlertActive;

    print(
      '🔔 Alertas carregados: Campo=$savedFieldValue, Ativo=${prefs.alertTargetFiat}, Oscilação=${prefs.alertOscillation}%, Switch=$_isPriceAlertEnabled',
    );
    
    // Força reconstrução do widget para mostrar os valores carregados
    setState(() {
      print('🔄 Widget reconstruído com valores carregados');
    });
  }

  /// Salva o alerta de oscilação se houver mudança
  Future<void> _saveOscillationAlert() async {
    final newValue = double.tryParse(_oscillationController.text.replaceAll('%', '').trim()) ?? oscillationPercentage;

    // Sempre salva o valor na chave separada (para não perder ao desativar)
    await PreferencesService.setSavedOscillationValue(newValue);
    
    // Atualiza o valor local
    oscillationPercentage = newValue;
    
    // Se o alerta estava desativado mas agora tem um valor, ativa automaticamente
    if (newValue != 0.0 && !_isOscillationAlertEnabled) {
      setState(() {
        _isOscillationAlertEnabled = true;
      });
      await context.read<PreferencesCubit>().updateAlertOscillation(newValue);
      print('💾 Alerta de oscilação salvo e ativado: $newValue%');
    } else if (_isOscillationAlertEnabled) {
      // Se está ativado, salva o valor no alerta ativo também
      await context.read<PreferencesCubit>().updateAlertOscillation(newValue);
      print('💾 Alerta de oscilação salvo: $newValue%');
    } else {
      // Se está desativado, apenas salva localmente
      print('💾 Valor de oscilação atualizado localmente: $newValue%');
    }
  }

  /// Alterna entre editar e salvar o alerta de oscilação
  void _toggleOscillationEdit() async {
    if (_isOscillationEditable) {
      // Está editando, agora vai salvar
      // Ativa o alerta ANTES de salvar (se tiver valor diferente de zero)
      if (oscillationPercentage != 0.0 && !_isOscillationAlertEnabled) {
        setState(() {
          _isOscillationAlertEnabled = true;
        });
      }
      
      // Agora salva com o estado correto
      await _saveOscillationAlert();
      
      setState(() {
        _isOscillationEditable = false;
      });
      print('✅ Alerta de oscilação salvo: $oscillationPercentage%, ativado: $_isOscillationAlertEnabled');
    } else {
      // Vai entrar em modo de edição
      setState(() {
        _isOscillationEditable = true;
      });
      print('✏️ Modo de edição de oscilação ativado');
    }
  }

  /// Alterna entre editar e salvar o alerta de preço
  void _togglePriceAlertEdit() async {
    if (_isPriceAlertEditable) {
      // Está editando, agora vai salvar
      await _savePriceAlertManually();
      setState(() {
        _isPriceAlertEditable = false;
      });
    } else {
      // Vai entrar em modo de edição
      setState(() {
        _isPriceAlertEditable = true;
      });
      // Dá foco ao campo
      _priceAlertFocusNode.requestFocus();
    }
  }

  /// Salva o alerta de preço manualmente (ao clicar no botão)
  Future<void> _savePriceAlertManually() async {
    final cubit = context.read<PreferencesCubit>();
    final text = _priceAlertController.text.trim();
    final prefs = widget.preferences;

    print('💾 _savePriceAlertManually - Texto no campo: "$text"');

    // Fiat - precisa converter de volta
    final numericText = text.replaceAll(RegExp(r'[^\d]'), '');
    final newValue = numericText.isNotEmpty ? int.parse(numericText) / 100.0 : 0.0;
    final savedValue = prefs.alertTargetFiat;

    print('💾 Fiat - Texto numérico: "$numericText"');
    print('💾 Fiat - Novo valor: $newValue, Salvo: $savedValue');

    // Validação: não permite salvar valor vazio ou zero
    if (text.isEmpty || text == '0,00' || newValue <= 0.0) {
      print('⚠️ Tentativa de salvar valor vazio ou zero');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um valor válido para o alerta'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Não salva e não sai do modo de edição
    }

    // Sempre salva o valor do campo separadamente (para manter ao desativar/reativar)
    await PreferencesService.setSavedAlertValueFiat(newValue);

    // Verifica se mudou
    if (newValue == savedValue) {
      print('ℹ️ Valor não mudou, mantendo: $savedValue $selectedCurrency');
      return;
    }

    // Salva o alerta
    await cubit.updateAlertTargetFiat(newValue);
    setState(() {
      _isPriceAlertEnabled = true;
    });
    print('💾 Alerta de preço Fiat salvo: $newValue $selectedCurrency');
  }

  /// Exclui o alerta completamente (campo, valor salvo e alerta ativo)
  void _deleteAlert() async {
    // Remove do SharedPreferences
    await context.read<PreferencesCubit>().updateAlertTargetFiat(null);
    await PreferencesService.setSavedAlertValueFiat(null);
    await PreferencesService.setLastTriggeredAlertFiat(null);
    
    // Limpa o campo
    _priceAlertController.clear();
    
    setState(() {
      _isPriceAlertEnabled = false;
      _isPriceAlertEditable = false;
      _isCreatingNewAlert = false; // Sai do modo de criar novo alerta
    });
    
    print('🗑️ Alerta excluído completamente');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta excluído'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Inicia o processo de criação de novo alerta
  void _startCreatingNewAlert() {
    setState(() {
      _isCreatingNewAlert = true;
      _isPriceAlertEditable = true;
    });
    // Dá foco ao campo
    _priceAlertFocusNode.requestFocus();
  }

  /// Inicia o processo de criação de novo alerta de oscilação
  void _startCreatingNewOscillationAlert() {
    setState(() {
      _isCreatingNewOscillationAlert = true;
      _isOscillationEditable = true; // Permite edição imediatamente
    });
  }

  /// Exclui o alerta de oscilação completamente
  void _deleteOscillationAlert() async {
    // Remove do SharedPreferences (tanto o ativo quanto o salvo)
    await context.read<PreferencesCubit>().updateAlertOscillation(0.0);
    
    // Remove também o valor salvo
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_oscillation_value');
    
    // Reseta os valores
    setState(() {
      oscillationPercentage = 0.0;
      _oscillationController.text = '0.0';
      _isOscillationAlertEnabled = false;
      _isCreatingNewOscillationAlert = false;
      _isOscillationEditable = false;
    });
    
    print('🗑️ Alerta de oscilação excluído completamente');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta de oscilação excluído'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Alterna o estado do alerta de oscilação (ativado/desativado)
  void _toggleOscillationAlertEnabled(bool value) async {
    // Verifica se tem valor configurado
    final hasValue = oscillationPercentage != 0.0;

    // Não permite ativar se não tem valor
    if (value && !hasValue) {
      print('⚠️ Não é possível ativar alerta de oscilação sem valor definido');
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
      // Desativou, salva o valor atual em uma chave separada para restaurar depois
      await PreferencesService.setSavedOscillationValue(oscillationPercentage);
      // Remove do SharedPreferences de alerta ativo
      await context.read<PreferencesCubit>().updateAlertOscillation(0.0);
      print('🔕 Alerta de oscilação desativado (valor salvo: $oscillationPercentage%)');
    } else {
      // Ativou, salva o valor atual
      await PreferencesService.setSavedOscillationValue(oscillationPercentage);
      await context.read<PreferencesCubit>().updateAlertOscillation(oscillationPercentage);
      print('🔔 Alerta de oscilação ativado: $oscillationPercentage%');
    }
  }

  /// Alterna o estado do alerta de preço (ativado/desativado)
  void _togglePriceAlertEnabled(bool value) async {
    final text = _priceAlertController.text.trim();
    final prefs = widget.preferences;

    // Verifica se tem valor no campo ou no SharedPreferences (apenas Fiat)
    final numericText = text.replaceAll(RegExp(r'[^\d]'), '');
    final fieldValue = numericText.isNotEmpty ? int.parse(numericText) / 100.0 : 0.0;
    
    // Tenta carregar o valor salvo do campo
    final savedFieldValue = await PreferencesService.getSavedAlertValueFiat() ?? 0.0;
    final savedValue = prefs.alertTargetFiat ?? 0.0;
    final hasValue = fieldValue > 0.0 || savedValue > 0.0 || savedFieldValue > 0.0;

    // Não permite ativar se não tem valor
    if (value && !hasValue) {
      print('⚠️ Não é possível ativar alerta sem valor definido');
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
      // Desativou, remove do SharedPreferences mas mantém o valor no campo
      // Salva o valor atual do campo para manter ao reiniciar
      if (fieldValue > 0.0) {
        await PreferencesService.setSavedAlertValueFiat(fieldValue);
      } else if (savedValue > 0.0) {
        await PreferencesService.setSavedAlertValueFiat(savedValue);
      }
      
      // Também salva como último alerta para possível restauração futura
      if (savedValue > 0.0) {
        await PreferencesService.setLastTriggeredAlertFiat(savedValue);
      }
      
      await context.read<PreferencesCubit>().updateAlertTargetFiat(null);
      print('🔕 Alerta de preço Fiat desativado (valor salvo: ${fieldValue > 0.0 ? fieldValue : savedValue})');
    } else {
      // Ativou, salva o valor atual
      // Prioridade: valor do campo > valor salvo do campo > savedValue
      final valueToSave = fieldValue > 0.0 ? fieldValue : (savedFieldValue > 0.0 ? savedFieldValue : savedValue);
      
      if (valueToSave > 0.0) {
        // Salva o valor do campo separadamente
        await PreferencesService.setSavedAlertValueFiat(valueToSave);
        
        // Ativa o alerta
        await context.read<PreferencesCubit>().updateAlertTargetFiat(valueToSave);
        
        // Atualiza o campo se estava vazio
        if (fieldValue == 0.0) {
          final value = (valueToSave * 100).toInt().toString();
          _priceAlertController.text = FiatCurrencyFormatter()
              .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: value))
              .text;
        }
        
        print('🔔 Alerta de preço Fiat ativado: $valueToSave $selectedCurrency');
      }
    }
  }

  /// Salva o alerta de preço quando o campo perde o foco
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
    
    // Atualiza selectedCurrency quando as preferências mudarem
    if (oldWidget.preferences.selectedCurrency != widget.preferences.selectedCurrency) {
      setState(() {
        selectedCurrency = widget.preferences.selectedCurrency;
      });
    }
    
    // Recarrega os alertas se mudarem
    if (oldWidget.preferences.alertTargetFiat != widget.preferences.alertTargetFiat ||
        oldWidget.preferences.alertOscillation != widget.preferences.alertOscillation) {
      print('🔄 Preferências de alerta mudaram, recarregando...');
      _loadSavedAlerts();
      setState(() {}); // Força reconstrução
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text(
          'Preferências',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        // Abas
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
        // Conteúdo
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
    // Verifica se deve mostrar os controles (tem alerta OU está criando novo)
    final bool showControls = (_priceAlertController.text.isNotEmpty && _priceAlertController.text != '0,00') || _isCreatingNewAlert;
    
    return Container(
      child: Column(
        children: [
          _buildAlertsItem(
            'Alertas de preço',
            iconTitle: showControls ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Switch
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isPriceAlertEnabled,
                    // Desabilita o Switch se não houver alerta salvo
                    onChanged: (_priceAlertController.text.isNotEmpty && _priceAlertController.text != '0,00')
                        ? _togglePriceAlertEnabled
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

                // Espaçador flexível para empurrar a lixeira para a direita
                const Spacer(),
                
                // Ícone de lixeira - sempre aparece quando showControls é true
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
            
            // Conteúdo: TextField com botão Save OU botão "Novo alerta"
            showControls ?
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Color(AppColors.cardIndicator), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  /* Row(
                    children: [
                      Expanded(child: _buildPriceAlertButton('BTC', selectedPriceAlert == 'BTC')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPriceAlertButton(selectedCurrency, selectedPriceAlert != 'BTC')),
                    ],
                  ),
                  const SizedBox(height: 5), */

                  
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
                            print('💰 [Alerta de Preço] Valor digitado: $value');
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
            // Botão "Novo alerta de preço" quando não há alerta
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
          
          // Alerta de oscilação - mostra botão ou controles
          _buildAlertsItem(
            'Alertas de oscilação (%)',
            ((oscillationPercentage != 0.0) || _isCreatingNewOscillationAlert || _isOscillationAlertEnabled) ?
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(AppColors.cardIndicator), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    // Slider para seleção visual
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicador de valor atual
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
                        padding: const EdgeInsets.symmetric(horizontal: 12 /* vertical: 6 */),
                        decoration: BoxDecoration(
                          color: oscillationPercentage >= 0
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          /*  border: Border.all(
                            color: oscillationPercentage >= 0 
                              ? Colors.green
                              : Colors.red,
                            width: 1,
                          ), */
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
                      //  const SizedBox(height: 12),
                      // Slider
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
                              // Atualiza o controller do TextField
                              _oscillationController.text = value.toStringAsFixed(1);
                            });
                          } : null, // Desabilita o slider quando não estiver editável
                        ),
                      ),
                      // Legendas
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
              // const SizedBox(width: 4),
                // Switch para ativar/desativar
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _isOscillationAlertEnabled,
                    onChanged: oscillationPercentage != 0.0 ? _toggleOscillationAlertEnabled : null,
                    //activeThumbColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ), const Spacer(),
                
                // Ícone de lixeira
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
        // Moeda Fiat
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

        // Checkbox Iniciar com Sistema
        _buildPreferenceItem(
          "",
          _buildCheckbox(
            preferences.startWithSystem,
            'Iniciar junto com o sistema',
            (value) => cubit.updateStartWithSystem(value),
          ),
        ),
        const SizedBox(height: 5),

        // Checkbox Notificações
        _buildPreferenceItem(
          "",
          _buildCheckbox(
            preferences.showNotifications,
            'Exibir notificações',
            (value) => cubit.updateShowNotifications(value),
          ),
        ),
        const SizedBox(height: 5),

        // Checkbox Alertas Recorrentes
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
                Expanded(child: iconTitle), // Envolve em Expanded para permitir Spacer interno
              ],
            ),
          ),

        const SizedBox(height: 4),
        widget,
      ],
    );
  }
}
