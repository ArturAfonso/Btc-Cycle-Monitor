import 'package:btc_cycle_monitor/core/preferences/preferences_cubit.dart';
import 'package:btc_cycle_monitor/core/preferences/preferences_state.dart';
import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/home_data.dart';
import '../../data/models/bitcoin_historical_data_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'bitcoin_header.dart';

/// Widget que exibe o gráfico do Bitcoin usando fl_chart
class BitcoinChart extends StatefulWidget {
  final BitcoinData bitcoinData;

  const BitcoinChart({super.key, required this.bitcoinData});

  @override
  State<BitcoinChart> createState() => _BitcoinChartState();
}

class _BitcoinChartState extends State<BitcoinChart> {
  /// Retorna a cor da linha do gráfico baseada na mudança de preço
  Color get lineColor {
    final isPositive = widget.bitcoinData.changePercentage > 0;
    return isPositive
        ? const Color(AppColors.successColor) // Verde para alta
        : const Color(0xFFEF4444); // Vermelho para baixa
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(AppColors.cardColor), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BitcoinHeader(bitcoinData: widget.bitcoinData),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      // Verifica se está carregando dados do gráfico
                      final isLoadingChart = state is HomeLoaded && state.isLoadingChart;

                      // Usa os dados do estado para garantir que estão atualizados
                      BitcoinHistoricalDataModel? historicalData = widget.bitcoinData.historicalData;

                      if (state is HomeLoaded && state.data.bitcoinData != null) {
                        historicalData = state.data.bitcoinData!.historicalData;
                      }

                      return BlocBuilder<PreferencesCubit, PreferencesState>(
                        
                        builder: (context, state) {
                          String selectedCurrency = 'USD'; // Default
                           if (state is PreferencesLoaded) {
          selectedCurrency = state.selectedCurrency;
        }

                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              // Gráfico principal usando fl_chart
                              if (historicalData != null && historicalData.prices.isNotEmpty)
                                _buildLineChart(historicalData, selectedCurrency)
                              else
                                _buildEmptyChart(),

                              // Overlay de loading se estiver carregando
                              if (isLoadingChart)
                                Container(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(lineColor),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BitcoinHistoricalDataModel historicalData, String selectedCurrency) {
    print('📊 BitcoinChart: Rendering chart with ${historicalData.prices.length} points in $selectedCurrency');
    
    // Cria os pontos do gráfico diretamente dos preços da API
    // A API já retorna os preços na moeda selecionada
    final spots = historicalData.prices.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1; // 10% padding

    // Lógica simples: sempre 4 divisões iguais
    final chartMinY = minY - padding;
    final chartMaxY = maxY + padding;
    final range = chartMaxY - chartMinY;
    final yInterval = range / 4; // 4 intervalos = 5 valores (0, 1, 2, 3, 4)

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [lineColor, lineColor]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        minY: chartMinY,
        maxY: chartMaxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: yInterval,
              getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, chartMinY, chartMaxY),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length / 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < historicalData.prices.length) {
                  final date = historicalData.prices[index].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _formatDateForPeriod(date),
                      style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 9),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(AppColors.cardColor),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < historicalData.prices.length) {
                  final point = historicalData.prices[index];
                  final cubit = context.read<HomeCubit>();

                  // Formatação do tooltip baseada no período
                  String dateFormat = switch (cubit.selectedPeriod) {
                    '1D' => 'dd/MM HH:mm', // 28/10 14:30 (mostra dia e hora)
                    '1W' => 'dd/MM HH:mm', // 28/10 14:30
                    '1M' => 'dd/MM', // 28/10 (apenas dia)
                    '3M' => 'dd/MM', // 28/10 (apenas dia)
                    '1Y' => 'MMM/yy', // Out/24
                    _ => 'dd/MM HH:mm',
                  };
                  print('${Utility().priceToCurrency(point.price, fiat: selectedCurrency)}\n${DateFormat(dateFormat).format(point.timestamp)}');

                  return LineTooltipItem(
                    '${Utility().priceToCurrency(point.price, fiat: selectedCurrency)}\n${DateFormat(dateFormat).format(point.timestamp)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            // Adiciona feedback haptic se necessário
            // HapticFeedback.lightImpact();
          },
          handleBuiltInTouches: true,
        ),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildEmptyChart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Color(AppColors.textSecondary)),
          SizedBox(height: 16),
          Text('Carregando dados do gráfico...', style: TextStyle(color: Color(AppColors.textSecondary), fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDateForPeriod(DateTime date) {
    final cubit = context.read<HomeCubit>();
    switch (cubit.selectedPeriod) {
      case '1D':
        return DateFormat('dd/MM\nHH:mm').format(date); // 28/10\n14:30 (dia e hora em linhas separadas)
      case '1W':
        return DateFormat('EEE dd').format(date); // Seg 28
      case '1M':
        return DateFormat('dd').format(date); // 28 (apenas dia do mês)
      case '3M':
        return DateFormat('dd/MM').format(date); // 28/10
      case '1Y':
        return DateFormat('MMM').format(date); // Out
      default:
        return DateFormat('dd/MM\nHH:mm').format(date);
    }
  }

  // Método simples para títulos do eixo Y
  Widget _leftTitleWidgets(double value, TitleMeta meta, double chartMinY, double chartMaxY) {
    // Calcula os 5 valores fixos que queremos mostrar
    final range = chartMaxY - chartMinY;
    final step = range / 4;

    final targetValues = [
      chartMinY, // Valor mínimo
      chartMinY + step, // 25%
      chartMinY + step * 2, // 50%
      chartMinY + step * 3, // 75%
      chartMaxY, // Valor máximo
    ];

    // Verifica se o valor atual está próximo de algum dos targets
    for (double target in targetValues) {
      if ((value - target).abs() < step * 0.1) {
        // 10% de tolerância
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            _formatPrice(target),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(AppColors.textSecondary), fontSize: 10),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(0)}k';
    } else {
      return '\$${price.toStringAsFixed(0)}';
    }
  }
}
