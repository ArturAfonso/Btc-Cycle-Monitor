import 'package:btc_cycle_monitor/core/constants/app_constants.dart';
import 'package:btc_cycle_monitor/core/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_data.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';

/// Widget que exibe a análise de preço do Bitcoin
class AppPreferences extends StatefulWidget {
  final BitcoinData bitcoinData;

  const AppPreferences({super.key, required this.bitcoinData});

  @override
  State<AppPreferences> createState() => _AppPreferencesState();
}

class _AppPreferencesState extends State<AppPreferences> {
  String selectedTab = 'Alertas'; // Variável para controlar qual aba está selecionada
  String selectedPriceAlert = 'BTC'; // Variável para controlar qual alerta de preço está selecionado
  String selectedCurrency = 'USD'; // Moeda selecionada
  String selectedInterval = '30s'; // Intervalo de atualização
  String selectedTheme = 'dark'; // Tema selecionado
  bool startWithSystem = false; // Checkbox para iniciar com sistema
  bool showNotifications = false; // Checkbox para exibir notificações
  bool _isLoading = true; // Estado de carregamento

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Carrega as preferências salvas
  Future<void> _loadPreferences() async {
    try {
      final prefs = await PreferencesService.loadAllPreferences();
      setState(() {
        selectedCurrency = prefs['currency'];
        selectedInterval = prefs['interval'];
        selectedTheme = prefs['theme'];
        startWithSystem = prefs['startWithSystem'];
        showNotifications = prefs['showNotifications'];
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar preferências: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Salva uma preferência específica
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      switch (key) {
        case 'currency':
          await PreferencesService.setSelectedCurrency(value);
          break;
        case 'interval':
          await PreferencesService.setSelectedInterval(value);
          break;
        case 'theme':
          await PreferencesService.setSelectedTheme(value);
          break;
        case 'startWithSystem':
          await PreferencesService.setStartWithSystem(value);
          break;
        case 'showNotifications':
          await PreferencesService.setShowNotifications(value);
          break;
      }
    } catch (e) {
      print('Erro ao salvar preferência $key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppColors.cardColor) /* const Color(0xFF1E293B) */,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferências',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Abas Resumo e Técnica
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(16)),

            //   color: Color(0xFF2A3139),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Alertas', selectedTab == 'Alertas')),
                const SizedBox(width: 12),
                Expanded(child: _buildTabButton('Configurações', selectedTab == 'Configurações')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Conteúdo da análise
      selectedTab == 'Alertas' ? _dataAlertsTabContent() : _dataSettingsbContent(),
        ],
      ),
    );
  }

  Widget _buildPriceAlertButton(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPriceAlert = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ?  Colors.red : Colors.pink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = title; // Atualiza para a aba clicada
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A3139) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, Widget widget, Color valueColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
          visible: label.isNotEmpty,
          child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14))),
        SizedBox(height: 4),
        widget,
      ],
    );
  }

   Widget _dataAlertsTabContent() {
    return  Container(
            child: Column(
              children: [
                _buildAnalysisItem('Alertas de preço',   Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(16)),

            //   color: Color(0xFF2A3139),
            child: Row(
              children: [
                Expanded(child: _buildPriceAlertButton('BTC', selectedPriceAlert == 'BTC')),
                const SizedBox(width: 12),
                Expanded(child: _buildPriceAlertButton(selectedCurrency, selectedPriceAlert != 'BTC')),
              ],
            ),
          ), Colors.green),
         
              ],
            ),
          );
  }

   Widget _dataSettingsbContent() {
    List<DropdownMenuItem<String>> listFiat = [
      const DropdownMenuItem(value: 'USD', child: Text('USD - Dólar Americano')),
      const DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
      const DropdownMenuItem(value: 'BRL', child: Text('BRL - Real Brasileiro')),
      const DropdownMenuItem(value: 'GBP', child: Text('GBP - Libra Esterlina')),
      const DropdownMenuItem(value: 'JPY', child: Text('JPY - Iene Japonês')),
    ];
    
    return Container(
      child: Column(
        children: [
          _buildAnalysisItem(
            'Moeda Fiat padrão', 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, /* vertical: 2 */),
              decoration: BoxDecoration(
                color: const Color(0xFF334155), // Cor de fundo escura
                borderRadius:BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF475569), // Borda sutil
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  
                  value: selectedCurrency,
                  items: listFiat,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCurrency = newValue ?? 'USD';
                    });
                    _savePreference('currency', newValue ?? 'USD');
                  },
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF94A3B8),
                    size: 15,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: const Color(0xFF334155), // Cor do menu dropdown
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ), 
            Colors.green
          ),
          const SizedBox(height: 5),
          _buildAnalysisItem(
            "", // Label em branco conforme solicitado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Checkbox circular personalizado
                  InkWell(
                    onTap: () {
                      setState(() {
                        startWithSystem = !startWithSystem;
                      });
                      _savePreference('startWithSystem', startWithSystem);
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: startWithSystem 
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF475569),
                          width: 2,
                        ),
                        color: startWithSystem 
                          ? const Color(0xFF3B82F6) 
                          : Colors.transparent,
                      ),
                      child: startWithSystem
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Texto clicável
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          startWithSystem = !startWithSystem;
                        });
                        _savePreference('startWithSystem', startWithSystem);
                      },
                      child: const Text(
                        'Iniciar junto com o sistema',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Colors.blue,
          ),
          const SizedBox(height: 5),
          _buildAnalysisItem(
            "", // Label em branco conforme solicitado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Checkbox circular personalizado
                  InkWell(
                    onTap: () {
                      setState(() {
                        showNotifications = !showNotifications;
                      });
                      _savePreference('showNotifications', showNotifications);
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: showNotifications
                            ? const Color(0xFF3B82F6) 
                            : const Color(0xFF475569),
                          width: 2,
                        ),
                        color: showNotifications 
                          ? const Color(0xFF3B82F6) 
                          : Colors.transparent,
                      ),
                      child: showNotifications
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Texto clicável
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showNotifications = !showNotifications;
                        });
                        _savePreference('showNotifications', showNotifications);
                      },
                      child: const Text(
                        'Exibir notificações',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Colors.blue,
          ),
        ],
      ),
    );
  }
}
