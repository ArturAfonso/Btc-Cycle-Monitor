import 'package:btc_cycle_monitor/core/constants/app_constants.dart';
import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_data.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/preferences/preferences_cubit.dart';
import '../../../../core/preferences/preferences_state.dart';


class BitcoinStats extends StatelessWidget {
  final BitcoinData bitcoinData;

  const BitcoinStats({
    super.key,
    required this.bitcoinData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, preferencesState) {
        String selectedCurrency = 'USD'; 

        
        if (preferencesState is PreferencesLoaded) {
           selectedCurrency = preferencesState.selectedCurrency;

        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(AppColors.cardColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estatísticas 24h',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 10),
              _buildStatItem('Máxima', Utility().priceToCurrency(bitcoinData.maxPrice24h, fiat: selectedCurrency), valueColor: Color(AppColors.successColor)),
              const SizedBox(height: 5),
              _buildStatItem('Mínima', Utility().priceToCurrency(bitcoinData.minPrice24h, fiat: selectedCurrency), valueColor: Color(AppColors.errorColor)),
              const SizedBox(height: 5),
              _buildStatItem('Volume 24h', NumberFormatter.formatLargeNumber(bitcoinData.volume24h * 1e9, decimals: 1, fiat: selectedCurrency)),
              
              const SizedBox(height: 5),
              _buildStatItem('Market Cap', NumberFormatter.formatLargeNumber(bitcoinData.marketCap * 1e12, decimals: 2, fiat: selectedCurrency)),
             
              const SizedBox(height: 5),
              _buildStatItem('Fornecimento Circ.', '${Utility().priceToCurrency(bitcoinData.circulatingSupply, fiat: selectedCurrency)}M BTC'),
              const SizedBox(height: 5),
              _buildStatItem('Dominância', '${bitcoinData.dominance.toStringAsFixed(1)}%'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value,{Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style:  TextStyle(
            color: valueColor ??Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}