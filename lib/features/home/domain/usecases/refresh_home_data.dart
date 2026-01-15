import '../repositories/home_repository.dart';

/// Use case para atualizar dados da tela Home
class RefreshHomeDataUseCase {
  final HomeRepository repository;

  RefreshHomeDataUseCase(this.repository);

  Future<void> call() async {
    return await repository.refreshHomeData();
  }
}
