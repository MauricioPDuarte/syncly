# Syncly

Sistema de sincronização independente e completo para aplicações Flutter com arquitetura moderna e flexível.

## Características

- ✅ **Sincronização bidirecional** (upload/download)
- ✅ **Sincronização incremental** - baixa apenas dados modificados
- ✅ **Sincronização em background** com WorkManager
- ✅ **Sistema de tema independente** (SyncTheme)
- ✅ **Gerenciamento de conectividade** automático
- ✅ **Sistema de logs e debug** configurável
- ✅ **Widgets de UI prontos** (SyncIndicator, SyncDetailsBottomSheet)
- ✅ **Tratamento de erros robusto** com retry automático
- ✅ **Arquitetura baseada em estratégias** (Strategy Pattern)
- ✅ **Configuração centralizada** via SyncConfig
- ✅ **Injeção de dependência** com GetIt
- ✅ **Sistema de notificações** integrado
- ✅ **Modo offline** com fila de operações
- ✅ **Upload de arquivos** e mídia
- ✅ **Autenticação** integrada

## Instalação

### Como Pacote Local

```yaml
dependencies:
  syncly:
    path: ../path/to/syncly
```

### Como Dependência Git

```yaml
dependencies:
  syncly:
    git:
      url: https://github.com/seu-usuario/syncly.git
      ref: main
```

## Uso Básico

### 1. Implementar SyncConfig

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  String get appName => 'Meu App';
  
  @override
  String get appVersion => '1.0.0';
  
  @override
  bool get enableDebugLogs => true;
  
  @override
  Duration get syncInterval => Duration(minutes: 5);
  
  // Implementar métodos HTTP obrigatórios
  @override
  Future<SyncHttpResponse<T>> httpPost<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    // Implementar usando Dio, http ou outro cliente
    // Retornar SyncHttpResponse<T>
  }
  
  // Implementar autenticação
  @override
  Future<bool> isAuthenticated() async {
    // Verificar se usuário está autenticado
  }
  
  @override
  Future<String?> getAuthToken() async {
    // Retornar token de autenticação
  }
  
  // Implementar estratégias de download
  @override
  List<IDownloadStrategy> get downloadStrategies => [
    MinhaDownloadStrategy(),
  ];
  
  // Implementar limpeza de dados
  @override
  Future<void> clearLocalData() async {
    // Limpar dados locais antes da sincronização
  }
}
```

### 2. Inicializar o Sistema

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Opção 1: Inicializar usando estratégias definidas no SyncConfig
  await SyncInitializer.initialize(MeuSyncConfig());
  
  // Opção 2: Passar estratégias de download diretamente
  await SyncInitializer.initialize(
    MeuSyncConfig(),
    downloadStrategies: [
      MeuDownloader(),
      OutroDownloader(),
    ],
  );
  
  // Opção 3: Usar StrategyResolver para integração com DI (novo na v1.1.4)
  await SyncInitializer.initialize(
    MeuSyncConfig(),
    strategyResolver: () => [
      Modular.get<MeuDownloader>(),
      GetIt.instance.get<OutroDownloader>(),
    ],
  );
  
  runApp(MeuApp());
}
```

### 3. Usar os Widgets

```dart
class MinhaTela extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu App'),
        actions: [
          SyncIndicator(
            onTap: () => SyncDetailsBottomSheet.show(context),
          ),
        ],
      ),
      body: MeuConteudo(),
    );
  }
}
```

### 4. Controlar Sincronização

```dart
// Forçar sincronização
await SyncConfigurator.syncService.forceSync();

// Verificar status
final syncData = SyncConfigurator.syncService.syncData.value;
print('Status: ${syncData.status}');
print('Itens pendentes: ${syncData.pendingItemsCount}');
print('Online: ${syncData.isOnline}');

// Escutar mudanças de status
SyncConfigurator.syncService.syncData.addListener(() {
  final data = SyncConfigurator.syncService.syncData.value;
  print('Status mudou para: ${data.status}');
});

// Adicionar operações à fila de sincronização
await SyncConfigurator.syncService.addToSyncQueue(
  SyncData(
    id: 'unique-id',
    entityType: 'todo',
    entityId: 'todo-123',
    operation: SyncOperation.create,
    data: {'title': 'Nova tarefa', 'completed': false},
  ),
);

// Parar/iniciar sincronização
await SyncConfigurator.syncService.stopSync();
await SyncConfigurator.syncService.startSync();

// Resetar estado de sincronização
await SyncConfigurator.syncService.resetSyncState();
```

## Configuração Avançada

### Sincronização Incremental

**🚀 Nova Funcionalidade**: Sincronização incremental para otimizar performance!

