import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'core/interfaces/i_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'sync_service.dart';
import 'sync_configurator.dart';
import 'core/enums/sync_status.dart';
import 'core/config/sync_constants.dart';
import 'sync_config.dart';
import 'core/utils/sync_utils.dart';
import 'core/services/sync_notification_service.dart';

class BackgroundSyncService {
  static bool _isInitialized = false;

  /// Obtém o SyncConfig via SyncConfigurator
  static SyncConfig? _getSyncConfig() {
    return SyncConfigurator.provider;
  }

  /// Inicializa o serviço de sincronização em background
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // As notificações são agora gerenciadas internamente pelo Syncly
      // através do SyncNotificationService

      _isInitialized = true;
      SyncUtils.debugLog('BackgroundSyncService inicializado com sucesso', tag: 'BackgroundSyncService');
    } catch (e) {
      SyncUtils.debugLog('Erro ao inicializar BackgroundSyncService: $e', tag: 'BackgroundSyncService');
      rethrow;
    }
  }

  /// Inicia a sincronização em background
  static Future<void> startBackgroundSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Workmanager().cancelByUniqueName(SyncConstants.backgroundSyncTaskName);

      //  Registrar nova tarefa periódica
      await Workmanager().registerPeriodicTask(
        SyncConstants.backgroundSyncTaskName,
      SyncConstants.backgroundSyncTaskName,
      frequency: SyncConstants.backgroundSyncFrequency,
      initialDelay: SyncConstants.backgroundSyncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      _isInitialized = true;
      SyncUtils.debugLog('Sincronização em background iniciada', tag: 'BackgroundSyncService');
    } catch (e) {
      SyncUtils.debugLog('Erro ao iniciar sincronização em background: $e', tag: 'BackgroundSyncService');
      rethrow;
    }
  }

  /// Para a sincronização em background
  static Future<void> stopBackgroundSync() async {
    try {
      await Workmanager().cancelByUniqueName(SyncConstants.backgroundSyncTaskName);
      await _dismissAllNotifications();
      SyncUtils.debugLog('Sincronização em background parada', tag: 'BackgroundSyncService');
    } catch (e) {
      SyncUtils.debugLog('Erro ao parar sincronização em background: $e', tag: 'BackgroundSyncService');
    }
  }

  /// Exibe uma notificação de progresso da sincronização
  static Future<void> showSyncProgressNotification({
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
    bool indeterminate = false,
  }) async {
    try {
      final syncConfig = _getSyncConfig();
      if (syncConfig == null || !syncConfig.enableNotifications) {
        return;
      }

      if (indeterminate || (progress == null || maxProgress == null)) {
        await SyncNotificationService.instance.showNotification(
          title: title,
          message: body,
          notificationId: SyncConstants.progressNotificationId,
        );
      } else {
        await SyncNotificationService.instance.showProgressNotification(
          title: title,
          message: body,
          progress: progress,
          maxProgress: maxProgress,
          notificationId: SyncConstants.progressNotificationId,
        );
      }
    } catch (e) {
      SyncUtils.debugLog('Erro ao exibir notificação de progresso: $e', tag: 'BackgroundSyncService');
    }
  }

  /// Mostra notificação de resultado da sincronização
  static Future<void> showSyncResultNotification({
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    try {
      final syncConfig = _getSyncConfig();
      if (syncConfig == null || !syncConfig.enableNotifications) {
        return;
      }

      await SyncNotificationService.instance.showNotification(
        title: title,
        message: body,
        notificationId: SyncConstants.syncNotificationId,
      );
    } catch (e) {
      SyncUtils.debugLog('Erro ao mostrar notificação de resultado: $e', tag: 'BackgroundSyncService');
    }
  }

  /// Remove todas as notificações de sincronização
  static Future<void> _dismissAllNotifications() async {
    try {
      final syncConfig = _getSyncConfig();
      if (syncConfig != null && syncConfig.enableNotifications) {
        await SyncNotificationService.instance.cancelNotification(SyncConstants.syncNotificationId);
        await SyncNotificationService.instance.cancelNotification(SyncConstants.progressNotificationId);
      }
    } catch (e) {
      SyncUtils.debugLog('Erro ao remover notificações: $e', tag: 'BackgroundSyncService');
    }
  }

  /// Verifica se a sincronização em background está ativa
  static Future<bool> isBackgroundSyncActive() async {
    try {
      // Não há uma forma direta de verificar se uma tarefa específica está ativa
      // no WorkManager, então assumimos que está ativa se foi iniciada
      return _isInitialized;
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar status da sincronização em background: $e', tag: 'BackgroundSyncService');
      return false;
    }
  }

  /// Força uma sincronização imediata em background
  static Future<void> triggerImmediateSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Workmanager().registerOneOffTask(
        'immediate_sync',
        SyncConstants.backgroundSyncTaskName,
        initialDelay: const Duration(seconds: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      SyncUtils.debugLog('Sincronização imediata em background disparada', tag: 'BackgroundSyncService');
    } catch (e) {
      SyncUtils.debugLog('Erro ao disparar sincronização imediata: $e', tag: 'BackgroundSyncService');
    }
  }
}

/// Callback dispatcher para o WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    SyncUtils.debugLog('Executando tarefa em background: $task', tag: 'BackgroundSyncService');

    switch (task) {
      case 'background_sync_task':
      case 'immediate_sync':
        try {
          await _performBackgroundSync();
          SyncUtils.debugLog('Sincronização em background concluída com sucesso', tag: 'BackgroundSyncService');
          return Future.value(true);
        } catch (e) {
          SyncUtils.debugLog('Erro na sincronização em background: $e', tag: 'BackgroundSyncService');
          return Future.value(false);
        }
      default:
        SyncUtils.debugLog('Tarefa desconhecida: $task', tag: 'BackgroundSyncService');
        return Future.value(false);
    }
  });
}

