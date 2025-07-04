import 'core/interfaces/i_download_strategy.dart';
import 'core/interfaces/i_logger_debug_provider.dart';
import 'core/interfaces/i_storage_provider.dart';
import 'core/interfaces/i_sync_service.dart';
import 'core/providers/default_sync_logger_provider.dart';
import 'core/theme/sync_theme.dart';
import 'sync_config.dart';
import 'sync_configurator.dart';
import 'package:get_it/get_it.dart';

/// Typedef para resolver estratégias de download dinamicamente
typedef StrategyResolver = List<IDownloadStrategy> Function();

/// Classe responsável por inicializar os serviços de sincronização usando SyncConfig
class SyncInitializer {
  static bool _isInitialized = false;
  static SyncConfig? _provider;
  static final ISyncLoggerDebugProvider _defaultLogger =
      DefaultSyncLoggerProvider();

  static bool get isInitialized => _isInitialized;
  static SyncConfig? get provider => _provider;
  static ISyncLoggerDebugProvider get logger => _defaultLogger;

  /// Inicializa o sistema de sincronização com um SyncConfig
  /// 
  /// [provider] - Configuração do sistema de sincronização
  /// [downloadStrategies] - Lista de estratégias de download (opcional, se não fornecida usa as do SyncConfig)
  /// [strategyResolver] - Callback para resolver estratégias dinamicamente (alternativa a downloadStrategies)
  static Future<void> initialize(
    SyncConfig provider, {
    List<IDownloadStrategy>? downloadStrategies,
    StrategyResolver? strategyResolver,
  }) async {
    if (_isInitialized) {
      _defaultLogger.info('SyncInitializer já foi inicializado',
          category: 'SyncInitializer');
      return;
    }

    try {
      // Armazena o provider
      _provider = provider;
      _defaultLogger.info('SyncConfig configurado com sucesso',
          category: 'SyncInitializer');

      // Configura o tema se fornecido
      if (provider.theme != null) {
        SyncThemeProvider.setTheme(provider.theme!);
      }

      // Inicializa o SyncConfigurator com o provider
      SyncConfigurator.initialize(
        provider: provider, 
        downloadStrategies: downloadStrategies,
        strategyResolver: strategyResolver,
      );
      _defaultLogger.info('SyncConfigurator inicializado com sucesso',
          category: 'SyncInitializer');

      _isInitialized = true;
      _defaultLogger.info('SyncInitializer inicializado com sucesso',
          category: 'SyncInitializer');
    } catch (e, stackTrace) {
      _defaultLogger.error(
        'Erro ao inicializar SyncInitializer: $e',
        category: 'SyncInitializer',
        exception: e,
        stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  // Configuration-based approach: Dependencies are now registered in SyncModule
  // using the stored configuration instead of dynamic registration

  /// Salva a preferência do usuário para background sync
  static Future<void> saveBackgroundSyncPreference(bool enabled) async {
    try {
      if (!_isInitialized) {
        throw Exception('SyncInitializer não foi inicializado');
      }

      IStorageProvider storageProvider = GetIt.instance.get<IStorageProvider>();

      await storageProvider.setBool('background_sync_enabled', enabled);

      _defaultLogger.info(
        'Preferência de background sync salva: $enabled',
        category: 'SyncInitializer',
      );
    } catch (e) {
      _defaultLogger.error(
        'Erro ao salvar preferência de background sync: $e',
        category: 'SyncInitializer',
        exception: e,
      );
      rethrow;
    }
  }

  /// Recupera a preferência do usuário para background sync
  static Future<bool> getBackgroundSyncPreference() async {
    try {
      if (!_isInitialized) {
        throw Exception('SyncInitializer não foi inicializado');
      }

      IStorageProvider storageProvider = GetIt.instance.get<IStorageProvider>();

      final preference =
          await storageProvider.getBool('background_sync_enabled');
      return preference ?? false;
    } catch (e) {
      _defaultLogger.error(
        'Falha ao recuperar preferência de background sync',
        category: 'SyncInitializer',
        exception: e,
      );

      return false; // Default para false em caso de erro
    }
  }

  /// Atualiza a configuração de sincronização com um novo provider
  static Future<void> updateConfig(SyncConfig newProvider) async {
    try {
      if (!_isInitialized) {
        throw Exception('SyncInitializer deve ser inicializado primeiro');
      }

      // Reset do configurador antes de reinicializar
      SyncConfigurator.reset();
      _isInitialized = false;

      await initialize(newProvider);

      _defaultLogger.info(
        'Configuração do sistema de sincronização atualizada',
        category: 'SyncInitializer',
        metadata: {
          'appName': newProvider.appName,
          'backgroundSync': newProvider.enableBackgroundSync,
          'notifications': newProvider.enableNotifications,
          'syncInterval': newProvider.syncInterval.inMinutes,
        },
      );
    } catch (e) {
      _defaultLogger.error(
        'Falha ao atualizar configuração do sistema de sincronização',
        category: 'SyncInitializer',
        exception: e,
        stackTrace: StackTrace.current.toString(),
      );

      rethrow;
    }
  }

  /// Obtém o serviço de sync após inicialização
  static ISyncService get syncService {
    if (!_isInitialized) {
      throw StateError(
          'SyncInitializer não foi inicializado. Chame initialize() primeiro.');
    }
    return SyncConfigurator.syncService;
  }

  /// Reset do inicializador (útil para testes)
  static void reset() {
    if (_isInitialized) {
      SyncConfigurator.reset();
    }
    _provider = null;
    _isInitialized = false;
  }
}
