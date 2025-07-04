import 'core/interfaces/i_sync_log_manager.dart';
import 'core/services/sync_log_manager.dart';
import 'package:get_it/get_it.dart';
import 'sync_config.dart';
import 'core/interfaces/i_sync_service.dart';
import 'core/interfaces/i_download_strategy.dart';
import 'core/services/sync_connectivity_service.dart';
import 'core/services/sync_error_manager.dart';
import 'core/services/sync_error_reporter.dart';
import 'core/services/sync_data_cleanup_service.dart';
import 'core/services/sync_logger_service.dart';
import 'core/interfaces/i_logger_debug_provider.dart';
import 'sync_service.dart';
import 'core/theme/sync_theme.dart';
import 'core/interfaces/i_logger_provider.dart';
import 'core/interfaces/i_storage_provider.dart';
import 'core/services/storage_service.dart';
import 'core/providers/default_sync_logger_provider.dart';
import 'core/presentation/controllers/sync_indicator_controller.dart';
import 'core/services/sync_notification_service.dart';

/// Configurador principal do sistema de sincronização
///
/// Esta classe simplifica a configuração do sync, permitindo que o usuário
/// implemente apenas um SyncConfig e tenha todo o sistema funcionando.
class SyncConfigurator {
  static SyncConfig? _provider;
  static bool _isInitialized = false;

  /// Inicializa o sistema de sync com o provider fornecido
  ///
  /// [provider] - Implementação do SyncConfig com todas as configurações
  /// [registerInGetIt] - Se deve registrar automaticamente no GetIt (padrão: true)
  /// [downloadStrategies] - Lista de estratégias de download (opcional, se não fornecida usa as do SyncConfig)
  static Future<void> initialize({
    required SyncConfig provider,
    bool registerInGetIt = true,
    List<IDownloadStrategy>? downloadStrategies,
  }) async {
    if (_isInitialized) {
      throw StateError(
          'SyncConfigurator já foi inicializado. Use reset() antes de inicializar novamente.');
    }

    _provider = provider;

    // Configurações são aplicadas através do provider
    // SyncConfig permanece com valores padrão

    // Registra dependências no GetIt se solicitado
    if (registerInGetIt) {
      _registerDependencies(provider, downloadStrategies);
    }

    // Inicializa o serviço interno de notificações se habilitadas
    if (provider.enableNotifications) {
      await SyncNotificationService.instance.initialize(enabled: true);
    } else {
      await SyncNotificationService.instance.initialize(enabled: false);
    }

    _isInitialized = true;
  }

  /// Reseta o configurador (útil para testes)
  static void reset() {
    if (_isInitialized) {
      // Remove todas as dependências registradas do GetIt
      final getIt = GetIt.instance;
      if (getIt.isRegistered<ISyncService>()) getIt.unregister<ISyncService>();
      if (getIt.isRegistered<List<IDownloadStrategy>>()) {
        getIt.unregister<List<IDownloadStrategy>>();
      }
      if (getIt.isRegistered<ISyncConnectivityService>()) {
        getIt.unregister<ISyncConnectivityService>();
      }
      if (getIt.isRegistered<ISyncErrorManager>()) {
        getIt.unregister<ISyncErrorManager>();
      }
      if (getIt.isRegistered<ISyncDataCleanupService>()) {
        getIt.unregister<ISyncDataCleanupService>();
      }
      if (getIt.isRegistered<ILoggerProvider>()) {
        getIt.unregister<ILoggerProvider>();
      }
      if (getIt.isRegistered<ISyncLoggerDebugProvider>()) {
        getIt.unregister<ISyncLoggerDebugProvider>();
      }
      if (getIt.isRegistered<ISyncErrorReporter>()) {
        getIt.unregister<ISyncErrorReporter>();
      }
      if (getIt.isRegistered<SyncIndicatorController>()) {
        getIt.unregister<SyncIndicatorController>();
      }
    }

    _provider = null;
    _isInitialized = false;
  }

  /// Verifica se o configurador foi inicializado
  static bool get isInitialized => _isInitialized;

  /// Obtém o provider atual
  static SyncConfig? get provider => _provider;

  /// Obtém o serviço de sync (após inicialização)
  static ISyncService get syncService {
    if (!_isInitialized) {
      throw StateError(
          'SyncConfigurator não foi inicializado. Chame initialize() primeiro.');
    }
    return GetIt.instance.get<ISyncService>();
  }

