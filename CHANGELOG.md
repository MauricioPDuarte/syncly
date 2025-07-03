# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 04/06/2025

### 🚀 Adicionado
- **Sistema de Notificações Interno**: Novo `SyncNotificationService` centraliza toda a lógica de notificações
- **Configuração Simplificada**: Desenvolvedores agora só precisam definir `enableNotifications = true`
- **Padrão Singleton**: Garantia de uma única instância do serviço de notificações
- **Logs de Desenvolvimento**: Sistema de logs detalhados para facilitar debug e desenvolvimento

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

[1.0.0]: https://github.com/seu-usuario/syncly/releases/tag/v1.0.0