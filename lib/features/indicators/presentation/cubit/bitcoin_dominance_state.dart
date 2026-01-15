/// Estados possíveis para a dominância do Bitcoin
abstract class BitcoinDominanceState {
  const BitcoinDominanceState();
}

/// Estado inicial
class BitcoinDominanceInitial extends BitcoinDominanceState {
  const BitcoinDominanceInitial();
}

/// Estado de carregamento
class BitcoinDominanceLoading extends BitcoinDominanceState {
  const BitcoinDominanceLoading();
}

/// Estado com dados carregados
class BitcoinDominanceLoaded extends BitcoinDominanceState {
  final double dominance;
  final String status;
  final String message;
  final double cycleProximity;

  const BitcoinDominanceLoaded({
    required this.dominance,
    required this.status,
    required this.message,
    required this.cycleProximity,
  });

  @override
  String toString() {
    return 'BitcoinDominanceLoaded(dominance: $dominance%, status: $status, cycleProximity: $cycleProximity%)';
  }
}

/// Estado de erro
class BitcoinDominanceError extends BitcoinDominanceState {
  final String message;

  const BitcoinDominanceError(this.message);

  @override
  String toString() => 'BitcoinDominanceError(message: $message)';
}