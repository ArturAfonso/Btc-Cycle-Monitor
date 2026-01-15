import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api/fear_greed_api.dart';
import '../../data/models/fear_greed_model.dart';

/// Estados possíveis para o Fear & Greed Index
abstract class FearGreedState {}

class FearGreedInitial extends FearGreedState {}

class FearGreedLoading extends FearGreedState {}

class FearGreedLoaded extends FearGreedState {
  final FearGreedModel data;
  final List<FearGreedModel> history;

  FearGreedLoaded(this.data, {this.history = const []});
}

class FearGreedError extends FearGreedState {
  final String message;

  FearGreedError(this.message);
}

/// Cubit para gerenciar o estado do Fear & Greed Index
class FearGreedCubit extends Cubit<FearGreedState> {
  final FearGreedApi api;

  FearGreedCubit({required this.api}) : super(FearGreedInitial());

  /// Carrega o índice atual
  Future<void> loadFearGreedIndex() async {
    emit(FearGreedLoading());

    try {
      final response = await api.getFearGreedIndex(limit: 1);
      
      if (response.latest != null) {
        emit(FearGreedLoaded(response.latest!));
      } else {
        emit(FearGreedError('Nenhum dado disponível'));
      }
    } catch (e) {
      emit(FearGreedError('Erro ao carregar índice: ${e.toString()}'));
    }
  }

  /// Carrega o histórico (últimos 30 dias por padrão)
  Future<void> loadFearGreedHistory({int days = 30}) async {
    emit(FearGreedLoading());

    try {
      final response = await api.getFearGreedHistory(days: days);
      
      if (response.data.isNotEmpty) {
        emit(FearGreedLoaded(
          response.data.first,
          history: response.data,
        ));
      } else {
        emit(FearGreedError('Nenhum dado histórico disponível'));
      }
    } catch (e) {
      emit(FearGreedError('Erro ao carregar histórico: ${e.toString()}'));
    }
  }

  /// Recarrega os dados
  Future<void> refresh() async {
    await loadFearGreedIndex();
  }
}
