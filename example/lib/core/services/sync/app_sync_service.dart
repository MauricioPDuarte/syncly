import 'package:flutter/material.dart';
import 'package:syncly_example/core/services/sync/app_sync_data.dart';

/// Interface abstrata para o serviço de sincronização da aplicação
abstract class AppSyncService {
  Future<void> forceSync();
  Future<void> stopSync();
  Future<void> stopBackgroundSync();
  Future<void> startSync();
  Future<void> startBackgroundSync();
  Future<void> resetSyncState();
  Future<void> logCreate(
      {required String entityType, required String entityId, required Map<String, dynamic> data});
  Future<void> logUpdate({
     required String entityType, required String entityId,  required Map<String, dynamic> data});
  Future<void> logDelete({required String entityType, required String entityId});
  Future<int> getPendingItemsCount();
  bool get isOnline;
  bool get isSyncing;
  ValueNotifier<AppSyncData> get syncData;
}
