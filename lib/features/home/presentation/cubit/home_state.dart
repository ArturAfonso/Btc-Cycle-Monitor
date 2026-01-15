import '../../domain/entities/home_data.dart';

/// Estados possíveis da tela Home
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final HomeData data;
  final bool isLoadingChart;

  HomeLoaded(this.data, {this.isLoadingChart = false});
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
