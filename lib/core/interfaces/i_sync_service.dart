import '../entities/sync_data.dart';
import '../enums/sync_operation.dart';
import 'package:flutter/foundation.dart';

/// Interface para o serviço de sincronização
///
/// Define os contratos para sincronização de dados entre o app e o servidor.
/// Gerencia o estado de conectividade, fila de sincronização e recuperação de erros.
abstract class ISyncService {
  ValueNotifier<SyncData> get syncData;
  ValueNotifier<bool> get isOnline;
  Future<void> startSync();
  Future<void> stopSync();
  Future<void> forceSync();
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  
  // ========== LOGGING DE SINCRONIZAÇÃO ==========
  
  /// Registra log de criação de entidade
  Future<void> logCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  
  /// Registra log de atualização de entidade
  Future<void> logUpdate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  
  /// Registra log de exclusão de entidade
  Future<void> logDelete({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  });
  
  /// Registra operação customizada
  Future<void> logCustomOperation({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  });
  
  Future<int> getPendingItemsCount();
  Future<void> enterOfflineMode();
  Future<void> clearCorruptedData();
  Future<void> resetSyncState();
  Future<bool> canContinueWithoutSync();
  Future<void> startBackgroundSync();
  Future<void> stopBackgroundSync();
  Future<bool> isBackgroundSyncActive();
  Future<void> triggerImmediateBackgroundSync();
  void dispose();
}
