import 'dart:async';

import 'core/interfaces/i_logger_provider.dart';
import 'package:flutter/foundation.dart';

import 'background_sync_service.dart';
import 'core/config/sync_constants.dart';
import 'sync_configurator.dart';
import 'core/entities/sync_data.dart';
import 'core/enums/sync_operation.dart';
import 'core/enums/sync_status.dart';
import 'core/interfaces/i_sync_service.dart';
import 'core/services/sync_connectivity_service.dart';
import 'core/services/sync_error_manager.dart';
import 'core/services/sync_error_reporter.dart';
import 'core/utils/sync_utils.dart';
import 'strategies/sync_download_strategy.dart';
import 'strategies/sync_upload_strategy.dart';

/// {@template sync_service}
/// Gerencia todo o ciclo de vida da sincronização de dados, incluindo operações
/// automáticas em background, tratamento de falhas, modo offline e
/// recuperação de erros.
/// {@endtemplate}
class SyncService implements ISyncService {
  // --- Injeção de Dependências ---
  final ISyncConnectivityService _connectivityService;
  final ILoggerProvider _syncLogger;
  final ISyncErrorManager _errorManager;
  final ISyncErrorReporter _errorReporter;

  // --- Estratégias de Sincronização ---
  late final SyncDownloadStrategy _downloadStrategy;
  late final SyncUploadStrategy _uploadStrategy;

  // --- Notificadores de Estado Público ---
  @override
  final ValueNotifier<SyncData> syncData = ValueNotifier(
    const SyncData(status: SyncStatus.idle),
  );

  @override
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  // --- Controle Interno de Estado ---
  Timer? _syncTimer;
  Timer? _recoveryTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  int _consecutiveFailures = 0;
  bool _isInOfflineMode = false;
  bool _isDisposed = false;

  /// Mutex para garantir que apenas uma operação de sincronização ocorra por vez.
  Completer<void>? _currentSyncOperation;

  /// Getter para verificar se uma sincronização já está em andamento.
  bool get _isSyncInProgress =>
      _currentSyncOperation != null && !_currentSyncOperation!.isCompleted;

  // --- Construtor e Inicialização ---

  /// {@macro sync_service}
  SyncService(
    this._connectivityService,
    this._syncLogger,
    this._errorManager,
    this._errorReporter,
  ) {
    _downloadStrategy = SyncDownloadStrategy();

    _uploadStrategy = SyncUploadStrategy(
      _syncLogger,
      _errorManager,
    );

    SyncUtils.debugLog(
        'SyncService inicializado - syncInterval: ${SyncConstants.syncInterval.inSeconds}s, initialDelay: ${SyncConstants.initialSyncDelay.inSeconds}s, recoveryTimeout: ${SyncConstants.recoveryTimeout.inSeconds}s',
        tag: 'SyncService');

    _initConnectivityListener();
    _checkInitialConnectivity();
  }

  // #######################################################################
  // #                    IMPLEMENTAÇÃO DA API PÚBLICA                     #
  // #######################################################################

  @override
  Future<void> startSync() async {
    if (!isOnline.value) {
      _updateSyncStatus(SyncStatus.offline, 'Sem conexão com a internet');
      return;
    }

    await Future.delayed(SyncConstants.initialSyncDelay);
    await forceSync(isManualCall: false);
  }

  @override
  Future<void> stopSync() async {
    _stopSyncTimer();
    _updateSyncStatus(SyncStatus.idle, 'Sincronização pausada');
  }

  @override
  Future<void> forceSync({bool isManualCall = true}) async {
    if (_isDisposed) {
      _log('warning', 'ForceSync ignorado: serviço foi disposed');
      return;
    }

    _log('info', 'ForceSync chamado', metadata: {
      'isManualCall': isManualCall,
      'status': syncData.value.status.name
    });

    if (!isOnline.value && !_isInOfflineMode) {
      _updateSyncStatus(SyncStatus.offline, 'Sem conexão com a internet');
      return;
    }

    if (isManualCall) {
      _handleManualSyncRequest();
    }

    if (isManualCall) {
      _updateSyncStatus(SyncStatus.syncing, 'Iniciando sincronização...');
      unawaited(_executeSyncSafely(isManualCall: true));
    } else {
      await _executeSyncSafely(isManualCall: false);
    }
  }

