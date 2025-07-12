# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.5] - 06/06/2025
### 🚀 Adicionado
- **Notificações Reais**: Implementação completa de notificações nativas usando `flutter_local_notifications`
- **Canais de Notificação**: Organização por categorias (Status, Erros, Conectividade, Progresso)
- **Notificações de Progresso**: Barras visuais de progresso para downloads e uploads
- **Configuração Automática**: Inicialização automática dos canais de notificação

### 🔧 Modificado
- **SyncNotificationService**: Migração de simulação para notificações reais do sistema
- **Dependências**: Adicionado `flutter_local_notifications: ^17.2.3`
- **Permissões Android**: Adicionadas permissões necessárias no exemplo

### 📱 Melhorias
- **UX**: Notificações agora aparecem na barra de notificações do dispositivo
- **Organização**: Canais separados por tipo de notificação
- **Fallback**: Mantido fallback para debug em caso de erro

### Added
- **Sistema de Permissões de Notificação**: Verificação e solicitação automática de permissões
  - Método `_requestNotificationPermission()` interno no `SyncInitializer` com implementação completa
  - Método público `checkNotificationPermission()` para verificar status das permissões
  - Método público `requestNotificationPermission()` para solicitar permissões manualmente
  - Verificação automática de permissões durante a inicialização quando `enableNotifications = true`
  - Integração com `permission_handler` para gerenciamento robusto de permissões
  - Tratamento de diferentes estados de permissão (concedida, negada, negada permanentemente)
  - Logs detalhados sobre o status das permissões de notificação
  - Guia completo de configuração em `NOTIFICATION_PERMISSIONS_GUIDE.md`
- **Dependência permission_handler**: Adicionada versão ^11.3.1 para gerenciamento de permissões
- **Sincronização Incremental**: Nova funcionalidade que permite sincronizar apenas dados modificados
  - Método `getLastSyncTimestamp()` no SyncConfig para obter timestamp da última sincronização
  - Método `saveLastSyncTimestamp()` no SyncConfig para salvar timestamp da sincronização
  - Propriedade `useIncrementalSync` no SyncConfig para habilitar/desabilitar sincronização incremental
  - Propriedade `maxIncrementalSyncInterval` no SyncConfig para controlar intervalo máximo da sincronização incremental
  - Parâmetro `lastSyncTimestamp` na interface `IDownloadStrategy.downloadData()`
  - Propriedades `deletedEntities` e `isIncremental` na classe `DownloadResult`
  - Lógica automática para decidir entre sincronização completa e incremental
  - Processamento automático de entidades excluídas no servidor
  - Exemplo de implementação em `IncrementalDownloadStrategyExample`
  - Guia completo de implementação em `INCREMENTAL_SYNC_GUIDE.md`

### Changed
- **BREAKING CHANGE**: Estratégias de download agora são obrigatórias no `SyncConfig`
  - Propriedade `downloadStrategies` no `SyncConfig` não é mais opcional
  - Todas as implementações de `SyncConfig` devem fornecer pelo menos uma estratégia de download
  - Melhora a consistência e previsibilidade do sistema de sincronização
  - Evita erros de runtime por falta de estratégias configuradas

### Removed
- **BREAKING CHANGE**: Removido suporte ao `StrategyResolver`
  - Parâmetros `downloadStrategies` e `strategyResolver` removidos do `SyncInitializer.initialize()`
  - Typedef `StrategyResolver` removido
  - Estratégias agora devem ser definidas exclusivamente no `SyncConfig`

### Changed
- Interface `IDownloadStrategy.downloadData()` agora aceita parâmetros opcionais `lastSyncTimestamp` e `isIncremental`
- Classe `DownloadResult` expandida com informações sobre sincronização incremental
- `SyncDownloadStrategy` atualizada para suportar sincronização incremental e passar parâmetro `isIncremental`
- Exemplo `SynclyConfig` atualizado com implementação dos novos métodos
- Estratégias de download agora recebem explicitamente se devem fazer sincronização incremental

### Improved
- **Sistema de Permissões**: Implementação robusta com tratamento completo de estados
  - Verificação automática do status atual das permissões
  - Solicitação inteligente apenas quando necessário
  - Tratamento específico para permissões negadas permanentemente
  - Logs informativos para debugging e monitoramento
