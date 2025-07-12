# Syncly

Sistema de sincronização independente e completo para aplicações Flutter com arquitetura moderna e flexível.

## Características

- ✅ **Sincronização bidirecional** (upload/download)
- ✅ **Sincronização incremental** - baixa apenas dados modificados
- ✅ **Sincronização em background** com WorkManager (ativada por padrão)
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
      url: https://github.com/MauricioPDuarte/syncly.git
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
  
  // Inicializar o sistema de sincronização
  await SyncInitializer.initialize(MeuSyncConfig());
  
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
  bool get enableBackgroundSync => true; // Ativada por padrão - pode ser desabilitada
  
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


  


}
```

### Sistema de Notificações Simplificado

**🎉 Novidade na v1.1.4**: O sistema de notificações agora usa **notificações reais do sistema** com `flutter_local_notifications`!

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableNotifications => true; // Ativa notificações reais!
  
  // ✅ Notificações reais incluem:
  // - Notificações de status da sincronização
  // - Notificações de progresso com barra visual
  // - Notificações de erro com alta prioridade
  // - Notificações de conectividade
  // - Canais organizados por categoria
  
  // ✅ Não é necessário implementar nada:
  // O Syncly gerencia tudo automaticamente!
}
```

**Benefícios do novo sistema:**
- ✅ **Menos código**: Apenas uma propriedade para habilitar
- ✅ **Manutenção automática**: Notificações gerenciadas internamente
- ✅ **Logs de desenvolvimento**: Sistema de debug integrado
- ✅ **Compatibilidade**: Funciona imediatamente sem configuração adicional
- ✅ **Permissões automáticas**: Verificação e solicitação automática de permissões

#### 🔐 Configuração de Permissões

O Syncly verifica automaticamente as permissões de notificação durante a inicialização:

```dart
// Verificação automática durante a inicialização
await SyncInitializer.initialize(meuSyncConfig);

// Verificação manual (opcional)
bool hasPermission = await SyncInitializer.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await SyncInitializer.requestNotificationPermission();
}
```

#### 📱 Configurações Nativas Necessárias

**Para Android:**

1. **Android 13+ (API 33+)** - Adicione no `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

2. **Todas as versões** - Configure o ícone de notificação em `android/app/src/main/res/drawable/`:
```xml
<!-- ic_notification.xml -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnPrimary">
  <path
      android:fillColor="@android:color/white"
      android:pathData="M12,2C6.48,2 2,6.48 2,12s4.48,10 10,10 10,-4.48 10,-10S17.52,2 12,2z"/>
</vector>
```

**Para iOS:**

1. **Adicione no `ios/Runner/Info.plist`:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

2. **Configure as permissões de notificação:**
```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>
```

📚 **Para configuração completa de permissões e solução de problemas, consulte o [Guia de Permissões de Notificação](NOTIFICATION_PERMISSIONS_GUIDE.md)**

### Sincronização em Background

**🔄 A sincronização em background vem ativada por padrão** e funciona automaticamente usando o WorkManager.

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableBackgroundSync => true; // ✅ Ativada por padrão
  
  @override
  Duration get backgroundSyncInterval => Duration(minutes: 15); // Intervalo padrão
}
```

**Características:**
- ✅ **Ativada automaticamente**: Não requer configuração adicional
- ✅ **Execução inteligente**: Só executa quando há dados para sincronizar
- ✅ **Respeita conectividade**: Aguarda conexão de rede disponível
- ✅ **Notificações de progresso**: Informa o usuário sobre o status
- ✅ **Controle pelo usuário**: Pode ser desabilitada nas configurações do app

**Como desabilitar (se necessário):**
```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableBackgroundSync => false; // Desabilita completamente
}
```

**Controle programático:**
```dart
// Parar temporariamente
await SyncConfigurator.syncService.stopBackgroundSync();

// Reiniciar
await SyncConfigurator.syncService.startBackgroundSync();

// Verificar status
bool isActive = await SyncConfigurator.syncService.isBackgroundSyncActive();

// Executar imediatamente
await SyncConfigurator.syncService.triggerImmediateBackgroundSync();
```

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

### Estratégias de Download

As estratégias de download são definidas diretamente no `SyncConfig` através da propriedade `downloadStrategies`:

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

**Benefícios desta abordagem:**
- ✅ **Simplicidade**: Configuração centralizada em um só lugar
- ✅ **Consistência**: Todas as configurações ficam no SyncConfig
- ✅ **Testabilidade**: Fácil de mockar estratégias em testes
- ✅ **Modularidade**: Estratégias podem ser organizadas por módulos
- ✅ **Manutenibilidade**: Menos pontos de configuração para gerenciar

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