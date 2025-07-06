import 'dart:convert';
import 'dart:developer' as developer;
import '../interfaces/i_sync_log_manager.dart';
import '../interfaces/i_storage_provider.dart';
import '../entities/sync_log.dart';
import '../enums/sync_operation.dart';
import 'package:uuid/uuid.dart';

/// Implementação interna do armazenamento de logs de sincronização
///
/// Esta classe é responsável por gerenciar os logs de sincronização
/// usando apenas o ISyncStorageProvider, mantendo o sync completamente
/// independente de implementações externas.
class SyncLogManager implements ISyncLogManager {
  static const String _syncLogsKey = 'sync_logs';
  static const String _syncLogPrefix = 'sync_log_';

  final IStorageProvider _storageProvider;
  final Uuid _uuid = const Uuid();

  SyncLogManager(this._storageProvider);

  /// Cria um novo log de sincronização
  @override
  Future<void> createLog(SyncLog log) async {
    try {
      final syncLog = SyncLog(
        syncId: _uuid.v4(),
        entityType: log.entityType,
        entityId: log.entityId,
        operation: log.operation,
        dataJson: log.dataJson,
        isFileToUpload: log.isFileToUpload,
        isSynced: false,
        retryCount: 0,
        createdAt: DateTime.now(),
      );

      await _saveSyncLog(syncLog);
    } catch (e) {
      developer.log(
        'Erro ao criar log de sincronização: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      // Não propaga o erro para não afetar a operação principal
    }
  }

  @override
  Future<List<SyncLog>> getPendingLogs() async {
    try {
      final allLogs = await _getAllLogs();
      return allLogs.where((log) => !log.isSynced).toList();
    } catch (e) {
      developer.log(
        'Erro ao buscar logs pendentes: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      return [];
    }
  }

  @override
  Future<List<SyncLog>> getFailedLogs() async {
    try {
      final allLogs = await _getAllLogs();
      return allLogs
          .where((log) => !log.isSynced && log.retryCount > 0)
          .toList();
    } catch (e) {
      developer.log(
        'Erro ao buscar logs com falha: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      return [];
    }
  }

  @override
  Future<List<SyncLog>> getAllLogs() async {
    return await _getAllLogs();
  }

  @override
  Future<List<SyncLog>> getLogsBySyncId(String syncId) async {
    try {
      final allLogs = await _getAllLogs();
      return allLogs.where((log) => log.syncId == syncId).toList();
    } catch (e) {
      developer.log(
        'Erro ao buscar logs por syncId: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      return [];
    }
  }

  @override
  Future<List<SyncLog>> getLogsByEntityType(String entityType) async {
    try {
      final allLogs = await _getAllLogs();
      return allLogs.where((log) => log.entityType == entityType).toList();
    } catch (e) {
      developer.log(
        'Erro ao buscar logs por tipo de entidade: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      return [];
    }
  }

  @override
  Future<void> markAsSynced(String syncId) async {
    try {
      final syncLog = await _getSyncLogById(syncId);
      if (syncLog == null) return;

      final updatedLog = syncLog.copyWith(
        isSynced: true,
        syncedAt: DateTime.now(),
      );

      await _saveSyncLog(updatedLog);
    } catch (e) {
      developer.log(
        'Erro ao marcar log como sincronizado: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<void> incrementRetryCount(String syncId) async {
    try {
      final syncLog = await _getSyncLogById(syncId);
      if (syncLog == null) return;

      final updatedLog = syncLog.copyWith(
        retryCount: syncLog.retryCount + 1,
        lastAttemptAt: DateTime.now(),
      );

      await _saveSyncLog(updatedLog);
    } catch (e) {
      developer.log(
        'Erro ao incrementar contador de retry: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<void> setLastError(String syncId, String error) async {
    try {
      final syncLog = await _getSyncLogById(syncId);
      if (syncLog == null) return;

      final updatedLog = syncLog.copyWith(
        lastError: error,
        lastAttemptAt: DateTime.now(),
      );

      await _saveSyncLog(updatedLog);
    } catch (e) {
      developer.log(
        'Erro ao definir último erro: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      final allKeys = await _storageProvider.getKeys();
      final syncLogKeys = allKeys
          .where((key) => key.startsWith(_syncLogPrefix) || key == _syncLogsKey)
          .toList();

      for (final key in syncLogKeys) {
        await _storageProvider.remove(key);
      }
    } catch (e) {
      developer.log(
        'Erro ao limpar todos os logs: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<void> removeLog(String syncId) async {
    try {
      await _storageProvider.remove('$_syncLogPrefix$syncId');
      await _removeFromLogsList(syncId);
    } catch (e) {
      developer.log(
        'Erro ao remover log: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<void> cleanupOldSyncedLogs(DateTime olderThan) async {
    try {
      final allLogs = await _getAllLogs();
      final logsToRemove = allLogs
          .where((log) =>
              log.isSynced &&
              log.syncedAt != null &&
              log.syncedAt!.isBefore(olderThan))
          .toList();

      for (final log in logsToRemove) {
        await removeLog(log.syncId);
      }

      developer.log(
        'Limpeza de logs antigos concluída: ${logsToRemove.length} logs removidos',
        name: 'InternalSyncLogStorage',
        level: 800,
      );
    } catch (e) {
      developer.log(
        'Erro ao limpar logs antigos: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
    }
  }

  @override
  Future<Map<String, int>> getLogStatistics() async {
    try {
      final allLogs = await _getAllLogs();

      return {
        'total': allLogs.length,
        'pending': allLogs.where((log) => !log.isSynced).length,
        'synced': allLogs.where((log) => log.isSynced).length,
        'failed':
            allLogs.where((log) => !log.isSynced && log.retryCount > 0).length,
        'files': allLogs.where((log) => log.isFileToUpload).length,
      };
    } catch (e) {
      developer.log(
        'Erro ao obter estatísticas dos logs: $e',
        name: 'InternalSyncLogStorage',
        level: 1000,
      );
      return {
        'total': 0,
        'pending': 0,
        'synced': 0,
        'failed': 0,
        'files': 0,
      };
    }
  }

  // Métodos privados

  Future<void> _saveSyncLog(SyncLog syncLog) async {
    // Salva o log individual
    final syncLogJson = _toJson(syncLog);
    await _storageProvider.setString(
        '$_syncLogPrefix${syncLog.syncId}', jsonEncode(syncLogJson));

    // Atualiza a lista geral
    await _updateLogsList(syncLog);
  }

  Future<SyncLog?> _getSyncLogById(String syncId) async {
    final syncLogData =
        await _storageProvider.getString('$_syncLogPrefix$syncId');
    if (syncLogData == null) return null;

    final json = jsonDecode(syncLogData) as Map<String, dynamic>;
    return _fromJson(json);
  }

  Future<List<SyncLog>> _getAllLogs() async {
    final syncLogsData = await _storageProvider.getString(_syncLogsKey);
    if (syncLogsData == null) return [];

    final jsonList = jsonDecode(syncLogsData) as List<dynamic>;
    return jsonList
        .cast<Map<String, dynamic>>()
        .map((data) => _fromJson(data))
        .toList();
  }

  Future<void> _updateLogsList(SyncLog syncLog) async {
    final existingLogs = await _getAllLogs();
    final logIndex =
        existingLogs.indexWhere((log) => log.syncId == syncLog.syncId);

    if (logIndex >= 0) {
      existingLogs[logIndex] = syncLog;
    } else {
      existingLogs.add(syncLog);
    }

    final logsJson = existingLogs.map(_toJson).toList();
    await _storageProvider.setString(_syncLogsKey, jsonEncode(logsJson));
  }

  Future<void> _removeFromLogsList(String syncId) async {
    final existingLogs = await _getAllLogs();
    final updatedLogs =
        existingLogs.where((log) => log.syncId != syncId).toList();

    final logsJson = updatedLogs.map(_toJson).toList();
    await _storageProvider.setString(_syncLogsKey, jsonEncode(logsJson));
  }

  Map<String, dynamic> _toJson(SyncLog syncLog) {
    return {
      'syncId': syncLog.syncId,
      'entityType': syncLog.entityType,
      'entityId': syncLog.entityId,
      'operation': syncLog.operation.value,
      'dataJson': syncLog.dataJson,
      'isFileToUpload': syncLog.isFileToUpload,
      'isSynced': syncLog.isSynced,
      'retryCount': syncLog.retryCount,
      'lastError': syncLog.lastError,
      'createdAt': syncLog.createdAt.toIso8601String(),
      'lastAttemptAt': syncLog.lastAttemptAt?.toIso8601String(),
      'syncedAt': syncLog.syncedAt?.toIso8601String(),
    };
  }

  SyncLog _fromJson(Map<String, dynamic> json) {
    return SyncLog(
      syncId: json['syncId'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: SyncOperation.values.firstWhere(
        (op) => op.value == json['operation'],
        orElse: () => SyncOperation.create,
      ),
      dataJson: json['dataJson'] as String,
      isFileToUpload: json['isFileToUpload'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
    );
  }
}