- Performance da sincronização significativamente melhorada para dados grandes
- Redução no uso de dados de rede
- Experiência do usuário aprimorada com sincronizações mais rápidas
- Menor carga no servidor backend

## [1.1.4] - 03/07/2025

### 🚀 Adicionado
- **StrategyResolver**: Nova funcionalidade para integração com sistemas de injeção de dependência
- **Suporte a Modular**: Integração nativa com Flutter Modular via `strategyResolver`
- **Suporte a GetIt**: Integração nativa com GetIt via `strategyResolver`
- **Lazy Loading**: Estratégias de download são resolvidas apenas quando necessário
- **Typedef StrategyResolver**: Novo tipo `StrategyResolver = List<IDownloadStrategy> Function()` para callbacks de resolução
- **Endpoint de Erros Configurável**: Adicionado `errorReportingEndpoint` ao `SyncConfig` para configuração personalizada
- **Getter errorReportConfig**: Novo método getter no `SyncConfig` para configuração completa do sistema de envio de erros

### 🔄 Modificado
- **SyncInitializer.initialize()**: Adicionado parâmetro opcional `strategyResolver`
- **SyncConfigurator.initialize()**: Adicionado suporte ao `StrategyResolver`
- **Registro de Dependências**: Modificado para usar callback de resolução quando fornecido
- **SyncConfigurator**: Atualizado para usar `errorReportConfig` completo do provider ao invés de endpoint fixo
- **SyncConfig**: Adicionado import de `SyncErrorReportConfig` para suporte ao novo getter

### 🛠️ Melhorado
- **Ordem de Inicialização**: Resolve problemas de dependências não registradas durante inicialização
- **Flexibilidade**: Funciona com qualquer sistema de injeção de dependência
- **Compatibilidade**: Mantém total compatibilidade com versões anteriores
- **Arquitetura**: Melhor separação entre inicialização do Syncly e sistemas de DI
- **Configuração de Erros**: Sistema de envio de erros agora totalmente configurável via `SyncConfig`
- **Flexibilidade de Endpoints**: Endpoints de erro podem ser personalizados por projeto

### 📚 Documentação
- Atualizado README.md com exemplos de uso do `StrategyResolver`
- Atualizada documentação HTML com nova funcionalidade
- Adicionados exemplos de integração com Modular e GetIt
- Documentadas as três opções de configuração de estratégias
- Adicionada seção "Configuração de Endpoints" no README.md
- Atualizada documentação HTML com exemplos de configuração de `errorReportingEndpoint`
- Documentado o novo getter `errorReportConfig` no `SyncConfig`

### 🔧 Correções
- **TodoDownloader**: Implementado lazy loading para `RestClient` via getter
- **Exemplo**: Removida inicialização duplicada do `SyncInitializer` no `AppWidget`
- **Dependências**: Resolvidos problemas de ordem de inicialização no exemplo

## [1.1.1] - 05/06/2025

### 🔧 Correções
- **Inicialização do SyncInitializer**: Corrigido erro "Bad state: SyncInitializer não foi inicializado" que ocorria quando serviços tentavam acessar o `SyncInitializer` antes de sua inicialização completa
- **Injeção de Dependência Lazy**: Implementada inicialização lazy no `SynclyService` para evitar chamadas prematuras ao `ISyncService.getInstance()`
- **TodoLocalDatasource**: Modificado para usar `Modular.get<AppSyncService>()` de forma lazy, evitando dependências circulares durante a inicialização
- **Ordem de Inicialização**: Garantida a ordem correta de inicialização dos serviços, com o `SyncInitializer` sendo inicializado antes de qualquer acesso aos serviços de sincronização

### 🛠️ Melhorado
- **Estabilidade**: Eliminadas condições de corrida durante a inicialização da aplicação
- **Arquitetura**: Melhorada a gestão de dependências para evitar inicializações prematuras
- **Robustez**: Sistema mais resiliente a problemas de ordem de inicialização

## [0.1.0] - 04/06/2025

### 🚀 Adicionado
- **Sistema de Notificações Interno**: Novo `SyncNotificationService` centraliza toda a lógica de notificações
- **Configuração Simplificada**: Desenvolvedores agora só precisam definir `enableNotifications = true`
- **Padrão Singleton**: Garantia de uma única instância do serviço de notificações
- **Logs de Desenvolvimento**: Sistema de logs detalhados para facilitar debug e desenvolvimento
- **Estratégias de Download Flexíveis**: Agora é possível passar estratégias de download diretamente no método `SyncInitializer.initialize()`
- **Parâmetro `downloadStrategies`**: Novo parâmetro opcional no `initialize()` para maior flexibilidade

