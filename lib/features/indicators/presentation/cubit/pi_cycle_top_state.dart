import 'package:equatable/equatable.dart';

/// Estados do Pi Cycle Top Indicator
abstract class PiCycleTopState extends Equatable {
  const PiCycleTopState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PiCycleTopInitial extends PiCycleTopState {}

/// Estado de carregamento
class PiCycleTopLoading extends PiCycleTopState {}

/// Estado de sucesso com dados carregados
class PiCycleTopLoaded extends PiCycleTopState {
  final double? sma111;
  final double? sma350x2;
  final double? distance;
  final String status; // 'top', 'approaching', 'normal', 'insufficient_data'
  final String message;

  const PiCycleTopLoaded({
    required this.sma111,
    required this.sma350x2,
    required this.distance,
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [sma111, sma350x2, distance, status, message];

  /// Retorna true se estiver em sinal de topo
  bool get isTop => status == 'top';

  /// Retorna true se estiver se aproximando do topo
  bool get isApproaching => status == 'approaching';

  /// Retorna true se estiver em situação normal
  bool get isNormal => status == 'normal';

  /// Retorna true se não houver dados suficientes
  bool get hasInsufficientData => status == 'insufficient_data';

  /// Cor do status baseado no estado
  /// - top: vermelho (perigo)
  /// - approaching: amarelo (atenção)
  /// - normal: verde (seguro)
  String get statusColor {
    switch (status) {
      case 'top':
        return '#FF0000';
      case 'approaching':
        return '#FFA500';
      case 'normal':
        return '#00FF00';
      default:
        return '#808080';
    }
  }

  /// Ícone emoji do status
  String get statusEmoji {
    switch (status) {
      case 'top':
        return '🔴';
      case 'approaching':
        return '⚠️';
      case 'normal':
        return '✅';
      default:
        return 'ℹ️';
    }
  }
}

/// Estado de erro
class PiCycleTopError extends PiCycleTopState {
  final String message;

  const PiCycleTopError(this.message);

  @override
  List<Object?> get props => [message];
}
