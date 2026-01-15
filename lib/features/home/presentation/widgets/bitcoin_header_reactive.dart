import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_data.dart';
import '../cubit/home_cubit.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';
import '../../../../core/utils/utility.dart';

/// Widget reativo que exibe o cabeçalho com informações do Bitcoin
/// Escuta automaticamente mudanças na moeda selecionada via PreferencesCubit
class BitcoinHeaderReactive extends StatelessWidget {
  final BitcoinData bitcoinData;

  const BitcoinHeaderReactive({super.key, required this.bitcoinData});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, preferencesState) {
        String selectedLocale = 'ru_RU'; // Default - Rublo russo
        String selectedCurrency = 'RUB'; // Para exibição do código
        
        if (preferencesState is PreferencesLoaded) {
          selectedLocale = preferencesState.selectedLocale;
          selectedCurrency = preferencesState.selectedCurrency;
          print('🎯 BitcoinHeaderReactive: Locale do state = $selectedLocale');
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF334155),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bitcoinData.changePercentage >= 0 
                ? Colors.green.withOpacity(0.3) 
                : Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com logo e refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7931A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.currency_bitcoin,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bitcoin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'BTC • ${selectedCurrency.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.read<HomeCubit>().refreshData();
                      },
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Preço principal e variação
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Utility().priceToCurrency(bitcoinData.currentPrice, fiat: selectedCurrency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              bitcoinData.changePercentage >= 0 
                                ? Icons.trending_up 
                                : Icons.trending_down,
                              color: bitcoinData.changePercentage >= 0 
                                ? Colors.green 
                                : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${bitcoinData.changePercentage >= 0 ? '+' : ''}${bitcoinData.changePercentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: bitcoinData.changePercentage >= 0 
                                  ? Colors.green 
                                  : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${Utility().priceToCurrency(bitcoinData.changeAmount,fiat: selectedCurrency )})',
                              style: TextStyle(
                                color: bitcoinData.changePercentage >= 0 
                                  ? Colors.green 
                                  : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Estatísticas adicionais
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Máx. 24h',
                      Utility().priceToCurrency(bitcoinData.maxPrice24h, fiat: selectedCurrency,),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Mín. 24h',
                      Utility().priceToCurrency(bitcoinData.minPrice24h, fiat: selectedCurrency,),
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Volume 24h',
                      _formatCompactPrice(bitcoinData.volume24h, selectedLocale),
                      const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactPrice(double price, String locale) {
    // Mapa de símbolos de moeda por locale
    final Map<String, String> currencySymbols = {
      'en_US': '\$',
      'pt_BR': 'R\$',
      'de_DE': '€',
      'en_GB': '£',
      'ja_JP': '¥',
      'ru_RU': '₽',
    };
    
    final symbol = currencySymbols[locale] ?? '₽';
    
    if (price >= 1000000000) {
      return '$symbol${(price / 1000000000).toStringAsFixed(1)}B';
    } else if (price >= 1000000) {
      return '$symbol${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '$symbol${(price / 1000).toStringAsFixed(1)}K';
    }
    return Utility().priceToCurrency(price,fiat:locale );
  }
}