### 🔄 Modificado
- **BREAKING CHANGE**: Removidos métodos de notificação obrigatórios do `SyncConfig`
  - `initializeNotifications()` - agora gerenciado internamente
  - `showNotification()` - substituído pelo serviço interno
  - `showProgressNotification()` - substituído pelo serviço interno
  - `cancelNotification()` - substituído pelo serviço interno
  - `cancelAllNotifications()` - substituído pelo serviço interno
  - `areNotificationsEnabled()` - removido, use `enableNotifications` property
- **SyncConfigurator**: Atualizado para usar o serviço interno de notificações
- **Todos os Serviços**: Migrados para usar `SyncNotificationService.instance`

### 🛠️ Melhorado
- **Experiência do Desenvolvedor**: Menos código boilerplate necessário
- **Manutenibilidade**: Lógica de notificações centralizada em um local
- **Flexibilidade**: Fácil extensão e customização do sistema de notificações
- **Compatibilidade**: Propriedade `enableNotifications` mantida para compatibilidade
- **Testabilidade**: Estratégias de download podem ser facilmente mockadas em testes
- **Modularidade**: Estratégias podem ser definidas em módulos separados e reutilizadas

### 📚 Documentação
- Atualizada documentação HTML com novo sistema de notificações
- README atualizado com exemplos simplificados
- Removidos exemplos de implementação de métodos de notificação obsoletos

### 🔧 Correções
- Corrigido import incorreto em `sync_download_strategy.dart`
- Removidas referências obsoletas a métodos de notificação
- Validação completa com `flutter analyze` sem erros

## [0.0.2] - 03/06/2025

### Corrigido
- Correções pequenas, removendo métodos obsoletos.


## [0.0.1]  03/06/2025

### Corrigido
- Correção de parâmetros `isSuccess` e `error` na classe `SyncHttpResponse`
- Substituição de `print` por `debugPrint` nos arquivos de exemplo
- Remoção de imports desnecessários (`dart:typed_data`)
- Implementação completa da classe `SyncConfig` com todos os métodos obrigatórios

### Adicionado
- Sistema completo de envio de erros para backend via `SyncErrorReporter`
- Documentação detalhada do sistema de envio de erros em `sync_documentation.html`
- Implementação de métodos HTTP (GET, POST, PUT, DELETE, PATCH, download, upload) usando Dio
- Métodos de autenticação usando SharedPreferences
- Sistema de notificações com callbacks configuráveis
- Estratégias de download e limpeza de dados

### Melhorado
- Documentação atualizada com exemplos práticos de uso
- Estrutura de configuração mais robusta e extensível
- Tratamento de erros aprimorado com logging estruturado

## [1.0.0] - 02/06/2025

### Adicionado
- Sistema de sincronização bidirecional completo
- Sincronização em background com WorkManager
- Sistema de tema independente (SyncTheme)
- Widgets de UI prontos (SyncIndicator, SyncDetailsBottomSheet)
- Gerenciamento de conectividade automático
- Sistema de logs e debug configurável
- Tratamento robusto de erros
- Arquitetura baseada em estratégias (Strategy Pattern)
- Configuração centralizada via SyncConfigurator
- Suporte a múltiplas estratégias de download
- Sistema de notificações configurável
- Armazenamento local com SharedPreferences
- Geração automática de UUIDs para logs
- Cliente HTTP configurável com Dio

### Características Técnicas
- Injeção de dependência com GetIt
- Interfaces bem definidas para extensibilidade
- Padrão Provider para configuração
- ValueNotifier para reatividade
- Suporte a temas claro e escuro
- Logs estruturados com categorias
- Cleanup automático de dados antigos
- Relatórios de erro configuráveis

### Dependências
- Flutter SDK >=3.10.0
- Dart SDK >=3.0.0
- dio: ^5.4.0
- get_it: ^7.6.4
- workmanager: ^0.5.2
- shared_preferences: ^2.2.2
- uuid: ^4.2.1

### Documentação
- README completo com exemplos de uso
- Documentação de arquitetura
- Guias de implementação
- Exemplos de configuração

[1.0.0]: https://github.com/MauricioPDuarte/syncly/releases/tag/v1.0.0