  /// Registra todas as dependências no GetIt
  static void _registerDependencies(
      SyncConfig provider, List<IDownloadStrategy>? downloadStrategies) {
    final getIt = GetIt.instance;

    // Registra as estratégias de download
    getIt.registerLazySingleton<List<IDownloadStrategy>>(
        () => downloadStrategies ?? []);

    // Registra serviços internos
    getIt.registerLazySingleton<ISyncConnectivityService>(
        () => SyncConnectivityService());

    // Registra o logger debug provider
    getIt.registerLazySingleton<ISyncLoggerDebugProvider>(
        () => DefaultSyncLoggerProvider());

    // Registra o storage interno para logs
    getIt.registerLazySingleton<ISyncLogManager>(
        () => SyncLogManager(getIt.get<IStorageProvider>()));

    // Registra o logger provider
    getIt.registerLazySingleton<ILoggerProvider>(() => LoggerProvider(
          getIt.get<ISyncLogManager>(),
          getIt.get<ISyncLoggerDebugProvider>(),
        ));

    // Registra o storage provider usando a implementação própria
    getIt.registerLazySingleton<IStorageProvider>(() => SyncStorageService());

    // Registra o SyncIndicatorController
    getIt.registerLazySingleton<SyncIndicatorController>(
        () => SyncIndicatorController(getIt.get<IStorageProvider>()));

    // Registra o error manager
    getIt.registerLazySingleton<ISyncErrorManager>(() => SyncErrorManager(
          getIt.get<IStorageProvider>(),
          getIt.get<ISyncLoggerDebugProvider>(),
        ));

    // Registra o data cleanup service
    getIt.registerLazySingleton<ISyncDataCleanupService>(
        () => SyncDataCleanupService(
              getIt.get<IStorageProvider>(),
              getIt.get<ISyncLoggerDebugProvider>(),
              getIt.get<ISyncErrorManager>(),
              provider,
            ));

    // Registra o reporter de erros
    getIt.registerLazySingleton<ISyncErrorReporter>(() => SyncErrorReporter(
          getIt.get<ISyncErrorManager>(),
          getIt.get<ISyncLoggerDebugProvider>(),
          SyncErrorReportConfig(
            endpoint: '${provider.baseUrl ?? ''}/errors',
          ),
          provider,
        ));

    // Registra o serviço principal de sync
    getIt.registerLazySingleton<ISyncService>(() => SyncService(
          getIt.get<ISyncConnectivityService>(),
          getIt.get<ILoggerProvider>(),
          getIt.get<ISyncErrorManager>(),
          getIt.get<ISyncErrorReporter>(),
        ));
  }

  /// Método de conveniência para configurar tema personalizado
  static void configureTheme(SyncTheme theme) {
    if (!_isInitialized) {
      throw StateError(
          'SyncConfigurator não foi inicializado. Chame initialize() primeiro.');
    }
    // Implementar configuração de tema se necessário
  }

  /// Método de conveniência para obter configurações atuais
  static Map<String, dynamic> getCurrentConfig() {
    if (!_isInitialized || _provider == null) {
      throw StateError('SyncConfigurator não foi inicializado.');
    }

    return {
      'appName': _provider!.appName,
      'appVersion': _provider!.appVersion,
      'enableDebugLogs': _provider!.enableDebugLogs,
      'enableBackgroundSync': _provider!.enableBackgroundSync,
      'enableNotifications': _provider!.enableNotifications,
      'syncInterval': _provider!.syncInterval.inMinutes,
      'backgroundSyncInterval': _provider!.backgroundSyncInterval.inMinutes,
      'maxRetryAttempts': _provider!.maxRetryAttempts,
      'networkTimeout': _provider!.networkTimeout.inSeconds,
      'maxDataBatchSize': _provider!.maxDataBatchSize,
      'maxFileBatchSize': _provider!.maxFileBatchSize,
      'baseUrl': _provider!.baseUrl,
      'dataSyncEndpoint': _provider!.dataSyncEndpoint,
      'fileSyncEndpoint': _provider!.fileSyncEndpoint,
    };
  }

  /// Método de conveniência para validar configuração
  static List<String> validateConfiguration() {
    if (!_isInitialized || _provider == null) {
      return ['SyncConfigurator não foi inicializado.'];
    }

    final errors = <String>[];

    // Validações básicas
    if (_provider!.appName.isEmpty) {
      errors.add('appName não pode estar vazio.');
    }

    if (_provider!.appVersion.isEmpty) {
      errors.add('appVersion não pode estar vazio.');
    }

    if (_provider!.maxRetryAttempts < 1) {
      errors.add('maxRetryAttempts deve ser maior que 0.');
    }

    if (_provider!.maxDataBatchSize < 1) {
      errors.add('maxDataBatchSize deve ser maior que 0.');
    }

    if (_provider!.maxFileBatchSize < 1) {
      errors.add('maxFileBatchSize deve ser maior que 0.');
    }

    // REMOVIDO: Validação de downloadStrategies (agora vem do SyncInitializer)

    return errors;
  }
}
