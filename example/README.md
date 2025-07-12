# Syncly Todo Example

Este é um exemplo completo de como usar a biblioteca Syncly em um projeto Flutter com arquitetura modular e Clean Architecture.

## Características

- ✅ **Arquitetura Modular**: Usando flutter_modular para injeção de dependência e navegação
- ✅ **Clean Architecture**: Separação clara entre domínio, dados e apresentação
- ✅ **Offline First**: Funciona completamente offline usando SharedPreferences
- ✅ **Sincronização**: Integração com Syncly para sincronização automática
- ✅ **Sincronização Incremental**: Baixa apenas dados modificados para melhor performance
- ✅ **ValueNotifier**: Gerenciamento de estado reativo
- ✅ **Material Design 3**: Interface moderna e responsiva

## Estrutura do Projeto

```
lib/
├── core/                          # Módulo principal com serviços compartilhados
│   ├── core_module.dart          # Configuração de dependências globais
│   └── services/
│       ├── shared_preferences_service.dart  # Serviço de persistência local
│       └── sync_service.dart     # Integração com Syncly
├── modules/
│   └── todo/                     # Módulo de todos
│       ├── data/                 # Camada de dados
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/               # Camada de domínio
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── presentation/         # Camada de apresentação
│       │   ├── controllers/
│       │   ├── pages/
│       │   └── widgets/
│       └── todo_module.dart      # Configuração do módulo
├── app_module.dart               # Módulo principal da aplicação
├── app_widget.dart               # Widget principal
└── main.dart                     # Ponto de entrada
```

## Como Executar

1. **Instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Executar a aplicação**:
   ```bash
   flutter run
   ```

## Funcionalidades

### Todo App
- Criar novos todos
- Marcar como concluído/pendente
- Excluir todos
- Visualizar estatísticas
- Sincronização automática (quando configurada)

### Integração com Syncly

O exemplo demonstra como:

1. **Configurar o Syncly com Sincronização Incremental**:
   ```dart
   class SynclyConfig extends SyncConfig {
     @override
     bool get useIncrementalSync => true;
     
     @override
     Duration get maxIncrementalSyncInterval => const Duration(days: 3);
     
     @override
     Duration get syncInterval => const Duration(minutes: 5);
   }
   ```

2. **Implementar Download Strategy com Suporte Incremental**:
   ```dart
   class TodoDownloader implements IDownloadStrategy {
     @override
     Future<DownloadResult> downloadData({DateTime? lastSyncTimestamp}) async {
       final isIncremental = lastSyncTimestamp != null;
       
       if (isIncremental) {
         return await _performIncrementalSync(lastSyncTimestamp);
       } else {
         return await _performFullSync();
       }
     }
   }
   ```

3. **Gerenciar Timestamps de Sincronização**:
   ```dart
   @override
   Future<DateTime?> getLastSyncTimestamp() async {
     final prefs = await SharedPreferences.getInstance();
     final timestamp = prefs.getString('last_sync_timestamp');
     return timestamp != null ? DateTime.parse(timestamp) : null;
   }
   ```



### Sincronização Incremental

Este exemplo implementa sincronização incremental completa:

- **Performance Otimizada**: Baixa apenas dados modificados desde a última sincronização
- **Economia de Dados**: Reduz significativamente o tráfego de rede
- **Processamento de Exclusões**: Remove automaticamente dados excluídos no servidor
- **Fallback Inteligente**: Volta para sincronização completa quando necessário

📖 **Para detalhes completos, consulte**: [INCREMENTAL_SYNC_EXAMPLE.md](INCREMENTAL_SYNC_EXAMPLE.md)

### Permissões de Notificação

O exemplo demonstra como gerenciar permissões de notificação:

1. **Configuração Automática**:
   ```dart
   class SynclyConfig extends SyncConfig {
     @override
     bool get enableNotifications => true; // Permissões verificadas automaticamente
   }
   ```

2. **Verificação Manual de Permissões**:
   ```dart
   // Verificar se as permissões estão concedidas
   bool hasPermission = await SyncInitializer.checkNotificationPermission();
   
   if (!hasPermission) {
     // Solicitar permissão manualmente
     bool granted = await SyncInitializer.requestNotificationPermission();
     
     if (granted) {
       print('Permissão concedida - notificações habilitadas');
     } else {
       print('Permissão negada - funcionalidade limitada');
     }
   }
   ```

