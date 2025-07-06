import '../entities/sync_log.dart';

import '../enums/sync_operation.dart';

/// Interface para logging automático de sincronização
///
/// Este serviço é responsável apenas por registrar logs de sincronização
/// após operações bem-sucedidas no banco de dados local.
abstract class ILoggerProvider {
  Future<void> logCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  Future<void> logUpdate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  Future<void> logDelete({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  });
  Future<void> logCustomOperation({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  Future<void> logBatch({
    required String entityType,
    required List<String> entityIds,
    required List<Map<String, dynamic>> dataList,
    required SyncOperation operation,
    bool isFileToUpload = false,
  });
  Future<List<SyncLog>> getPendingLogs();
  Future<void> removeLog(String id);
  Future<void> incrementRetryCount(String id);
  Future<void> setLastError(String id, String error);
  Future<List<SyncLog>> getAllLogs();
  Future<void> clearAllLogs();
}
