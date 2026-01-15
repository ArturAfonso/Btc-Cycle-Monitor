import 'package:btc_cycle_monitor/core/utils/utility.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget que exibe o indicador Pi Cycle Top
/// 
/// Mostra:
/// - Status atual (Topo, Aproximando, Normal)
/// - Gráfico visual mostrando proximidade das médias
/// - Valores das médias móveis (SMA 111 e SMA 350 x 2)
/// - Distância percentual entre as médias
/// - Ícone/emoji indicando o estado
class PiCycleTopWidget extends StatelessWidget {
  final double? sma111;
  final double? sma350x2;
  final double? distance;
  final String status;
  final String message;

  const PiCycleTopWidget({
    super.key,
    required this.sma111,
    required this.sma350x2,
    required this.distance,
    required this.status,
    required this.message,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'top':
        return Colors.red.shade700;
      case 'approaching':
        return Colors.orange.shade700;
      case 'normal':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'top':
        return Icons.warning_rounded;
      case 'approaching':
        return Icons.trending_up_rounded;
      case 'normal':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case 'top':
        return 'SINAL DE TOPO';
      case 'approaching':
        return 'APROXIMANDO DO TOPO';
      case 'normal':
        return 'MERCADO NORMAL';
      default:
        return 'DADOS INSUFICIENTES';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusTitle = _getStatusTitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com status
        Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                statusTitle,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
    
        // Mensagem descritiva
        Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 13,
          ),
        ),
    
        if (sma111 != null && sma350x2 != null) ...[
          const SizedBox(height: 8),
          const Divider(height: 2),
          const SizedBox(height: 8),
    
          // Gráfico visual de proximidade
          _buildProximityChart(),
          const SizedBox(height: 5),
    
          // Valores das médias móveis
          _buildMetricRow(
            label: 'SMA 111',
            value: Utility().priceToCurrency(sma111!),   //'\$${sma111!.toStringAsFixed(2)}',
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 5),
          _buildMetricRow(
            label: 'SMA 350 x 2',
            value: Utility().priceToCurrency(sma350x2!), //'\$${sma350x2!.toStringAsFixed(2)}',
            color: Colors.purple.shade400,
          ),
    
          if (distance != null) ...[
            const SizedBox(height: 5),
            _buildMetricRow(
              label: 'Distância',
              value: '${distance! >= 0 ? '+' : ''}${distance!.toStringAsFixed(2)}%',
              color: distance! >= 0 ? Colors.red.shade400 : Colors.green.shade400,
            ),
          ],
        ],
    
        // Rodapé informativo
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Pi Cycle Top detecta topos de mercado quando SMA 111 cruza acima de SMA 350 x 2',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o gráfico visual de proximidade entre as médias
  Widget _buildProximityChart() {
    if (sma111 == null || sma350x2 == null) {
      return const SizedBox.shrink();
    }

    // Calcula a porcentagem do Pi Cycle Top
    // Fórmula: (SMA 111 / SMA 350 x 2) × 100
    // - 0%: SMA 111 muito abaixo (mercado frio)
    // - 50%: SMA 111 na metade do caminho
    // - 100%: SMA 111 cruzou SMA 350 x 2 (TOPO!)
    // - >100%: SMA 111 muito acima (topo confirmado)
    final double percentage = (sma111! / sma350x2!) * 100;
    
    print('🎨 [Pi Cycle] SMA 111: \$${sma111!.toStringAsFixed(2)}, SMA 350x2: \$${sma350x2!.toStringAsFixed(2)}, Percentage: ${percentage.toStringAsFixed(1)}%');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Proximidade do Topo',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getProgressColor(percentage),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Barra de progresso
        Stack(
          children: [
            // Container de fundo
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Barra de progresso preenchida
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 24,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (percentage / 100).clamp(0.0, 1.0), // Limita a 100% visual
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.yellow.shade700,
                          Colors.orange.shade600,
                          Colors.red.shade600,
                        ],
                        stops: const [0.0, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Marcadores de texto sobrepostos
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '50',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '100',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Retorna a cor do progresso baseado na porcentagem
  Color _getProgressColor(double percentage) {
    if (percentage >= 90) {
      return Colors.red.shade400;
    } else if (percentage >= 70) {
      return Colors.orange.shade400;
    } else {
      return Colors.green.shade400;
    }
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
