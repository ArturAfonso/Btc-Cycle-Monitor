import 'package:flutter/material.dart';

import '../entities/home_data.dart';
import '../repositories/home_repository.dart';

/// Use case para obter dados da tela Home
/// Encapsula a lógica de negócio específica
class GetHomeDataUseCase {
  final HomeRepository repository;

  GetHomeDataUseCase(this.repository);

  Future<HomeData> call() async {
    debugPrint('🔄 [UseCase] Iniciando busca de dados da Home...');
    final homeData = await repository.getHomeData();
    debugPrint('✅ [UseCase] Dados da Home obtidos com sucesso');
    return homeData;
  }
}
