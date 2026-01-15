import 'package:flutter/material.dart';

/// Widget para exibir a dominância do Bitcoin com barra de progresso visual
class BitcoinDominanceWidget extends StatelessWidget {
  final double dominance;
  final String status;
  final String message;
  final double cycleProximity;

  const BitcoinDominanceWidget({
    super.key,
    required this.dominance,
    required this.status,
    required this.message,
    required this.cycleProximity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status e ícone
        Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Gráfico de proximidade ao fim do ciclo
        _buildCycleProximityChart(),
        
        const SizedBox(height: 16),
        
        // Métricas detalhadas
        _buildMetrics(),
        
        const Spacer(),
        
        // Rodapé com explicação
        _buildFooterInfo(),
      ],
    );
  }

  /// Constrói o ícone do status
  Widget _buildStatusIcon() {
    IconData icon;
    switch (status) {
      case 'extreme_fear':
        icon = Icons.shield; // Proteção/segurança
        break;
      case 'fear':
        icon = Icons.trending_up; // Subindo para BTC
        break;
      case 'neutral':
        icon = Icons.balance; // Equilíbrio
        break;
      case 'greed':
        icon = Icons.trending_down; // Descendo do BTC
        break;
      case 'extreme_greed':
        icon = Icons.rocket_launch; // Altseason
        break;
      default:
        icon = Icons.help_outline;
    }
    
    return Icon(
      icon,
      color: _getStatusColor(),
      size: 16,
    );
  }

  /// Constrói o gráfico de proximidade ao fim do ciclo
  Widget _buildCycleProximityChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Proximidade do Fim de Ciclo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${cycleProximity.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getCycleProximityColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Barra de progresso customizada - igual ao Pi Cycle Top
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF334155), // Fundo cinza escuro para área não preenchida
          ),
          child: Stack(
            children: [
              // Barra preenchida apenas até a porcentagem atual
              FractionallySizedBox(
                widthFactor: cycleProximity <= 0 ? 0.05 : cycleProximity / 100, // Mínimo de 5% quando for 0
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _getGradientColors(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Escala de referência
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
            Text(
              '50',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
            Text(
              '100',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói as métricas detalhadas
  Widget _buildMetrics() {
    return Column(
      children: [
        _buildMetricRow('Dominância BTC', '${dominance.toStringAsFixed(1)}%', _getStatusColor()),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Interpretação', 
          _getInterpretationText(), 
          const Color(0xFF94A3B8),
        ),
      ],
    );
  }

  /// Constrói uma linha de métrica
  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Constrói o rodapé informativo
  Widget _buildFooterInfo() {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 12,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Dominância baixa indica dinheiro fluindo para altcoins (fim de ciclo)',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Retorna as cores do gradiente baseado na proximidade do ciclo
  List<Color> _getGradientColors() {
    // Se a proximidade for muito baixa, usa apenas azul
    if (cycleProximity <= 20) {
      return [
        const Color(0xFF3B82F6), // Azul
        const Color(0xFF3B82F6), // Azul
      ];
    }
    // Se for baixa-média, usa azul → ciano
    else if (cycleProximity <= 40) {
      return [
        const Color(0xFF3B82F6), // Azul
        const Color(0xFF06B6D4), // Ciano
      ];
    }
    // Se for média, usa azul → amarelo
    else if (cycleProximity <= 60) {
      return [
        const Color(0xFF3B82F6), // Azul
        const Color(0xFF06B6D4), // Ciano
        const Color(0xFFFFB800), // Amarelo
      ];
    }
    // Se for alta, usa azul → laranja
    else if (cycleProximity <= 80) {
      return [
        const Color(0xFF3B82F6), // Azul
        const Color(0xFF06B6D4), // Ciano
        const Color(0xFFFFB800), // Amarelo
        const Color(0xFFEAB308), // Laranja
      ];
    }
    // Se for muito alta, usa todas as cores até vermelho
    else {
      return [
        const Color(0xFF3B82F6), // Azul
        const Color(0xFF06B6D4), // Ciano
        const Color(0xFFFFB800), // Amarelo
        const Color(0xFFEAB308), // Laranja
        const Color(0xFFEF4444), // Vermelho
      ];
    }
  }

  /// Retorna a cor baseada no status
  Color _getStatusColor() {
    switch (status) {
      case 'extreme_fear':
        return const Color(0xFF3B82F6); // Azul
      case 'fear':
        return const Color(0xFF06B6D4); // Ciano
      case 'neutral':
        return const Color(0xFFFFB800); // Amarelo
      case 'greed':
        return const Color(0xFFEAB308); // Laranja
      case 'extreme_greed':
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF6B7280); // Cinza
    }
  }

  /// Retorna a cor baseada na proximidade do ciclo
  Color _getCycleProximityColor() {
    if (cycleProximity <= 20) return const Color(0xFF3B82F6); // Azul
    if (cycleProximity <= 40) return const Color(0xFF06B6D4); // Ciano
    if (cycleProximity <= 60) return const Color(0xFFFFB800); // Amarelo
    if (cycleProximity <= 80) return const Color(0xFFEAB308); // Laranja
    return const Color(0xFFEF4444); // Vermelho
  }

  /// Retorna o texto de interpretação simplificado
  String _getInterpretationText() {
    switch (status) {
      case 'extreme_fear':
        return 'Início de Ciclo';
      case 'fear':
        return 'Bear Market';
      case 'neutral':
        return 'Meio de Ciclo';
      case 'greed':
        return 'Bull Market';
      case 'extreme_greed':
        return 'Fim de Ciclo';
      default:
        return 'Indefinido';
    }
  }
}