3. **Tratamento de Estados de Permissão**:
   ```dart
   Future<void> handleNotificationSetup() async {
     // O Syncly verifica automaticamente durante a inicialização
     await SyncInitializer.initialize(syncConfig);
     
     // Verificação adicional se necessário
     bool hasPermission = await SyncInitializer.checkNotificationPermission();
     
     if (!hasPermission) {
       // Mostrar dialog explicativo antes de solicitar
       await showNotificationPermissionDialog();
       
       // Solicitar permissão
       bool granted = await SyncInitializer.requestNotificationPermission();
       
       if (!granted) {
         // Orientar usuário para configurações manuais
         await showManualPermissionInstructions();
       }
     }
   }
   ```

**Configurações Nativas Necessárias:**
- **Android 13+**: Adicionar `POST_NOTIFICATIONS` no AndroidManifest.xml
- **iOS**: Configurar background modes no Info.plist

📖 **Para configuração completa, consulte**: [NOTIFICATION_PERMISSIONS_GUIDE.md](../NOTIFICATION_PERMISSIONS_GUIDE.md)

## Configuração da API

Para habilitar a sincronização com um servidor, você precisa:

1. **Configurar a URL da API** no `SynclyConfig`:
   ```dart
   @override
   String get baseUrl => 'https://sua-api.com'; // Substitua pela sua URL
   ```

2. **Implementar os endpoints da API** para sincronização incremental:
   
   **Sincronização Completa:**
   - `GET /api/todos/all` - Retorna todos os dados
   
   **Sincronização Incremental:**
   - `GET /api/todos/incremental?since=2024-01-15T10:30:00Z` - Retorna apenas dados modificados
   
   **Formato de resposta incremental:**
   ```json
   {
     "data": {
       "created": [...],    // Novos todos
       "updated": [...],    // Todos atualizados
       "deleted": ["id1", "id2"]  // IDs dos todos excluídos
     }
   }
   ```

3. **Implementar endpoints de upload** (para sincronização bidirecional):
   - `POST /todos` - Criar todo
   - `PUT /todos/{id}` - Atualizar todo
   - `DELETE /todos/{id}` - Excluir todo

## Arquitetura

### Clean Architecture

O projeto segue os princípios da Clean Architecture:

- **Domain**: Entidades, casos de uso e contratos (interfaces)
- **Data**: Implementações de repositórios e fontes de dados
- **Presentation**: Controllers, páginas e widgets

### Injeção de Dependência

Usamos flutter_modular para:
- Gerenciar dependências
- Navegação entre telas
- Modularização da aplicação

### Gerenciamento de Estado

Usamos ValueNotifier para:
- Estado reativo simples
- Baixa complexidade
- Performance otimizada

## Personalização

Você pode usar este exemplo como base para:

1. **Adicionar novos módulos**: Crie novos módulos seguindo a mesma estrutura
2. **Implementar autenticação**: Adicione um módulo de auth
3. **Adicionar mais campos**: Estenda a entidade Todo
4. **Customizar UI**: Modifique os widgets e temas
5. **Integrar com APIs reais**: Configure endpoints reais

## Dependências Principais

- `flutter_modular`: Injeção de dependência e navegação
- `shared_preferences`: Persistência local
- `syncly`: Biblioteca de sincronização (local)
- `uuid`: Geração de IDs únicos

## Documentação Adicional

- 📖 [Guia de Sincronização Incremental](INCREMENTAL_SYNC_EXAMPLE.md) - Implementação detalhada
- 📖 [Guia do Backend](../BACKEND_SYNC_GUIDE.md) - Como implementar o servidor
- 📖 [Documentação Completa](../INCREMENTAL_SYNC_GUIDE.md) - Guia abrangente

## Próximos Passos

- [ ] Implementar endpoints reais do backend
- [ ] Substituir simulações por chamadas de API reais
- [ ] Adicionar testes unitários
- [ ] Implementar autenticação
- [ ] Adicionar filtros e busca
- [ ] Implementar categorias
- [ ] Adicionar notificações
- [ ] Melhorar tratamento de erros