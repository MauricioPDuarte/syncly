import '../enums/sync_operation.dart';

/// Modelo de dados para logs de sincronização
///
/// Representa um registro de operação que precisa ser sincronizada
/// com o servidor. Contém todas as informações necessárias para
/// rastrear o estado da sincronização e permitir retry em caso de falha.
class SyncLog {
  final String syncId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String dataJson;
  final bool isFileToUpload;
  final bool isSynced;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;

  const SyncLog({
    required this.syncId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.dataJson,
    required this.isFileToUpload,
    required this.isSynced,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    this.lastAttemptAt,
    this.syncedAt,
  });

  SyncLog copyWith({
    String? syncId,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    String? dataJson,
    bool? isFileToUpload,
    bool? isSynced,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    DateTime? syncedAt,
  }) {
    return SyncLog(
      syncId: syncId ?? this.syncId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      dataJson: dataJson ?? this.dataJson,
      isFileToUpload: isFileToUpload ?? this.isFileToUpload,
      isSynced: isSynced ?? this.isSynced,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncLog && other.syncId == syncId;
  }

  @override
  int get hashCode => syncId.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'syncId': syncId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.value,
      'dataJson': dataJson,
      'isFileToUpload': isFileToUpload,
      'isSynced': isSynced,
      'retryCount': retryCount,
      'lastError': lastError,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SyncLog(syncId: $syncId, entityType: $entityType, entityId: $entityId, operation: $operation, isSynced: $isSynced)';
  }
}
