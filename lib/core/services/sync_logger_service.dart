import '../entities/sync_log.dart';

import '../interfaces/i_sync_log_manager.dart';
import '../enums/sync_operation.dart';
import '../interfaces/i_logger_debug_provider.dart';
import '../interfaces/i_logger_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Implementação do serviço de logging de sincronização
///
/// Responsável por registrar logs de sincronização usando apenas
/// o ISyncStorageProvider, mantendo o sync completamente independente.
class LoggerProvider implements ILoggerProvider {
  final ISyncLogManager _logStorage;
  final ISyncLoggerDebugProvider? _loggerDebugProvider;

  LoggerProvider(
    this._logStorage,
    this._loggerDebugProvider,
  );

  /// Acesso ao gerenciador interno de logs para operações avançadas
  ISyncLogManager get logManager => _logStorage;

  @override
  Future<void> logCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  }) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.create,
      dataJson: jsonEncode(data),
      isFileToUpload: isFileToUpload,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity created: $entityType [$entityId]',
      category: 'sync_logger',
      tag: 'create',
      metadata: {
        'entityType': entityType,
        'entityId': entityId
      },
    );
  }

  @override
  Future<void> logUpdate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  }) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      dataJson: jsonEncode(data),
      isFileToUpload: isFileToUpload,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity updated: $entityType [$entityId]',
      category: 'sync_logger',
      tag: 'update',
      metadata: {
        'entityType': entityType,
        'entityId': entityId
      },
    );
  }

  @override
  Future<void> logDelete({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      dataJson: jsonEncode(data),
      isFileToUpload: false,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity deleted: $entityType [$entityId]',
      category: 'sync_logger',
      tag: 'delete',
      metadata: {
        'entityType': entityType,
        'entityId': entityId
      },
    );
  }

  @override
  Future<void> logCustomOperation({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  }) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      dataJson: jsonEncode(data),
      isFileToUpload: isFileToUpload,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Custom operation: $operation for $entityType [$entityId]',
      category: 'sync_logger',
      tag: 'custom',
      metadata: {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation.value
      },
    );
  }

  @override
  Future<void> logBatch({
    required String entityType,
    required List<String> entityIds,
    required List<Map<String, dynamic>> dataList,
    required SyncOperation operation,
    bool isFileToUpload = false,
  }) async {
    for (int i = 0; i < entityIds.length; i++) {
      final log = SyncLog(
        syncId: const Uuid().v4(),
        entityType: entityType,
        entityId: entityIds[i],
        operation: operation,
        dataJson: jsonEncode(dataList[i]),
        isFileToUpload: isFileToUpload,
        isSynced: false,
        retryCount: 0,
        createdAt: DateTime.now(),
      );
      await _logStorage.createLog(log);
    }

    _loggerDebugProvider?.info(
      'Batch of ${entityIds.length} logs registered - ${operation.value}',
      category: 'sync_logger',
      tag: 'batch',
      metadata: {
        'count': entityIds.length,
        'operation': operation.value,
        'isFileToUpload': isFileToUpload,
      },
    );
  }

  @override
  Future<List<SyncLog>> getPendingLogs() async {
    return await _logStorage.getPendingLogs();
  }

  @override
  Future<void> clearAllLogs() async {
    await _logStorage.clearAllLogs();

    _loggerDebugProvider?.info(
      'All sync logs cleared',
      category: 'sync_logger',
      tag: 'clear',
    );
  }

  @override
  Future<List<SyncLog>> getAllLogs() async {
    return await _logStorage.getAllLogs();
  }

  @override
  Future<void> incrementRetryCount(String id) async {
    await _logStorage.incrementRetryCount(id);

    _loggerDebugProvider?.warning(
      'Retry count incremented for log: $id',
      category: 'sync_logger',
      tag: 'retry',
      metadata: {'logId': id},
    );
  }

  @override
  Future<void> removeLog(String id) async {
    await _logStorage.removeLog(id);

    _loggerDebugProvider?.info(
      'Log removed: $id',
      category: 'sync_logger',
      tag: 'remove',
      metadata: {'logId': id},
    );
  }

  @override
  Future<void> setLastError(String id, String error) async {
    await _logStorage.setLastError(id, error);

    _loggerDebugProvider?.error(
      'Error set for log: $id',
      category: 'sync_logger',
      tag: 'error',
      metadata: {
        'logId': id,
        'error': error,
      },
    );
  }
}