Em vez de apagar todos os dados e baixar tudo novamente, o Syncly agora pode:
- ✅ Baixar apenas dados novos e modificados
- ✅ Remover apenas dados específicos que foram excluídos
- ✅ Usar timestamps para determinar o que sincronizar
- ✅ Fallback automático para sincronização completa quando necessário

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get useIncrementalSync => true;
  
  @override
  Duration get maxIncrementalSyncInterval => const Duration(days: 7);
  
  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    // Implementar persistência do timestamp
  }
  
  @override
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    // Salvar timestamp da última sincronização
  }
  
  @override
  Future<void> clearSpecificData({
    required String entityType,
    required List<String> entityIds,
  }) async {
    // Remover dados específicos que foram excluídos no servidor
  }
}
```

**📖 Guia Completo**: Veja [INCREMENTAL_SYNC_GUIDE.md](INCREMENTAL_SYNC_GUIDE.md) para implementação detalhada.

### Tema Personalizado

```dart
final meuTema = SyncTheme(
  primary: Colors.blue,
  secondary: Colors.green,
  accent: Colors.orange,
  success: Colors.green,
  error: Colors.red,
  warning: Colors.amber,
  info: Colors.blue,
  surface: Colors.white,
  background: Colors.grey[50]!,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.black87,
  onBackground: Colors.black87,
);

class MeuSyncConfig extends SyncConfig {
  @override
  SyncTheme? get theme => meuTema;
}
```

### Configuração de Endpoints

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  String get baseUrl => 'https://api.meuapp.com';
  
  @override
  String get dataSyncEndpoint => '/api/sync/data';
  
  @override
  String get fileSyncEndpoint => '/api/sync/files';
  
  @override
  String get errorReportingEndpoint => '/api/sync/errors';
  
  @override
  SyncErrorReportConfig get errorReportConfig => SyncErrorReportConfig(
    endpoint: errorReportingEndpoint,
    maxRetries: 3,
    retryDelay: Duration(seconds: 5),
    batchSize: 10,
  );
}
```

### Configurações de Tempo e Comportamento

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableDebugLogs => true;
  
  @override
  bool get enableBackgroundSync => true;
  
  @override
  bool get enableNotifications => true;
  
  @override
  Duration get syncInterval => Duration(minutes: 5);
  
  @override
  Duration get backgroundSyncInterval => Duration(minutes: 15);
  
  @override
  int get maxRetryAttempts => 3;
  
  @override
  Duration get networkTimeout => Duration(seconds: 30);
  
  @override
  int get maxDataBatchSize => 20;
  
  @override
  int get maxFileBatchSize => 5;
}
```

### Implementação Completa de Autenticação

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }


  
  @override
  Future<String?> getCurrentUserId() async {
    // Implementar recuperação do ID do usuário
    return await UserService.getCurrentUserId();
  }
  

}
```

### Sistema de Notificações Simplificado

**🎉 Novidade na v0.1.0**: O sistema de notificações agora é **totalmente gerenciado internamente** pelo Syncly!

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableNotifications => true; // Só isso é necessário!
  
  // ✅ Não é mais necessário implementar:
  // - initializeNotifications()
  // - showNotification()
  // - showProgressNotification()
  // - cancelNotification()
  // - cancelAllNotifications()
  // - areNotificationsEnabled()
}
```

**Benefícios do novo sistema:**
- ✅ **Menos código**: Apenas uma propriedade para habilitar
- ✅ **Manutenção automática**: Notificações gerenciadas internamente
- ✅ **Logs de desenvolvimento**: Sistema de debug integrado
- ✅ **Compatibilidade**: Funciona imediatamente sem configuração adicional

**Migração da v0.0.x para v0.1.0:**
```dart
// ❌ Antes (v0.0.x) - muito código boilerplate
class MeuSyncConfig extends SyncConfig {
  @override
  Future<void> initializeNotifications() async {
    await NotificationService.initialize();
  }
  
  @override
  Future<void> showNotification({...}) async {
    // Implementação manual...
  }
  // ... mais métodos obrigatórios
}

// ✅ Agora (v0.1.0) - simples e direto
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableNotifications => true;
}
```

### Estratégias de Download Flexíveis

**🎉 Novidade na v0.1.0**: Agora você pode passar as estratégias de download diretamente no método `initialize()`!

#### Opção 1: Definir no SyncConfig (padrão)

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  List<IDownloadStrategy> get downloadStrategies => [
    TodoDownloader(),
    UserDownloader(),
    FileDownloader(),
  ];
}

// Inicializar
await SyncInitializer.initialize(MeuSyncConfig());
```

#### Opção 2: Passar diretamente no initialize()

