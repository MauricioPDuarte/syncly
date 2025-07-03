# Syncly

Sistema de sincronização independente e completo para aplicações Flutter com arquitetura moderna e flexível.

## Características

- ✅ **Sincronização bidirecional** (upload/download)
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
  
  // Inicializar o sync com SyncConfigurator
  await SyncConfigurator.initialize(
    provider: MeuSyncConfig(),
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
  Future<String?> getAuthToken() async {
    // Implementar recuperação do token
    return await SecureStorage.getToken();
  }
  
  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }
  
  @override
  Future<String?> getCurrentUserId() async {
    // Implementar recuperação do ID do usuário
    return await UserService.getCurrentUserId();
  }
  
  @override
  Future<Map<String, dynamic>?> getCurrentSession() async {
    // Implementar recuperação da sessão
    return await SessionService.getCurrentSession();
  }
  
  @override
  Future<void> onAuthenticationFailed() async {
    // Implementar ação quando autenticação falha
    await AuthService.logout();
    NavigationService.goToLogin();
  }
}
```

### Implementação de Notificações

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  Future<void> initializeNotifications() async {
    // Inicializar sistema de notificações
    await NotificationService.initialize();
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    return await NotificationService.areEnabled();
  }
  
  @override
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? notificationId,
  }) async {
    await NotificationService.show(
      title: title,
      message: message,
      channelId: channelId ?? 'sync_channel',
      id: notificationId ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  @override
  Future<void> showProgressNotification({
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    int? notificationId,
  }) async {
    await NotificationService.showProgress(
      title: title,
      message: message,
      progress: progress,
      maxProgress: maxProgress,
      id: notificationId ?? 1001,
    );
  }
}
```

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