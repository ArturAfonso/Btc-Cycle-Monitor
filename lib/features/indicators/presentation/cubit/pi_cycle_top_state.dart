import 'package:equatable/equatable.dart';


abstract class PiCycleTopState extends Equatable {
  const PiCycleTopState();

  @override
  List<Object?> get props => [];
}


class PiCycleTopInitial extends PiCycleTopState {}


class PiCycleTopLoading extends PiCycleTopState {}


class PiCycleTopLoaded extends PiCycleTopState {
  final double? sma111;
  final double? sma350x2;
  final double? distance;
  final String status; 
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

  
  bool get isTop => status == 'top';

  
  bool get isApproaching => status == 'approaching';

  
  bool get isNormal => status == 'normal';

  
  bool get hasInsufficientData => status == 'insufficient_data';

  
  
  
  
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


class PiCycleTopError extends PiCycleTopState {
  final String message;

  const PiCycleTopError(this.message);

  @override
  List<Object?> get props => [message];
}
