# Como Adicionar Novas Features

## Estrutura para Nova Feature

Para adicionar uma nova feature (ex: `portfolio`), siga esta estrutura:

```
lib/features/portfolio/
├── data/
│   ├── datasources/
│   │   ├── portfolio_local_datasource.dart
│   │   └── portfolio_remote_datasource.dart
│   ├── models/
│   │   └── portfolio_model.dart
│   └── repositories/
│       └── portfolio_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── portfolio.dart
│   ├── repositories/
│   │   └── portfolio_repository.dart
│   └── usecases/
│       ├── get_portfolio.dart
│       └── update_portfolio.dart
└── presentation/
    ├── cubit/
    │   ├── portfolio_cubit.dart
    │   └── portfolio_state.dart
    ├── pages/
    │   └── portfolio_page.dart
    └── widgets/
        ├── portfolio_chart.dart
        └── portfolio_summary.dart
```

## Passos para Implementação

### 1. Domain Layer (Primeiro)

**1.1. Criar Entity:**
```dart
// lib/features/portfolio/domain/entities/portfolio.dart
class Portfolio {
  final String id;
  final double totalValue;
  final List<Asset> assets;
  
  const Portfolio({
    required this.id,
    required this.totalValue,
    required this.assets,
  });
}
```

**1.2. Criar Repository Interface:**
```dart
// lib/features/portfolio/domain/repositories/portfolio_repository.dart
abstract class PortfolioRepository {
  Future<Portfolio> getPortfolio();
  Future<void> updatePortfolio(Portfolio portfolio);
}
```

**1.3. Criar Use Cases:**
```dart
// lib/features/portfolio/domain/usecases/get_portfolio.dart
class GetPortfolioUseCase {
  final PortfolioRepository repository;
  
  GetPortfolioUseCase(this.repository);
  
  Future<Portfolio> call() => repository.getPortfolio();
}
```

### 2. Data Layer (Segundo)

**2.1. Criar Model:**
```dart
// lib/features/portfolio/data/models/portfolio_model.dart
class PortfolioModel extends Portfolio {
  const PortfolioModel({
    required super.id,
    required super.totalValue,
    required super.assets,
  });
  
  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    // Implementar serialização
  }
}
```

**2.2. Criar DataSources:**
```dart
// lib/features/portfolio/data/datasources/portfolio_remote_datasource.dart
abstract class PortfolioRemoteDataSource {
  Future<PortfolioModel> getPortfolio();
}

class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  @override
  Future<PortfolioModel> getPortfolio() async {
    // Implementar chamada de API
  }
}
```

**2.3. Implementar Repository:**
```dart
// lib/features/portfolio/data/repositories/portfolio_repository_impl.dart
class PortfolioRepositoryImpl implements PortfolioRepository {
  final PortfolioRemoteDataSource remoteDataSource;
  final PortfolioLocalDataSource localDataSource;
  
  PortfolioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Portfolio> getPortfolio() async {
    // Implementar lógica de cache/fallback
  }
}
```

### 3. Presentation Layer (Terceiro)

**3.1. Criar States:**
```dart
// lib/features/portfolio/presentation/cubit/portfolio_state.dart
abstract class PortfolioState {}

class PortfolioInitial extends PortfolioState {}
class PortfolioLoading extends PortfolioState {}
class PortfolioLoaded extends PortfolioState {
  final Portfolio portfolio;
  PortfolioLoaded(this.portfolio);
}
class PortfolioError extends PortfolioState {
  final String message;
  PortfolioError(this.message);
}
```

**3.2. Criar Cubit:**
```dart
// lib/features/portfolio/presentation/cubit/portfolio_cubit.dart
class PortfolioCubit extends Cubit<PortfolioState> {
  final GetPortfolioUseCase getPortfolioUseCase;
  
  PortfolioCubit({required this.getPortfolioUseCase}) : super(PortfolioInitial());
  
  Future<void> loadPortfolio() async {
    emit(PortfolioLoading());
    try {
      final portfolio = await getPortfolioUseCase();
      emit(PortfolioLoaded(portfolio));
    } catch (e) {
      emit(PortfolioError(e.toString()));
    }
  }
}
```

**3.3. Criar Page:**
```dart
// lib/features/portfolio/presentation/pages/portfolio_page.dart
class PortfolioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioCubit, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return LoadingWidget();
        } else if (state is PortfolioLoaded) {
          return PortfolioContent(portfolio: state.portfolio);
        } else if (state is PortfolioError) {
          return ErrorWidget(message: state.message);
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

### 4. Integração no Main

**4.1. Atualizar main.dart:**
```dart
// Adicionar injeção de dependência
final portfolioRemoteDataSource = PortfolioRemoteDataSourceImpl();
final portfolioLocalDataSource = PortfolioLocalDataSourceImpl();
final portfolioRepository = PortfolioRepositoryImpl(
  remoteDataSource: portfolioRemoteDataSource,
  localDataSource: portfolioLocalDataSource,
);
final getPortfolioUseCase = GetPortfolioUseCase(portfolioRepository);

// Adicionar no MultiBlocProvider se necessário
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => HomeCubit(
        getHomeDataUseCase: getHomeDataUseCase,
        refreshHomeDataUseCase: refreshHomeDataUseCase,
      ),
    ),
    BlocProvider(
      create: (context) => PortfolioCubit(
        getPortfolioUseCase: getPortfolioUseCase,
      ),
    ),
  ],
  child: MyApp(),
)
```

## Benefícios desta Abordagem

1. **Separação Clara**: Cada camada tem responsabilidades específicas
2. **Testabilidade**: Fácil criar testes unitários para cada camada
3. **Reutilização**: Use cases podem ser reutilizados em diferentes telas
4. **Manutenibilidade**: Mudanças em uma camada não afetam outras
5. **Escalabilidade**: Fácil adicionar novas funcionalidades

## Próximas Features Sugeridas

- `portfolio` - Gestão de carteira de investimentos
- `analytics` - Análise técnica avançada
- `notifications` - Sistema de alertas
- `settings` - Configurações do usuário
- `auth` - Sistema de autenticação

Cada feature deve seguir esta mesma estrutura para manter a consistência do projeto.