import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'core/interfaces/i_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'sync_service.dart';
import 'sync_configurator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/enums/sync_status.dart';
import 'core/config/sync_config.dart';
import 'sync_provider.dart';

class BackgroundSyncService {
  static bool _isInitialized = false;

  /// Obtém o SyncProvider via SyncConfigurator
  static SyncProvider? _getSyncProvider() {
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

      // Inicializar serviço de notificações usando o SyncProvider
      try {
        final syncProvider = _getSyncProvider();
        if (syncProvider != null && syncProvider.enableNotifications) {
          await syncProvider.initializeNotifications();
        }
      } catch (e) {
        // Fallback silencioso se SyncProvider não estiver disponível
        final syncProvider = _getSyncProvider();
        if (syncProvider != null && syncProvider.enableDebugLogs) {
          debugPrint('Erro ao inicializar notificações: $e');
        }
      }

      _isInitialized = true;
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('BackgroundSyncService inicializado com sucesso');
      }
    } catch (e) {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao inicializar BackgroundSyncService: $e');
      }
      rethrow;
    }
  }

  /// Inicia a sincronização em background
  static Future<void> startBackgroundSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Workmanager().cancelByUniqueName(SyncConfig.backgroundSyncTaskName);

      //  Registrar nova tarefa periódica
      await Workmanager().registerPeriodicTask(
        SyncConfig.backgroundSyncTaskName,
        SyncConfig.backgroundSyncTaskName,
        frequency: SyncConfig.backgroundSyncFrequency,
        initialDelay: SyncConfig.backgroundSyncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      _isInitialized = true;
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Sincronização em background iniciada');
      }
    } catch (e) {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao iniciar sincronização em background: $e');
      }
      rethrow;
    }
  }

  /// Para a sincronização em background
  static Future<void> stopBackgroundSync() async {
    try {
      await Workmanager().cancelByUniqueName(SyncConfig.backgroundSyncTaskName);
      await _dismissAllNotifications();
      debugPrint('Sincronização em background parada');
    } catch (e) {
      debugPrint('Erro ao parar sincronização em background: $e');
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
      final syncProvider = _getSyncProvider();
      if (syncProvider == null || !syncProvider.enableNotifications) {
        return;
      }

      // Verificar se as notificações estão habilitadas
      final areEnabled = await syncProvider.areNotificationsEnabled();
      if (!areEnabled) {
        if (syncProvider.enableDebugLogs) {
          debugPrint('Notificações não estão habilitadas');
        }
        return;
      }

      if (indeterminate || (progress == null || maxProgress == null)) {
        await syncProvider.showNotification(
          title: title,
          message: body,
          notificationId: SyncConfig.progressNotificationId,
        );
      } else {
        await syncProvider.showProgressNotification(
          title: title,
          message: body,
          progress: progress,
          maxProgress: maxProgress,
          notificationId: SyncConfig.progressNotificationId,
        );
      }
    } catch (e) {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao exibir notificação de progresso: $e');
      }
    }
  }

  /// Mostra notificação de resultado da sincronização
  static Future<void> showSyncResultNotification({
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    try {
      final syncProvider = _getSyncProvider();
      if (syncProvider == null || !syncProvider.enableNotifications) {
        return;
      }

      // Verificar se as notificações estão habilitadas
      final areEnabled = await syncProvider.areNotificationsEnabled();
      if (!areEnabled) {
        if (syncProvider.enableDebugLogs) {
          debugPrint('Notificações não estão habilitadas');
        }
        return;
      }

      await syncProvider.showNotification(
        title: title,
        message: body,
        notificationId: SyncConfig.syncNotificationId,
      );
    } catch (e) {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao mostrar notificação de resultado: $e');
      }
    }
  }

  /// Remove todas as notificações de sincronização
  static Future<void> _dismissAllNotifications() async {
    try {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableNotifications) {
        await syncProvider.cancelNotification(SyncConfig.syncNotificationId);
        await syncProvider
            .cancelNotification(SyncConfig.progressNotificationId);
      }
    } catch (e) {
      final syncProvider = _getSyncProvider();
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao remover notificações: $e');
      }
    }
  }

  /// Verifica se a sincronização em background está ativa
  static Future<bool> isBackgroundSyncActive() async {
    try {
      // Não há uma forma direta de verificar se uma tarefa específica está ativa
      // no WorkManager, então assumimos que está ativa se foi iniciada
      return _isInitialized;
    } catch (e) {
      debugPrint('Erro ao verificar status da sincronização em background: $e');
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
        SyncConfig.backgroundSyncTaskName,
        initialDelay: const Duration(seconds: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      debugPrint('Sincronização imediata em background disparada');
    } catch (e) {
      debugPrint('Erro ao disparar sincronização imediata: $e');
    }
  }
}