```dart
// Estratégias passadas diretamente - mais flexível!
await SyncInitializer.initialize(
  MeuSyncConfig(),
  downloadStrategies: [
    TodoDownloader(),
    UserDownloader(),
    FileDownloader(),
  ],
);
```

#### Opção 3: Integração com Sistemas de DI (novo na v1.1.4)

**🎉 Novidade**: Agora você pode integrar perfeitamente com sistemas de injeção de dependência como Modular, GetIt, etc.!

```dart
// Com Flutter Modular
await SyncInitializer.initialize(
  MeuSyncConfig(),
  strategyResolver: () => [
    Modular.get<TodoDownloader>(),
    Modular.get<UserDownloader>(),
  ],
);

// Com GetIt
await SyncInitializer.initialize(
  MeuSyncConfig(),
  strategyResolver: () => [
    GetIt.instance.get<TodoDownloader>(),
    GetIt.instance.get<UserDownloader>(),
  ],
);

// Misto - diferentes sistemas de DI
await SyncInitializer.initialize(
  MeuSyncConfig(),
  strategyResolver: () => [
    Modular.get<TodoDownloader>(),
    GetIt.instance.get<UserDownloader>(),
    ServiceLocator.get<FileDownloader>(),
  ],
);
```

**Benefícios do StrategyResolver:**
- ✅ **Lazy Loading**: Estratégias resolvidas apenas quando necessário
- ✅ **Flexibilidade**: Funciona com qualquer sistema de DI
- ✅ **Ordem de Inicialização**: Resolve problemas de dependências não registradas
- ✅ **Compatibilidade**: Mantém suporte às opções anteriores

**Quando usar cada opção:**
 - **Opção 1**: Para projetos simples sem DI complexo
 - **Opção 2**: Para controle manual das instâncias
 - **Opção 3**: Para projetos com sistemas de DI estabelecidos

**Benefícios da nova abordagem:**
 - ✅ **Flexibilidade**: Diferentes estratégias para diferentes contextos
- ✅ **Testabilidade**: Fácil de mockar estratégias em testes
- ✅ **Modularidade**: Estratégias podem ser definidas em módulos separados
- ✅ **Compatibilidade**: Funciona com a abordagem anterior

**Quando usar cada opção:**
- **SyncConfig**: Quando as estratégias são fixas para toda a aplicação
- **initialize()**: Quando você precisa de flexibilidade ou estratégias dinâmicas

## Arquitetura

O Syncly utiliza uma arquitetura moderna baseada em camadas com injeção de dependência:

```
┌─────────────────────────────────────────────────────────────┐
│                        APP LAYER                           │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   SyncConfig    │    │  UI Widgets     │                │
│  │ (User Implementation) │ (SyncIndicator) │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                    CONFIGURATION LAYER                     │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │SyncConfigurator │    │ SyncInitializer │                │
│  │ (Central Config)│    │ (Initialization)│                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                         │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   SyncService   │    │ Background Sync │                │
│  │ (Main Logic)    │    │    Service      │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                     STRATEGY LAYER                         │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Upload Strategy │    │Download Strategy│                │
│  │ (Queue & Retry) │    │ (Data Fetching) │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│                      CORE LAYER                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ Connectivity    │  │ Error Manager   │  │ Log Manager │ │
│  │ Service         │  │ & Reporter      │  │ & Storage   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Principais Componentes

- **SyncConfig**: Interface que o usuário implementa com todas as configurações
- **SyncConfigurator**: Gerencia a configuração central e injeção de dependência
- **SyncService**: Lógica principal de sincronização com controle de estado
- **Strategies**: Padrão Strategy para upload/download personalizáveis
- **Core Services**: Serviços internos (conectividade, logs, erros, storage)
- **UI Components**: Widgets prontos para uso (indicadores, detalhes, etc.)

## Dependências

O Syncly utiliza as seguintes dependências principais:

- **`flutter`**: SDK Flutter (>=3.10.0)
- **`dio`** (^5.8.0+1): Cliente HTTP robusto para requisições de rede
- **`get_it`** (^8.0.3): Injeção de dependência e service locator
- **`workmanager`** (^0.8.0): Execução de tarefas em background
- **`shared_preferences`** (^2.5.3): Armazenamento local de configurações
- **`uuid`** (^4.5.1): Geração de identificadores únicos

### Dependências de Desenvolvimento

- **`flutter_test`**: Framework de testes do Flutter
- **`flutter_lints`** (^6.0.0): Regras de linting recomendadas

### Compatibilidade

- **Dart SDK**: >=3.0.0 <4.0.0
- **Flutter**: >=3.10.0
- **Plataformas**: Android, iOS, Web, Desktop

## Licença

MIT License - veja o arquivo LICENSE para detalhes.