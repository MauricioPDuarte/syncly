/// Sistema de Sincronização Syncly
///
/// Sistema centralizado e simplificado para sincronização de dados.
///
/// ## Uso Básico
///
/// 1. Implemente uma classe que estende [SyncConfig]
/// 2. Inicialize com [SyncConfigurator.initialize]
/// 3. Use [SyncConfigurator.syncService] para acessar funcionalidades
///
/// ```dart
/// // 1. Implementar provider
/// class MySyncConfig extends SyncConfig {
///   // implementar métodos obrigatórios
/// }
///
/// // 2. Inicializar
/// await SyncConfigurator.initialize(
///   provider: MySyncConfig(),
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
export 'sync_config.dart' show SyncConfig;

/// Configurador principal do sistema
export 'sync_configurator.dart' show SyncConfigurator;

/// Inicializador do sistema
export 'sync_initializer.dart' show SyncInitializer;

// ========== INTERFACES ESSENCIAIS ==========

/// Interface principal do serviço de sync
export 'core/interfaces/i_sync_service.dart' show ISyncService;

/// Interface para estratégias de download personalizadas
export 'core/interfaces/i_download_strategy.dart'
    show IDownloadStrategy, DownloadResult;

// ========== ENTIDADES E MODELOS ==========

/// Dados de sincronização
export 'core/entities/sync_data.dart' show SyncData;

/// Resposta HTTP padronizada
export 'core/entities/sync_http_response.dart' show SyncHttpResponse;

/// Enums essenciais
export 'core/enums/sync_operation.dart' show SyncOperation;
export 'core/enums/sync_status.dart' show SyncStatus;

/// Contratos e interfaces de modelo

/// Interfaces de storage
export 'core/interfaces/i_storage_provider.dart' show IStorageProvider;

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
export 'core/presentation/widgets/sync_details_bottom_sheet.dart'
    show SyncDetailsBottomSheet;

// ========== CONSTANTES E CONFIGURAÇÕES ==========

/// Configurações estáticas do sistema
export 'core/config/sync_constants.dart' show SyncConstants;

// ========== EXEMPLO DE IMPLEMENTAÇÃO ==========

// ========== ESTRATÉGIAS ==========

/// Estratégias de download e upload
export 'strategies/sync_download_strategy.dart' show SyncDownloadStrategy;
export 'strategies/sync_upload_strategy.dart' show SyncUploadStrategy;
