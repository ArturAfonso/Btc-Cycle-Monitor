import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

/// Widget de gauge (medidor semicircular) para o Fear & Greed Index
class FearGreedGauge extends StatelessWidget {
  final int value; // 0-100
  final String classification;
  final Color color;

  const FearGreedGauge({
    super.key,
    required this.value,
    required this.classification,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('fear_greed_gauge_sized_box'),
     // height: 184,
      child: Column(
        //mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: _GaugePainter(
              value: value,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classification.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
       
        ],
      ),
    );
  }
}

/// Painter customizado para desenhar o gauge
class _GaugePainter extends CustomPainter {
  final int value;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = math.min(size.width / 2, size.height) - 20;

    // Ângulos em radianos (semicírculo de 180°)
    const startAngle = math.pi; // 180° (esquerda)
    const sweepAngle = math.pi; // 180° (semicírculo)

    // Desenha o fundo do gauge (cinza claro)
    final backgroundPaint = Paint()
      ..color = const Color.fromARGB(255, 82, 107, 143).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Desenha as divisões de cores (Extreme Fear, Fear, Neutral, Greed, Extreme Greed)
    _drawColorSegments(canvas, center, radius);

    // Desenha o arco preenchido até o valor atual
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Calcula o ângulo proporcional ao valor (0-100 -> 0-180°)
    final valueAngle = (value / 100) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      valueAngle,
      false,
      valuePaint,
    );

    // Desenha o indicador (ponteiro)
    _drawNeedle(canvas, center, radius, value);

    // Desenha marcações de valores (0, 25, 50, 75, 100)
    _drawLabels(canvas, center, radius, size);
  }

  /// Desenha os segmentos de cores do gauge
  void _drawColorSegments(Canvas canvas, Offset center, double radius) {
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    const startAngle = math.pi;
    const segmentAngle = math.pi / 5; // Divide em 5 partes

    // Cores para cada segmento
    final colors = [
      const Color(0xFFC53030), // 0-20: Extreme Fear
      const Color(0xFFE53E3E), // 20-40: Fear
      const Color(0xFFFFB800), // 40-60: Neutral
      const Color(0xFF48BB78), // 60-80: Greed
      const Color(0xFF22C55E), // 80-100: Extreme Greed
    ];

    for (int i = 0; i < 5; i++) {
      segmentPaint.color = colors[i].withOpacity(0.4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 15),
        startAngle + (i * segmentAngle),
        segmentAngle,
        false,
        segmentPaint,
      );
    }
  }

  /// Desenha o ponteiro/agulha do gauge
  void _drawNeedle(Canvas canvas, Offset center, double radius, int value) {
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    
    // Calcula o ângulo do ponteiro
    final needleAngle = startAngle + (value / 100) * sweepAngle;
    
    // Ponto final do ponteiro
    final needleEnd = Offset(
      center.dx + (radius - 10) * math.cos(needleAngle),
      center.dy + (radius - 10) * math.sin(needleAngle),
    );

    // Desenha a linha do ponteiro
    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Desenha o círculo central
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, centerPaint);
  }

  /// Desenha as labels de valores (0, 25, 50, 75, 100)
  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    final textStyle = const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final labels = [
      {'value': '0', 'position': 0.0},
      {'value': '25', 'position': 0.25},
      {'value': '50', 'position': 0.5},
      {'value': '75', 'position': 0.75},
      {'value': '100', 'position': 1.0},
    ];

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    for (final label in labels) {
      final position = label['position'] as double;
      final text = label['value'] as String;
      
      final angle = startAngle + (position * sweepAngle);
      final labelRadius = radius + 35;
      
      final textSpan = TextSpan(
        text: text,
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final offset = Offset(
        center.dx + labelRadius * math.cos(angle) - (textPainter.width / 2),
        center.dy + labelRadius * math.sin(angle) - (textPainter.height / 2),
      );
      
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
