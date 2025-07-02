# Syncly

Sistema de sincronização independente para aplicações Flutter.

## Características

- ✅ **Sincronização bidirecional** (upload/download)
- ✅ **Sincronização em background** com WorkManager
- ✅ **Sistema de tema independente**
- ✅ **Gerenciamento de conectividade**
- ✅ **Sistema de logs e debug**
- ✅ **Widgets de UI prontos**
- ✅ **Tratamento de erros robusto**
- ✅ **Arquitetura desacoplada**

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

### 1. Implementar SyncProvider

```dart
class MeuSyncProvider extends SyncProvider {
  @override
  String get appName => 'Meu App';
  
  @override
  String get appVersion => '1.0.0';
  
  @override
  String? get baseUrl => 'https://api.meuapp.com';
  
  @override
  Future<SyncHttpResponse> httpPost(String url, Map<String, dynamic> data) async {
    // Implementar chamada HTTP
  }
  
  @override
  List<IDownloadStrategy> get downloadStrategies => [
    MinhaDownloadStrategy(),
  ];
}
```

### 2. Inicializar o Sistema

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o sync
  await SyncInitializer.initialize(
    provider: MeuSyncProvider(),
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

// Escutar mudanças
SyncConfigurator.syncService.syncData.addListener(() {
  print('Status mudou!');
});
```

## Configuração Avançada

### Tema Personalizado

```dart
final meuTema = SyncTheme(
  primary: Colors.blue,
  success: Colors.green,
  error: Colors.red,
  warning: Colors.orange,
  // ... outras configurações
);

class MeuSyncProvider extends SyncProvider {
  @override
  SyncTheme? get theme => meuTema;
}
```

### Configurações de Debug

```dart
class MeuSyncProvider extends SyncProvider {
  @override
  bool get enableDebugLogs => true;
  
  @override
  bool get enableBackgroundSync => true;
  
  @override
  Duration get syncInterval => Duration(minutes: 15);
}
```

## Arquitetura

```
┌─────────────────┐
│   SyncProvider  │ ← Implementação do usuário
└─────────────────┘
         │
┌─────────────────┐
│ SyncConfigurator│ ← Configuração central
└─────────────────┘
         │
┌─────────────────┐
│   SyncService   │ ← Lógica principal
└─────────────────┘
         │
┌─────────────────┐
│   Strategies    │ ← Upload/Download
└─────────────────┘
```

## Dependências

- `flutter`: SDK Flutter
- `dio`: Cliente HTTP
- `get_it`: Injeção de dependência
- `workmanager`: Tarefas em background
- `shared_preferences`: Armazenamento local
- `uuid`: Geração de IDs únicos

## Licença

MIT License - veja o arquivo LICENSE para detalhes.