/// Executa a sincronização em background
Future<void> _performBackgroundSync() async {
  ISyncService? syncService;

  // Obter SyncConfig com fallback
  SyncConfig? syncConfig;

  try {
    syncConfig = SyncConfigurator.provider;
  } catch (e) {
    SyncUtils.debugLog('SyncConfig não disponível via SyncConfigurator: $e', tag: 'BackgroundSyncService');
  }

  try {
    SyncUtils.debugLog('Iniciando sincronização em background', tag: 'BackgroundSyncService');

    // Verificar se há usuário autenticado antes de sincronizar
    try {
      if (syncConfig != null) {
        final isAuthenticated = await syncConfig.isAuthenticated();
        if (!isAuthenticated) {
          SyncUtils.debugLog(
            'Usuário não autenticado - cancelando sincronização em background', tag: 'BackgroundSyncService');
          return;
        }
      } else {
        // SyncConfig não disponível - cancelando sincronização
        SyncUtils.debugLog('SyncConfig não disponível - cancelando sincronização em background', tag: 'BackgroundSyncService');
        return;
      }
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar autenticação: $e', tag: 'BackgroundSyncService');
      return;
    }

    // Tentar obter o SyncService do SyncConfigurator
    try {
      syncService = SyncConfigurator.syncService;
    } catch (e) {
      SyncUtils.debugLog('Cancelando sincronização em background - SyncService não disponível', tag: 'BackgroundSyncService');
      return;
    }

    // Verificar se há itens pendentes antes de iniciar
    final initialPendingCount = await syncService.getPendingItemsCount();

    if (initialPendingCount == 0) {
      SyncUtils.debugLog('Nenhum item pendente para sincronizar', tag: 'BackgroundSyncService');
      await BackgroundSyncService.showSyncResultNotification(
        title: 'Sincronização Concluída',
        body: 'Todos os dados estão atualizados',
        isSuccess: true,
      );
      return;
    }

    // Mostrar notificação de progresso inicial
    await BackgroundSyncService.showSyncProgressNotification(
      title: 'Sincronizando',
      body: 'Sincronizando $initialPendingCount itens...',
      indeterminate: true,
    );

    // Verificar conectividade antes de sincronizar
    if (!syncService.isOnline.value) {
      SyncUtils.debugLog('Sem conexão com a internet - cancelando sincronização em background', tag: 'BackgroundSyncService');
      await BackgroundSyncService.showSyncResultNotification(
        title: 'Sincronização Cancelada',
        body: 'Sem conexão com a internet. Tentaremos novamente mais tarde.',
        isSuccess: false,
      );
      return;
    }

    // Executar sincronização forçada
    SyncUtils.debugLog('Iniciando sincronização forçada em background', tag: 'BackgroundSyncService');

    // Configurar listener para mudanças no status de sincronização
    bool listenerActive = true;
    void syncListener() {
      if (!listenerActive) return;

      final syncData = syncService!.syncData.value;

      switch (syncData.status) {
        case SyncStatus.syncing:
          BackgroundSyncService.showSyncProgressNotification(
            title: 'Sincronizando',
            body: syncData.message ?? 'Sincronizando dados...',
            indeterminate: true,
          );
          break;
        case SyncStatus.success:
          final finalPendingCount = syncData.pendingItems ?? 0;
          final syncedCount = initialPendingCount - finalPendingCount;

          SyncUtils.debugLog(
              'Sincronização em background concluída com sucesso - $syncedCount itens sincronizados, $finalPendingCount restantes', tag: 'BackgroundSyncService');

          BackgroundSyncService.showSyncResultNotification(
            title: 'Sincronização Concluída',
            body: syncedCount > 0
                ? '$syncedCount itens sincronizados com sucesso'
                : 'Todos os dados estão atualizados',
            isSuccess: true,
          );
          listenerActive = false;
          break;
        case SyncStatus.error:
        case SyncStatus.offline:
          SyncUtils.debugLog(
              'Erro na sincronização em background - Status: ${syncData.status}, Mensagem: ${syncData.message}, Itens pendentes: ${syncData.pendingItems}', tag: 'BackgroundSyncService');

          BackgroundSyncService.showSyncResultNotification(
            title: 'Erro na Sincronização',
            body: syncData.message ?? 'Não foi possível sincronizar os dados.',
            isSuccess: false,
          );
          listenerActive = false;
          break;
        default:
          break;
      }
    }

    // Adicionar listener
    syncService.syncData.addListener(syncListener);

    try {
      // Executar a sincronização
      await syncService.forceSync();

      // Aguardar um pouco para garantir que o listener seja executado
      await Future.delayed(const Duration(milliseconds: 1000));
    } finally {
      // Remover listener
      listenerActive = false;
      syncService.syncData.removeListener(syncListener);
    }

    SyncUtils.debugLog('Processo de sincronização em background finalizado', tag: 'BackgroundSyncService');
  } catch (e) {
    SyncUtils.debugLog('Erro inesperado na sincronização em background: $e', tag: 'BackgroundSyncService');

    // Mostrar notificação de erro
    await BackgroundSyncService.showSyncResultNotification(
      title: 'Erro na Sincronização',
      body: 'Ocorreu um erro inesperado durante a sincronização.',
      isSuccess: false,
    );

    rethrow;
  } finally {
    // Limpar recursos se necessário
    if (syncService != null && syncService is SyncService) {
      // Se criamos uma instância temporária, fazer dispose
      try {
        syncService.dispose();
      } catch (e) {
        SyncUtils.debugLog('Erro ao fazer dispose do SyncService: $e', tag: 'BackgroundSyncService');
      }
    }
  }
}
