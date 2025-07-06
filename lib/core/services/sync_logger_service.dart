import '../entities/sync_log.dart';

import '../interfaces/i_sync_log_manager.dart';
import '../enums/sync_operation.dart';
import '../interfaces/i_logger_debug_provider.dart';
import '../interfaces/i_logger_provider.dart';
import '../contracts/sync_model_syncable.dart';
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
  Future<void> logCreate<T extends SyncModelSyncable>(T entity) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entity.runtimeType.toString(),
      entityId: entity.id,
      operation: SyncOperation.create,
      dataJson: jsonEncode(entity.toJson()),
      isFileToUpload: entity.isMediaEntity,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity created: ${entity.runtimeType} [${entity.id}]',
      category: 'sync_logger',
      tag: 'create',
      metadata: {
        'entityType': entity.runtimeType.toString(),
        'entityId': entity.id
      },
    );
  }

  @override
  Future<void> logUpdate<T extends SyncModelSyncable>(T entity) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entity.runtimeType.toString(),
      entityId: entity.id,
      operation: SyncOperation.update,
      dataJson: jsonEncode(entity.toJson()),
      isFileToUpload: entity.isMediaEntity,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity updated: ${entity.runtimeType} [${entity.id}]',
      category: 'sync_logger',
      tag: 'update',
      metadata: {
        'entityType': entity.runtimeType.toString(),
        'entityId': entity.id
      },
    );
  }

  @override
  Future<void> logDelete<T extends SyncModelSyncable>(T entity) async {
    final log = SyncLog(
      syncId: const Uuid().v4(),
      entityType: entity.runtimeType.toString(),
      entityId: entity.id,
      operation: SyncOperation.delete,
      dataJson: jsonEncode(entity.toJson()),
      isFileToUpload: entity.isMediaEntity,
      isSynced: false,
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await _logStorage.createLog(log);

    _loggerDebugProvider?.info(
      'Entity deleted: ${entity.runtimeType} [${entity.id}]',
      category: 'sync_logger',
      tag: 'delete',
      metadata: {
        'entityType': entity.runtimeType.toString(),
        'entityId': entity.id
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
  Future<void> logBatch<T extends SyncModelSyncable>(
    List<T> entities,
    SyncOperation operation, {
    bool isFileToUpload = false,
  }) async {
    for (final entity in entities) {
      final log = SyncLog(
        syncId: const Uuid().v4(),
        entityType: entity.runtimeType.toString(),
        entityId: entity.id,
        operation: operation,
        dataJson: jsonEncode(entity.toJson()),
        isFileToUpload: isFileToUpload,
        isSynced: false,
        retryCount: 0,
        createdAt: DateTime.now(),
      );
      await _logStorage.createLog(log);
    }

    _loggerDebugProvider?.info(
      'Batch of ${entities.length} logs registered - ${operation.value}',
      category: 'sync_logger',
      tag: 'batch',
      metadata: {
        'count': entities.length,
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
