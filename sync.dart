/// Sistema de Sincronização Syncly
/// 
/// Sistema centralizado e simplificado para sincronização de dados.
/// 
/// ## Uso Básico
/// 
/// 1. Implemente uma classe que estende [SyncProvider]
/// 2. Inicialize com [SyncConfigurator.initialize]
/// 3. Use [SyncConfigurator.syncService] para acessar funcionalidades
/// 
/// ```dart
/// // 1. Implementar provider
/// class MySyncProvider extends SyncProvider {
///   // implementar métodos obrigatórios
/// }
/// 
/// // 2. Inicializar
/// await SyncConfigurator.initialize(
///   provider: MySyncProvider(),
/// );
/// 
/// // 3. Usar
/// final syncService = SyncConfigurator.syncService;
/// await syncService.startSync();
/// ```
/// 
/// Veja [README.md] para documentação completa.
library sync;

// ========== EXPORTS PRINCIPAIS ==========

/// Classe principal para implementação pelo usuário
export 'sync_provider.dart' show SyncProvider;

/// Configurador principal do sistema
export 'sync_configurator.dart' show SyncConfigurator;

// ========== INTERFACES ESSENCIAIS ==========

/// Interface principal do serviço de sync
export 'core/interfaces/i_sync_service.dart' show ISyncService;

/// Interface para estratégias de download personalizadas
export 'core/interfaces/i_download_strategy.dart' show IDownloadStrategy;

// ========== ENTIDADES E MODELOS ==========

/// Resposta HTTP padronizada
export 'core/entities/sync_http_response.dart' show SyncHttpResponse;

/// Tema personalizado para componentes do sync
export 'core/theme/sync_theme.dart' show SyncTheme;

/// Configuração para relatórios de erro
export 'core/services/sync_error_reporter.dart' show SyncErrorReportConfig;

// ========== UTILITÁRIOS ==========

/// Utilitários diversos para sync
export 'core/utils/sync_utils.dart' show SyncUtils;

// ========== WIDGETS (se necessário) ==========

/// Indicador de sincronização
export 'core/presentation/widgets/sync_indicator.dart' show SyncIndicator;

/// Bottom sheet com detalhes de sincronização
export 'core/presentation/widgets/sync_details_bottom_sheet.dart' show SyncDetailsBottomSheet;

// ========== CONSTANTES E CONFIGURAÇÕES ==========

/// Configurações estáticas do sistema
export 'core/config/sync_config.dart' show SyncConfig;

// ========== EXEMPLO DE IMPLEMENTAÇÃO ==========

// ========== ESTRATÉGIAS ==========

/// Estratégias de download e upload
export 'strategies/sync_download_strategy.dart' show SyncDownloadStrategy;
export 'strategies/sync_upload_strategy.dart' show SyncUploadStrategy;