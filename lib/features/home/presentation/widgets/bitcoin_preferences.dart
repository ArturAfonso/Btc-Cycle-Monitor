import 'package:btc_cycle_monitor/core/constants/app_constants.dart';
import 'package:btc_cycle_monitor/core/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_data.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';


class AppPreferences extends StatefulWidget {
  final BitcoinData bitcoinData;

  const AppPreferences({super.key, required this.bitcoinData});

  @override
  State<AppPreferences> createState() => _AppPreferencesState();
}

class _AppPreferencesState extends State<AppPreferences> {
  String selectedTab = 'Alertas'; 
  String selectedPriceAlert = 'BTC'; 
  String selectedCurrency = 'USD'; 
  String selectedInterval = '30s'; 
  String selectedTheme = 'dark'; 
  bool startWithSystem = false; 
  bool showNotifications = false; 
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  
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
      debugPrint('Erro ao carregar preferências: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  
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
      debugPrint('Erro ao salvar preferência $key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(AppColors.cardColor),
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
          selectedTab = title; 
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
              padding: const EdgeInsets.symmetric(horizontal: 10,),
              decoration: BoxDecoration(
                color: const Color(0xFF334155), 
                borderRadius:BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF475569), 
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
                  dropdownColor: const Color(0xFF334155), 
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ), 
            Colors.green
          ),
          const SizedBox(height: 5),
          _buildAnalysisItem(
            "", 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  
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
            "", 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  
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
