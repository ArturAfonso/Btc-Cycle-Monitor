import 'package:btc_cycle_monitor/core/preferences/preferences_cubit.dart';
import 'package:btc_cycle_monitor/core/preferences/preferences_state.dart';
import 'package:btc_cycle_monitor/core/services/preferences_service.dart';
import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_data.dart';
import '../cubit/home_cubit.dart';

/// Widget que exibe o cabeçalho com informações do Bitcoin
class BitcoinHeader extends StatefulWidget {
  final BitcoinData bitcoinData;

  const BitcoinHeader({super.key, required this.bitcoinData});

  @override
  State<BitcoinHeader> createState() => _BitcoinHeaderState();
}

class _BitcoinHeaderState extends State<BitcoinHeader> {
 





  @override
  Widget build(BuildContext context) {
    final isPositive = widget.bitcoinData.changePercentage > 0;
    final homeCubit = context.read<HomeCubit>();

    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, preferencesState) {
         String selectedCurrency = 'USD'; // Default
        
        if (preferencesState is PreferencesLoaded) {
          selectedCurrency = preferencesState.selectedCurrency;
        }
        return SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                          Text(
                                    'Bitcoin (BTC/${selectedCurrency.toUpperCase()})',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            const SizedBox(width: 8),
                            // Indicador de atualização automática com tooltip
                            Tooltip(
                              message: 'Atualização automática ativa (a cada 2 minutos)',
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPeriodButton('1D', homeCubit.selectedPeriod == '1D', homeCubit),
                          const SizedBox(width: 8),
                          _buildPeriodButton('1W', homeCubit.selectedPeriod == '1W', homeCubit),
                          const SizedBox(width: 8),
                          _buildPeriodButton('1M', homeCubit.selectedPeriod == '1M', homeCubit),
                          const SizedBox(width: 8),
                          _buildPeriodButton('3M', homeCubit.selectedPeriod == '3M', homeCubit),
                          const SizedBox(width: 8),
                          _buildPeriodButton('1Y', homeCubit.selectedPeriod == '1Y', homeCubit),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Utility().priceToCurrency(widget.bitcoinData.currentPrice, fiat: selectedCurrency, ),
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${widget.bitcoinData.changeAmount.toStringAsFixed(2)} (${isPositive ? '+' : ''}${widget.bitcoinData.changePercentage.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildPeriodButton(String period, bool isSelected, HomeCubit cubit) {
    return InkWell(
      onTap: () {
        cubit.changePeriod(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF334155) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}







 /*  const Text(
                  'Bitcoin (BTC/USD)',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8), */