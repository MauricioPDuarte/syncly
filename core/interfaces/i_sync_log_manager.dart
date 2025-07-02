import '../entities/sync_log.dart';

/// Interface para gerenciamento interno de logs de sincronização
///
/// Esta interface define os métodos necessários para o sistema de
/// sincronização gerenciar seus próprios logs de forma independente.
abstract class ISyncLogManager {
  /// Cria um novo log de sincronização
  Future<void> createLog(SyncLog log);

  /// Obtém todos os logs pendentes de sincronização
  Future<List<SyncLog>> getPendingLogs();

  /// Obtém logs com falha (que falharam em tentativas anteriores)
  Future<List<SyncLog>> getFailedLogs();

  /// Obtém todos os logs
  Future<List<SyncLog>> getAllLogs();

  /// Obtém logs por ID de sincronização
  Future<List<SyncLog>> getLogsBySyncId(String syncId);

  /// Obtém logs por tipo de entidade
  Future<List<SyncLog>> getLogsByEntityType(String entityType);

  /// Marca um log como sincronizado
  Future<void> markAsSynced(String syncId);

  /// Incrementa o contador de tentativas de um log
  Future<void> incrementRetryCount(String syncId);

  /// Define o último erro de um log
  Future<void> setLastError(String syncId, String error);

  /// Remove um log específico
  Future<void> removeLog(String syncId);

  /// Remove todos os logs
  Future<void> clearAllLogs();

  /// Remove logs sincronizados mais antigos que a data especificada
  Future<void> cleanupOldSyncedLogs(DateTime olderThan);

  /// Obtém estatísticas dos logs
  Future<Map<String, int>> getLogStatistics();
}