  @override
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
    bool isFileToUpload = false,
  }) async {
    await _syncLogger.logCustomOperation(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      isFileToUpload: isFileToUpload,
    );
    await _updatePendingItemsCount();
    _log('info', 'Item adicionado à fila de sync: $entityType/$operation',
        metadata: {'isFile': isFileToUpload});
  }

  @override
  Future<int> getPendingItemsCount() async {
    final pendingLogs = await _syncLogger.getPendingLogs();
    return pendingLogs.length;
  }

  // --- Métodos de Gerenciamento Avançado ---

  @override
  Future<void> enterOfflineMode() async {
    await _enterOfflineMode(
        'Modo offline ativado. O app continuará funcionando com dados locais.');
  }

  @override
  Future<void> clearCorruptedData() async {
    _log('info', 'Limpeza manual de dados corrompidos solicitada');
    try {
      await _clearPotentiallyCorruptedData();
      _updateSyncStatus(
        SyncStatus.idle,
        'Dados corrompidos removidos. Tente sincronizar novamente.',
      );
    } catch (e, s) {
      _log('error', 'Erro ao limpar dados corrompidos',
          error: e, stackTrace: s);
      _updateSyncStatus(SyncStatus.error, 'Erro ao limpar dados: $e');
    }
  }

  @override
  Future<void> resetSyncState() async {
    _log('warning', 'Reset completo do estado de sincronização solicitado');
    try {
      _stopAllTimers();
      _consecutiveFailures = 0;
      _isInOfflineMode = false;
      _currentSyncOperation = null;

      await _syncLogger.clearAllLogs();
      _updateSyncStatus(
        SyncStatus.idle,
        'Estado de sincronização resetado.',
        pendingItems: 0,
      );

      if (isOnline.value) {
        _scheduleSync();
      }
    } catch (e, s) {
      _log('error', 'Erro ao resetar estado de sync', error: e, stackTrace: s);
      _updateSyncStatus(SyncStatus.error, 'Erro ao resetar estado: $e');
    }
  }

  @override
  Future<bool> canContinueWithoutSync() {
    return SyncUtils.canContinueWithoutSync();
  }

  // --- Gerenciamento de Background Sync ---

  @override
  Future<void> startBackgroundSync() async {
    try {
      await BackgroundSyncService.initialize();
      await BackgroundSyncService.startBackgroundSync();
      _log('info', 'Sincronização em background iniciada');
    } catch (e, s) {
      _log('error', 'Erro ao iniciar sync em background',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> stopBackgroundSync() async {
    try {
      await BackgroundSyncService.stopBackgroundSync();
      _log('info', 'Sincronização em background parada');
    } catch (e, s) {
      _log('error', 'Erro ao parar sync em background',
          error: e, stackTrace: s);
    }
  }

  @override
  Future<bool> isBackgroundSyncActive() {
    return BackgroundSyncService.isBackgroundSyncActive();
  }

  @override
  Future<void> triggerImmediateBackgroundSync() async {
    try {
      await BackgroundSyncService.triggerImmediateSync();
      _log('info', 'Sincronização imediata em background disparada');
    } catch (e, s) {
      _log('error', 'Erro ao disparar sync imediato', error: e, stackTrace: s);
    }
  }

  // #######################################################################
  // #                   LÓGICA PRINCIPAL DE SINCRONIZAÇÃO                 #
  // #######################################################################

  Future<void> _executeSyncSafely({required bool isManualCall}) async {
    try {
      _recoveryTimer?.cancel();

      final syncConfig = SyncConfigurator.provider;
      if (syncConfig != null && !await syncConfig.isAuthenticated()) {
        _log('warning', 'Usuário não autenticado, sincronização cancelada.');
        _updateSyncStatus(
          SyncStatus.idle,
          'Sincronização pausada - autenticação necessária',
        );
        return;
      }

      final executed = await _executeSyncWithMutex(isManualCall);

      if (executed && syncData.value.status == SyncStatus.success) {
        _log('info', 'Sincronização bem-sucedida. Reativando sync automático.');
        _scheduleSync();
      }
    } catch (e, s) {
      _log('error', 'Erro durante a execução segura da sincronização',
          error: e, stackTrace: s);
      await _handleSyncFailure(e, s);
    }
  }

  Future<bool> _executeSyncWithMutex(bool isManualCall) async {
    if (_isSyncInProgress) {
      _log('info', 'Sincronização ignorada: operação já em andamento.');
      return false;
    }

    _currentSyncOperation = Completer<void>();

    try {
      await _performSyncInternal(isManualCall: isManualCall);
      if (!_currentSyncOperation!.isCompleted) {
        _currentSyncOperation!.complete();
      }
      return true;
    } catch (e, s) {
      if (!_currentSyncOperation!.isCompleted) {
        _currentSyncOperation!.completeError(e, s);
      }
      rethrow;
    } finally {
      _currentSyncOperation = null;
    }
  }

  Future<void> _performSyncInternal({required bool isManualCall}) async {
    if (_isInOfflineMode && !isManualCall) {
      _log('info', 'Sync pulado: sistema em modo offline forçado.');
      _updateSyncStatus(
        SyncStatus.degraded,
        'Funcionando em modo offline.',
      );
      return;
    }

    _updateSyncStatus(SyncStatus.syncing, 'Sincronizando dados...');
    _log('info', 'Iniciando sincronização interna',
        metadata: {'isManualCall': isManualCall});

    final initialPendingCount = await getPendingItemsCount();
    final syncConfig = SyncConfigurator.provider;
    if (initialPendingCount > 0 && syncConfig?.enableNotifications == true) {
      await syncConfig!.showProgressNotification(
        title: 'Sincronizando',
        message: 'Sincronizando $initialPendingCount itens...',
        progress: 0,
        maxProgress: 100,
        notificationId: 1001,
      );
    }

    try {
      _log('info', 'Iniciando fase de upload.');
      await _uploadStrategy.syncUploadData();

      _log('info', 'Iniciando fase de download.');
      await _downloadStrategy.fetchDataFromServer();

      await _handleSyncSuccess(initialPendingCount);
    } catch (e, s) {
      _log('error', 'Erro durante a sincronização interna',
          error: e, stackTrace: s);
      _consecutiveFailures++;

      if (syncConfig?.enableNotifications == true) {
        await syncConfig!.showNotification(
          title: 'Erro na Sincronização',
          message:
              'Não foi possível sincronizar os dados. Tentativa $_consecutiveFailures.',
          channelId: 'sync_result',
          notificationId: 1002,
        );
      }

      await _saveGlobalErrorLog(
          error: e,
          stackTrace: s,
          context: {'operation': 'performSyncInternal'});
      rethrow;
    }
  }

  // #######################################################################
  // #                   TRATAMENTO DE ESTADO E FALHAS                     #
  // #######################################################################

  Future<void> _handleSyncFailure(dynamic error, StackTrace stackTrace) async {
    _log('warning', 'Tratando falha de sincronização #$_consecutiveFailures',
        error: error, stackTrace: stackTrace);

    if (SyncUtils.hasReachedAbsoluteFailureLimit(_consecutiveFailures)) {
      _log('error', 'Limite absoluto de falhas atingido. Parando tentativas.');
      _updateSyncStatus(SyncStatus.error,
          'Muitas falhas. Sincronização automática desabilitada.');
      return;
    }

    await _reportCriticalErrorIfNeeded();
    final isNetworkError = SyncUtils.isNetworkError(error);

    if (isNetworkError &&
        SyncUtils.shouldEnterRecoveryMode(
            _consecutiveFailures, isNetworkError)) {
      await _enterTemporaryOfflineMode();
    } else if (SyncUtils.shouldEnterRecoveryMode(
        _consecutiveFailures, isNetworkError)) {
      await _initiateRecoveryProcess(error.toString());
    } else {
      _scheduleRecoveryAttempt();
      _updateSyncStatus(
        SyncStatus.degraded,
        SyncUtils.generateStatusMessage(
            _consecutiveFailures, SyncConstants.maxAbsoluteFailures),
      );
    }
  }

  void _handleManualSyncRequest() {
    _log('info', 'Resetando estado para sync manual.');
    if (_isInOfflineMode ||
        syncData.value.status == SyncStatus.recovery ||
        _consecutiveFailures >= SyncConstants.maxAbsoluteFailures) {
      _consecutiveFailures = 0;
      _isInOfflineMode = false;
      _recoveryTimer?.cancel();
      _updateSyncStatus(SyncStatus.idle, 'Iniciando sincronização manual...');
    }
  }

  Future<void> _handleSyncSuccess(int initialPendingCount) async {
    _consecutiveFailures = 0;
    await _updatePendingItemsCount();

    final finalPendingCount = syncData.value.pendingItems ?? 0;

    _updateSyncStatus(
      SyncStatus.success,
      'Dados sincronizados com sucesso',
      lastSync: DateTime.now(),
    );

    _log('info', 'Sincronização concluída com sucesso.', metadata: {
      'itemsSynced': initialPendingCount - finalPendingCount,
      'pendingItems': finalPendingCount
    });

    final syncConfig = SyncConfigurator.provider;
    if (initialPendingCount > 0 && syncConfig?.enableNotifications == true) {
      await syncConfig!.showNotification(
        title: 'Sincronização Concluída',
        message: 'Todos os seus dados estão atualizados.',
        channelId: 'sync_result',
        notificationId: 1003,
      );
    }
  }

  Future<void> _initiateRecoveryProcess(String reason) async {
    _log('warning', 'Entrando em modo de recuperação',
        metadata: {'reason': reason});
    _updateSyncStatus(
        SyncStatus.recovery, 'Tentando recuperação automática...');

    try {
      await _clearPotentiallyCorruptedData();
      _log('info', 'Limpeza de dados para recuperação concluída.');
      _updateSyncStatus(SyncStatus.degraded,
          'Recuperação concluída. Tentando sincronizar...');
      _scheduleRecoveryAttempt();
    } catch (e, s) {
      _log('error', 'Falha crítica na recuperação', error: e, stackTrace: s);
      await _enterOfflineMode('Falha na recuperação. Verifique sua conexão.');
    }
  }

  Future<void> _enterTemporaryOfflineMode() async {
    _log('warning',
        'Muitas falhas de rede. Entrando em modo offline temporário.');
    await enterOfflineMode();
    _scheduleReconnectionAttempt();
  }

  Future<void> _enterOfflineMode(String reason) async {
    _log('info', 'Entrando em modo offline', metadata: {'reason': reason});
    _isInOfflineMode = true;
    _stopAllTimers();
    _updateSyncStatus(SyncStatus.degraded, reason);
    _scheduleReconnectionAttempt();
  }

  Future<void> _exitOfflineMode() async {
    _log('info', 'Saindo do modo offline.');
    _isInOfflineMode = false;
    _updateSyncStatus(
        SyncStatus.idle, 'Reconectado. Sincronização será retomada.');
    if (!_isSyncInProgress) {
      await forceSync(isManualCall: false);
    } else {
      _scheduleSync();
    }
  }

  // #######################################################################
  // #                        AGENDAMENTO E TIMERS                         #
  // #######################################################################

  void _scheduleSync() {
    _stopSyncTimer();
    if (!isOnline.value) return;

    _syncTimer = Timer.periodic(SyncConstants.syncInterval, (_) {
      if (isOnline.value && !_isSyncInProgress) {
        _executeSyncSafely(isManualCall: false);
      }
    });
  }

  void _scheduleRecoveryAttempt() {
    _recoveryTimer?.cancel();
    final delay =
        Duration(seconds: SyncUtils.calculateRetryDelay(_consecutiveFailures));
    _log('info', 'Agendando próxima tentativa de sync em ${delay.inSeconds}s');

    _recoveryTimer = Timer(delay, () {
      if (_isDisposed ||
          !isOnline.value ||
          _isInOfflineMode ||
          _isSyncInProgress) {
        _log('info', 'Tentativa de recuperação cancelada', metadata: {
          'disposed': _isDisposed,
          'online': isOnline.value,
          'offlineMode': _isInOfflineMode,
          'syncInProgress': _isSyncInProgress
        });
        return;
      }
      _log('info', 'Executando tentativa de recuperação automática.');
      forceSync(isManualCall: false);
    });
  }

  void _scheduleReconnectionAttempt() {
    _recoveryTimer?.cancel();
    _log('info',
        'Agendando verificação de reconexão em ${SyncConstants.recoveryTimeout.inMinutes} min');

    _recoveryTimer = Timer(SyncConstants.recoveryTimeout, () async {
      if (_isDisposed) return;
      if (await _connectivityService.isConnected()) {
        _log('info', 'Conexão detectada. Tentando sair do modo offline.');
        await _exitOfflineMode();
      } else {
        _log('info', 'Ainda sem conexão. Reagendando verificação.');
        _scheduleReconnectionAttempt();
      }
    });
  }

  void _stopSyncTimer() => _syncTimer?.cancel();
  void _stopAllTimers() {
    _syncTimer?.cancel();
    _recoveryTimer?.cancel();
  }

  // #######################################################################
  // #                    CONECTIVIDADE E UTILITÁRIOS                      #
  // #######################################################################

  void _initConnectivityListener() {
    _connectivitySubscription =
        _connectivityService.isConnectedStream.listen((isConnected) {
      if (_isDisposed) return;

      final wasOnline = isOnline.value;
      isOnline.value = isConnected;
      _log('info',
          'Conectividade alterada: ${isConnected ? "Online" : "Offline"}');

      if (isConnected && !wasOnline) {
        _updatePendingItemsCount();
        if (_consecutiveFailures < SyncConstants.maxRetryAttempts) {
          _updateSyncStatus(SyncStatus.idle, 'Conexão restaurada');
          forceSync(isManualCall: false);
        } else {
          _updateSyncStatus(SyncStatus.error,
              'Conexão restaurada. Toque para tentar novamente.');
        }
      } else if (!isConnected) {
        _updatePendingItemsCount();
        _updateSyncStatus(SyncStatus.offline, 'Sem conexão com a internet');
        _stopAllTimers();
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      isOnline.value = await _connectivityService.isConnected();
      if (!isOnline.value) {
        _updateSyncStatus(SyncStatus.offline, 'Sem conexão com a internet');
      }
    } catch (e, s) {
      _log('error', 'Erro ao verificar conectividade inicial',
          error: e, stackTrace: s);
    }
  }

  // FIX 1: Logic moved back here from the non-existent method in ISyncDataCleanupService.
  Future<void> _clearPotentiallyCorruptedData() async {
    _log('info', 'Iniciando limpeza de dados potencialmente corrompidos.');
    try {
      final allLogs = await _syncLogger.getAllLogs();

      // Remove logs too old
      final oldLogs = allLogs
          .where((log) => !SyncUtils.isWithinOfflineTimeout(log.createdAt))
          .toList();
      for (final log in oldLogs) {
        await _syncLogger.removeLog(log.syncId);
      }

      // Remove logs with too many retries
      final problematicLogs =
          allLogs.where((log) => log.retryCount >= 5).toList();
      for (final log in problematicLogs) {
        await _syncLogger.removeLog(log.syncId);
        _log('info', 'Removido log problemático', metadata: {
          'entityType': log.entityType,
          'operation': log.operation,
          'syncId': log.syncId
        });
      }
    } catch (e, s) {
      _log('error', 'Erro durante a limpeza de dados', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _reportCriticalErrorIfNeeded() async {
    if (_consecutiveFailures >= SyncConstants.maxRetryAttempts) {
      try {
        await _errorReporter.scheduleErrorReporting();
        _log('info', 'Relatório de erro crítico agendado para envio.');
      } catch (e, s) {
        _log('warning', 'Falha ao agendar relatório de erro',
            error: e, stackTrace: s);
      }
    }
  }

  // FIX 2: Correctly handle stackTrace as an object and convert it to a string for the context map.
  Future<void> _saveGlobalErrorLog({
    required dynamic error,
    StackTrace? stackTrace,
    required Map<String, dynamic> context,
  }) {
    final newContext = {...context};
    if (stackTrace != null) {
      newContext['stackTrace'] = stackTrace.toString();
    }
    return SyncUtils.saveGlobalErrorLog(
      error: error,
      context: newContext,
      errorManager: _errorManager,
    );
  }

  void _updateSyncStatus(
    SyncStatus status,
    String? message, {
    DateTime? lastSync,
    int? pendingItems,
  }) {
    syncData.value = syncData.value.copyWith(
      status: status,
      message: message,
      lastSync: lastSync,
      pendingItems: pendingItems,
    );
  }

  Future<void> _updatePendingItemsCount() async {
    final count = await getPendingItemsCount();
    syncData.value = syncData.value.copyWith(pendingItems: count);
  }

  // FIX 2: Correctly handle stackTrace and error objects for logging.
  void _log(String level, String message,
      {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    // Prepare metadata with error and stacktrace strings if they exist
    final Map<String, dynamic> fullMetadata = {...?metadata};
    if (error != null) {
      fullMetadata['error'] = error.toString();
    }
    if (stackTrace != null) {
      fullMetadata['stackTrace'] = stackTrace.toString();
    }

    final metadataStr =
        fullMetadata.isNotEmpty ? ' - ${fullMetadata.toString()}' : '';
    SyncUtils.debugLog('[$level] $message$metadataStr', tag: 'SyncService');
  }

  // #######################################################################
  // #                            DISPOSE                                  #
  // #######################################################################

  @override
  void dispose() {
    _log('info', 'Disposing SyncService...');
    _isDisposed = true;
    _stopAllTimers();
    _connectivitySubscription?.cancel();
    _currentSyncOperation = null;
    syncData.dispose();
    isOnline.dispose();
    _log('info', 'SyncService disposed.');
  }

  @override
  Future<void> logCreate(
      {required String entityType,
      required String entityId,
      required Map<String, dynamic> data,
      bool isFileToUpload = false}) async {
    try {
      await addToSyncQueue(
        entityType: entityType,
        entityId: entityId,
        operation: SyncOperation.create,
        data: data,
        isFileToUpload: isFileToUpload,
      );

      _log('info', 'Operação CREATE registrada para sincronização', metadata: {
        'entityType': entityType,
        'entityId': entityId,
        'isFileToUpload': isFileToUpload,
      });
    } catch (e) {
      _log('error', 'Erro ao registrar operação CREATE', error: e, metadata: {
        'entityType': entityType,
        'entityId': entityId,
      });
      rethrow;
    }
  }

  @override
  Future<void> logCustomOperation(
      {required String entityType,
      required String entityId,
      required SyncOperation operation,
      required Map<String, dynamic> data,
      bool isFileToUpload = false}) async {
    try {
      await addToSyncQueue(
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        data: data,
        isFileToUpload: isFileToUpload,
      );

      _log('info', 'Operação customizada registrada para sincronização',
          metadata: {
            'entityType': entityType,
            'entityId': entityId,
            'operation': operation.toString(),
            'isFileToUpload': isFileToUpload,
          });
    } catch (e) {
      _log('error', 'Erro ao registrar operação customizada',
          error: e,
          metadata: {
            'entityType': entityType,
            'entityId': entityId,
            'operation': operation.toString(),
          });
      rethrow;
    }
  }

  @override
  Future<void> logDelete(
      {required String entityType,
      required String entityId,
      required Map<String, dynamic> data}) async {
    try {
      await addToSyncQueue(
        entityType: entityType,
        entityId: entityId,
        operation: SyncOperation.delete,
        data: data,
      );

      _log('info', 'Operação DELETE registrada para sincronização', metadata: {
        'entityType': entityType,
        'entityId': entityId,
      });
    } catch (e) {
      _log('error', 'Erro ao registrar operação DELETE', error: e, metadata: {
        'entityType': entityType,
        'entityId': entityId,
      });
      rethrow;
    }
  }

  @override
  Future<void> logUpdate(
      {required String entityType,
      required String entityId,
      required Map<String, dynamic> data,
      bool isFileToUpload = false}) async {
    try {
      await addToSyncQueue(
        entityType: entityType,
        entityId: entityId,
        operation: SyncOperation.update,
        data: data,
        isFileToUpload: isFileToUpload,
      );

      _log('info', 'Operação UPDATE registrada para sincronização', metadata: {
        'entityType': entityType,
        'entityId': entityId,
        'isFileToUpload': isFileToUpload,
      });
    } catch (e) {
      _log('error', 'Erro ao registrar operação UPDATE', error: e, metadata: {
        'entityType': entityType,
        'entityId': entityId,
      });
      rethrow;
    }
  }
}
