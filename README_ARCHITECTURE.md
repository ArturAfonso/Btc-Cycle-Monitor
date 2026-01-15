# BTC Cycle Monitor

## Estrutura do Projeto - Clean Architecture

Este projeto segue os princípios da **Clean Architecture**, organizando o código em camadas bem definidas e independentes.

### Estrutura de Pastas

```
lib/
├── core/                          # Recursos compartilhados
│   ├── constants/                 # Constantes da aplicação
│   │   └── app_constants.dart     # Cores, tamanhos, etc.
│   ├── error/                     # Classes de erro
│   │   └── failures.dart          # Tipos de falhas
│   └── theme/                     # Temas da aplicação
│       └── app_theme.dart         # Temas claro e escuro
│
├── features/                      # Features da aplicação
│   └── home/                      # Feature Home
│       ├── data/                  # Data Layer
│       │   ├── datasources/       # Fontes de dados
│       │   │   ├── home_local_datasource.dart    # Cache local
│       │   │   └── home_remote_datasource.dart   # API/Remoto
│       │   ├── models/            # Models para serialização
│       │   │   └── home_data_model.dart
│       │   └── repositories/      # Implementação dos repositórios
│       │       └── home_repository_impl.dart
│       │
│       ├── domain/                # Domain Layer (Business Logic)
│       │   ├── entities/          # Entidades de negócio
│       │   │   └── home_data.dart
│       │   ├── repositories/      # Interfaces dos repositórios
│       │   │   └── home_repository.dart
│       │   └── usecases/          # Casos de uso
│       │       ├── get_home_data.dart
│       │       └── refresh_home_data.dart
│       │
│       └── presentation/          # Presentation Layer (UI)
│           ├── cubit/             # State Management (Cubit)
│           │   ├── home_cubit.dart
│           │   └── home_state.dart
│           ├── pages/             # Páginas/Telas
│           │   └── home_page.dart
│           └── widgets/           # Widgets reutilizáveis
│               ├── home_content.dart
│               ├── home_error.dart
│               ├── home_header.dart
│               └── home_loading.dart
│
└── main.dart                      # Ponto de entrada da aplicação
```

## Camadas da Clean Architecture

### 1. **Domain Layer** (Domínio)
- **Entities**: Classes que representam os objetos de negócio
- **Repositories**: Interfaces que definem contratos para acesso a dados
- **Use Cases**: Lógica de negócio específica da aplicação

### 2. **Data Layer** (Dados)
- **Models**: Extensões das entities para serialização/deserialização
- **DataSources**: Fontes de dados (local, remoto, cache)
- **Repository Implementations**: Implementações concretas dos repositórios

### 3. **Presentation Layer** (Apresentação)
- **Pages**: Telas da aplicação
- **Widgets**: Componentes reutilizáveis da UI
- **Cubit/Bloc**: Gerenciamento de estado
- **States**: Estados possíveis da aplicação

### 4. **Core** (Núcleo)
- **Constants**: Constantes compartilhadas
- **Themes**: Temas e estilos visuais
- **Errors**: Classes de erro padronizadas

## Dependências de Camadas

```
Presentation ──> Domain ──> Data
     │              │         │
     └──────────────┴─────────┴──> Core
```

- **Presentation** conhece **Domain** e **Core**
- **Domain** conhece apenas **Core**
- **Data** conhece **Domain** e **Core**

## Benefícios desta Arquitetura

1. **Separação de Responsabilidades**: Cada camada tem uma responsabilidade específica
2. **Testabilidade**: Facilita a criação de testes unitários
3. **Manutenibilidade**: Código organizado e fácil de manter
4. **Escalabilidade**: Fácil adicionar novas features
5. **Independência**: Camadas independentes permitem mudanças sem afetar outras

## Próximos Passos

Para adicionar novas features:

1. Crie uma nova pasta em `features/`
2. Replique a estrutura de pastas da feature `home`
3. Implemente as camadas de baixo para cima: Domain → Data → Presentation
4. Adicione a nova feature no `main.dart` com injeção de dependência

## Padrões Utilizados

- **Clean Architecture**
- **Repository Pattern**
- **Use Case Pattern**
- **Cubit Pattern** (para gerenciamento de estado)
- **Dependency Injection** (manual por enquanto)

## Estado Management

Utilizamos **Cubit** (do pacote flutter_bloc) para gerenciar o estado da aplicação:

- Estados bem definidos (Initial, Loading, Loaded, Error)
- Separação clara entre lógica de negócio e UI
- Facilita testing e debugging