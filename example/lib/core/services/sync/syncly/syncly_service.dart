import '../app_sync_service.dart';
import '../app_sync_data.dart';
import 'package:syncly/sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Implementação do serviço de sincronização da aplicação
///
/// Esta classe atua como um adapter entre a interface da aplicação
/// e o sistema de sincronização interno, fornecendo uma camada
/// de abstração limpa e desacoplada.
class SynclyService implements AppSyncService {
  late final ISyncService _syncService;
  late final ValueNotifier<AppSyncData> _appSyncData;

  SynclyService() {
    _syncService = Modular.get<ISyncService>();
    _appSyncData = ValueNotifier(_convertToAppSyncData(_syncService.syncData.value));
    
    // Escutar mudanças no syncData original e converter para AppSyncData
    _syncService.syncData.addListener(_onSyncDataChanged);
  }

  void _onSyncDataChanged() {
    _appSyncData.value = _convertToAppSyncData(_syncService.syncData.value);
  }

  /// Converte SyncData para AppSyncData
  AppSyncData _convertToAppSyncData(SyncData syncData) {
    return AppSyncData(
      status: _convertSyncStatus(syncData.status),
      message: syncData.message,
      lastSync: syncData.lastSync,
      pendingItems: syncData.pendingItems,
    );
  }

  /// Converte SyncStatus para AppSyncStatus
  AppSyncStatus _convertSyncStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return AppSyncStatus.idle;
      case SyncStatus.syncing:
        return AppSyncStatus.syncing;
      case SyncStatus.success:
        return AppSyncStatus.success;
      case SyncStatus.error:
        return AppSyncStatus.error;
      case SyncStatus.offline:
        return AppSyncStatus.offline;
      case SyncStatus.degraded:
        return AppSyncStatus.degraded;
      case SyncStatus.recovery:
        return AppSyncStatus.recovery;
    }
  }

  @override
  Future<void> forceSync() {
    return _syncService.forceSync();
  }

  @override
  Future<void> stopSync() {
    return _syncService.stopSync();
  }

  @override
  Future<void> stopBackgroundSync() {
    return _syncService.stopBackgroundSync();
  }

  @override
  Future<void> startSync() {
    return _syncService.startSync();
  }

  @override
  Future<void> startBackgroundSync() {
    return _syncService.startBackgroundSync();
  }

  @override
  bool get isOnline {
    return _syncService.isOnline.value;
  }

  @override
  bool get isSyncing {
    return _syncService.syncData.value.status.name == 'syncing';
  }

  @override
  ValueNotifier<AppSyncData> get syncData {
    return _appSyncData;
  }

  @override
  Future<int> getPendingItemsCount() {
    return _syncService.getPendingItemsCount();
  }

  @override
  Future<void> resetSyncState() {
    return _syncService.resetSyncState();
  }

  @override
  Future<void> logCreate(String entityType, String entityId, Map<String, dynamic> data) {
    return _syncService.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.create,
      data: data,
    );
  }

  @override
  Future<void> logUpdate(String entityType, String entityId, Map<String, dynamic> data) {
    return _syncService.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      data: data,
    );
  }

  @override
  Future<void> logDelete(String entityType, String entityId) {
    return _syncService.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      data: {},
    );
  }

  @override
  void dispose() {
    _syncService.syncData.removeListener(_onSyncDataChanged);
    _appSyncData.dispose();
    _syncService.dispose();
  }
}
