import '../app_sync_service.dart';
import '../app_sync_data.dart';
import 'package:syncly/sync.dart';
import 'package:flutter/foundation.dart';

/// Implementação do serviço de sincronização da aplicação
///
/// Esta classe atua como um adapter entre a interface da aplicação
/// e o sistema de sincronização interno, fornecendo uma camada
/// de abstração limpa e desacoplada.
class SynclyService implements AppSyncService {
  ISyncService? _syncService;
  ValueNotifier<AppSyncData>? _appSyncData;
  bool _isInitialized = false;

  SynclyService();

  ISyncService get _service {
    if (!_isInitialized) {
      _syncService = ISyncService.getInstance();
      _appSyncData =
          ValueNotifier(_convertToAppSyncData(_syncService!.syncData.value));

      // Escutar mudanças no syncData original e converter para AppSyncData
      _syncService!.syncData.addListener(_onSyncDataChanged);
      _isInitialized = true;
    }
    return _syncService!;
  }

  void _onSyncDataChanged() {
    _appSyncData!.value = _convertToAppSyncData(_syncService!.syncData.value);
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
    return _service.forceSync();
  }

  @override
  Future<void> stopSync() {
    return _service.stopSync();
  }

  @override
  Future<void> stopBackgroundSync() {
    return _service.stopBackgroundSync();
  }

  @override
  Future<void> startSync() {
    return _service.startSync();
  }

  @override
  Future<void> startBackgroundSync() {
    return _service.startBackgroundSync();
  }

  @override
  bool get isOnline {
    return _service.isOnline.value;
  }

  @override
  bool get isSyncing {
    return _service.syncData.value.status.name == 'syncing';
  }

  @override
  ValueNotifier<AppSyncData> get syncData {
    return _appSyncData!;
  }

  @override
  Future<int> getPendingItemsCount() {
    return _service.getPendingItemsCount();
  }

  @override
  Future<void> resetSyncState() {
    return _service.resetSyncState();
  }

  @override
  Future<void> logCreate({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) {
    return _service.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.create,
      data: data,
    );
  }

  @override
  Future<void> logUpdate(
      {required String entityType,
      required String entityId,
      required Map<String, dynamic> data}) {
    return _service.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      data: data,
    );
  }

  @override
  Future<void> logDelete(
      {required String entityType, required String entityId}) {
    return _service.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      data: {},
    );
  }
}
