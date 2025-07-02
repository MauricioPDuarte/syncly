import 'dart:convert';
import '../../sync_config.dart';

import '../interfaces/i_storage_provider.dart';
import '../interfaces/i_logger_debug_provider.dart';
import 'sync_error_manager.dart';

/// Interface para limpeza de dados de sincronização
abstract class ISyncDataCleanupService {
  Future<void> clearSyncData();
  Future<void> clearErrorLogs();
  Future<void> clearSyncLogs();
  Future<void> clearAllSyncData();
  Future<void> clearOldData({int daysToKeep = 30});
  Future<Map<String, int>> getDataStatistics();
}

/// Implementação interna do serviço de limpeza de dados de sincronização
class SyncDataCleanupService implements ISyncDataCleanupService {
  final IStorageProvider _storageProvider;
  final ISyncLoggerDebugProvider? _loggerProvider;
  final ISyncErrorManager _errorManager;
  final SyncConfig _syncConfig;

  // Prefixos para diferentes tipos de dados
  static const String _syncDataPrefix = 'sync_data_';
  static const String _syncLogPrefix = 'sync_log_';
  static const String _syncQueuePrefix = 'sync_queue_';
  static const String _syncStatusPrefix = 'sync_status_';
  static const String _syncMetadataPrefix = 'sync_metadata_';

  SyncDataCleanupService(
    this._storageProvider,
    this._loggerProvider,
    this._errorManager,
    this._syncConfig,
  );

  @override
  Future<void> clearSyncData() async {
    try {
      await _clearDataByPrefix(_syncDataPrefix);
      await _clearDataByPrefix(_syncQueuePrefix);
      await _clearDataByPrefix(_syncStatusPrefix);
      await _clearDataByPrefix(_syncMetadataPrefix);

      _loggerProvider?.info(
        'Sync data cleared successfully',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear sync data: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearErrorLogs() async {
    try {
      await _errorManager.clearAllErrors();

      _loggerProvider?.info(
        'Error logs cleared successfully',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear error logs: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearSyncLogs() async {
    try {
      await _clearDataByPrefix(_syncLogPrefix);

      _loggerProvider?.info(
        'Sync logs cleared successfully',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear sync logs: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearAllSyncData() async {
    try {
      await Future.wait([
        clearSyncData(),
        clearErrorLogs(),
        clearSyncLogs(),
      ]);

      _loggerProvider?.info(
        'All sync data cleared successfully',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear all sync data: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearOldData({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      // Limpar erros antigos
      final allErrors = await _errorManager.getAllErrors();
      final oldErrors =
          allErrors.where((error) => error.timestamp.isBefore(cutoffDate));

      for (final error in oldErrors) {
        await _errorManager.removeError(error.id);
      }

      // Limpar logs antigos
      await _clearOldDataByPrefix(_syncLogPrefix, cutoffDate);

      _loggerProvider?.info(
        'Old data cleared successfully (older than $daysToKeep days)',
        category: 'SyncDataCleanupService',
        metadata: {
          'daysToKeep': daysToKeep,
          'cutoffDate': cutoffDate.toIso8601String(),
          'errorsRemoved': oldErrors.length,
        },
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear old data: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getDataStatistics() async {
    try {
      final stats = <String, int>{};

      // Contar erros
      final allErrors = await _errorManager.getAllErrors();
      stats['totalErrors'] = allErrors.length;
      stats['pendingErrors'] = allErrors.where((e) => !e.isSent).length;
      stats['sentErrors'] = allErrors.where((e) => e.isSent).length;

      // Contar dados por prefixo
      stats['syncData'] = await _countDataByPrefix(_syncDataPrefix);
      stats['syncLogs'] = await _countDataByPrefix(_syncLogPrefix);
      stats['syncQueue'] = await _countDataByPrefix(_syncQueuePrefix);
      stats['syncStatus'] = await _countDataByPrefix(_syncStatusPrefix);
      stats['syncMetadata'] = await _countDataByPrefix(_syncMetadataPrefix);

      // Verificar se há sessão ativa
      final hasSession = await _syncConfig.isAuthenticated();
      stats['hasActiveSession'] = hasSession ? 1 : 0;

      _loggerProvider?.info(
        'Data statistics retrieved',
        category: 'SyncDataCleanupService',
        metadata: stats,
      );

      return stats;
    } catch (e) {
      _loggerProvider?.error(
        'Failed to get data statistics: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      return {};
    }
  }

  // Métodos privados para operações de limpeza

  Future<void> _clearDataByPrefix(String prefix) async {
    try {
      final keys = await _storageProvider.getAllKeys();
      final keysToRemove = keys.where((key) => key.startsWith(prefix));

      for (final key in keysToRemove) {
        await _storageProvider.remove(key);
      }

      _loggerProvider?.debug(
        'Cleared ${keysToRemove.length} items with prefix: $prefix',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear data by prefix $prefix: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  Future<void> _clearOldDataByPrefix(String prefix, DateTime cutoffDate) async {
    try {
      final keys = await _storageProvider.getAllKeys();
      final keysWithPrefix = keys.where((key) => key.startsWith(prefix));

      int removedCount = 0;
      for (final key in keysWithPrefix) {
        try {
          final data = await _storageProvider.retrieve(key);
          if (data != null) {
            // Tentar extrair timestamp do dado (assumindo formato JSON)
            final Map<String, dynamic> jsonData = {};
            try {
              final decoded = jsonDecode(data);
              if (decoded is Map<String, dynamic>) {
                jsonData.addAll(decoded);
              }
            } catch (_) {
              // Se não conseguir decodificar, pular
              continue;
            }

            // Verificar se tem timestamp e se é antigo
            if (jsonData.containsKey('timestamp')) {
              final timestamp = DateTime.tryParse(jsonData['timestamp']);
              if (timestamp != null && timestamp.isBefore(cutoffDate)) {
                await _storageProvider.remove(key);
                removedCount++;
              }
            }
          }
        } catch (e) {
          _loggerProvider?.warning(
            'Failed to process key $key during old data cleanup: $e',
            category: 'SyncDataCleanupService',
          );
        }
      }

      _loggerProvider?.debug(
        'Cleared $removedCount old items with prefix: $prefix',
        category: 'SyncDataCleanupService',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear old data by prefix $prefix: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      rethrow;
    }
  }

  Future<int> _countDataByPrefix(String prefix) async {
    try {
      final keys = await _storageProvider.getAllKeys();
      return keys.where((key) => key.startsWith(prefix)).length;
    } catch (e) {
      _loggerProvider?.error(
        'Failed to count data by prefix $prefix: $e',
        category: 'SyncDataCleanupService',
        exception: e,
      );
      return 0;
    }
  }
}
