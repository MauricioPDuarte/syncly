import '../entities/sync_log.dart';

import '../contracts/sync_model_syncable.dart';
import '../enums/sync_operation.dart';

/// Interface para logging automático de sincronização
///
/// Este serviço é responsável apenas por registrar logs de sincronização
/// após operações bem-sucedidas no banco de dados local.
abstract class ILoggerProvider {
  Future<void> logCreate<T extends SyncModelSyncable>(T entity);
  Future<void> logUpdate<T extends SyncModelSyncable>(T entity);
  Future<void> logDelete<T extends SyncModelSyncable>(T entity);
  Future<void> logCustomOperation({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  Future<void> logBatch<T extends SyncModelSyncable>(
    List<T> entities,
    SyncOperation operation,
  );
  Future<List<SyncLog>> getPendingLogs();
  Future<void> removeLog(String id);
  Future<void> incrementRetryCount(String id);
  Future<void> setLastError(String id, String error);
  Future<List<SyncLog>> getAllLogs();
  Future<void> clearAllLogs();
}