/// Callback dispatcher para o WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Executando tarefa em background: $task');

    switch (task) {
      case 'background_sync_task':
      case 'immediate_sync':
        try {
          await _performBackgroundSync();
          debugPrint('Sincronização em background concluída com sucesso');
          return Future.value(true);
        } catch (e) {
          debugPrint('Erro na sincronização em background: $e');
          return Future.value(false);
        }
      default:
        debugPrint('Tarefa desconhecida: $task');
        return Future.value(false);
    }
  });
}

/// Executa a sincronização em background
Future<void> _performBackgroundSync() async {
  ISyncService? syncService;

  // Obter SyncProvider com fallback
  SyncProvider? syncProvider;

  try {
    syncProvider = SyncConfigurator.provider;
  } catch (e) {
    debugPrint('SyncProvider não disponível via SyncConfigurator: $e');
  }

  try {
    if (syncProvider != null && syncProvider.enableDebugLogs) {
      debugPrint('Iniciando sincronização em background');
    }

    // Verificar se há usuário autenticado antes de sincronizar
    try {
      if (syncProvider != null) {
        final isAuthenticated = await syncProvider.isAuthenticated();
        if (!isAuthenticated) {
          if (syncProvider.enableDebugLogs) {
            debugPrint(
                'Usuário não autenticado - cancelando sincronização em background');
          }
          return;
        }
      } else {
        // SyncProvider não disponível - cancelando sincronização
        debugPrint(
            'SyncProvider não disponível - cancelando sincronização em background');
        return;
      }
    } catch (e) {
      if (syncProvider != null && syncProvider.enableDebugLogs) {
        debugPrint('Erro ao verificar autenticação: $e');
      }
      return;
    }

    // Tentar obter o SyncService do SyncConfigurator
    try {
      syncService = SyncConfigurator.syncService;
    } catch (e) {
      debugPrint(
          'Cancelando sincronização em background - SyncService não disponível');
      return;
    }

    // Verificar se há itens pendentes antes de iniciar
    final initialPendingCount = await syncService.getPendingItemsCount();

    if (initialPendingCount == 0) {
      if (syncProvider.enableDebugLogs == true) {
        debugPrint('Nenhum item pendente para sincronizar');
      }
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
      debugPrint(
          'Sem conexão com a internet - cancelando sincronização em background');
      await BackgroundSyncService.showSyncResultNotification(
        title: 'Sincronização Cancelada',
        body: 'Sem conexão com a internet. Tentaremos novamente mais tarde.',
        isSuccess: false,
      );
      return;
    }

    // Executar sincronização forçada
    debugPrint('Iniciando sincronização forçada em background');

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

          if (syncProvider?.enableDebugLogs == true) {
            debugPrint(
                'Sincronização em background concluída com sucesso - $syncedCount itens sincronizados, $finalPendingCount restantes');
          }

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
          if (syncProvider?.enableDebugLogs == true) {
            debugPrint(
                'Erro na sincronização em background - Status: ${syncData.status}, Mensagem: ${syncData.message}, Itens pendentes: ${syncData.pendingItems}');
          }

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

    if (syncProvider.enableDebugLogs == true) {
      debugPrint('Processo de sincronização em background finalizado');
    }
  } catch (e) {
    if (syncProvider?.enableDebugLogs == true) {
      debugPrint('Erro inesperado na sincronização em background: $e');
    }

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
        debugPrint('Erro ao fazer dispose do SyncService: $e');
      }
    }
  }
}
