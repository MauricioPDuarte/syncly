import 'dart:async';
import 'package:get_it/get_it.dart';
import '../core/interfaces/i_download_strategy.dart';
import '../core/services/sync_notification_service.dart';
import '../core/utils/sync_utils.dart';
import '../sync_configurator.dart';
import '../sync_config.dart';

/// Orquestrador principal para download de dados do servidor
///
/// Esta classe é responsável por:
/// - Coordenar todas as estratégias de download
/// - Limpar dados antigos antes da sincronização
/// - Fazer pré-cache de imagens para uso offline
/// - Gerenciar notificações de progresso
/// - Executar limpeza pós-sincronização
class SyncDownloadStrategy {
  SyncDownloadStrategy();

  // Helper para obter o sync provider
  /// Obtém o SyncConfig via SyncConfigurator
  SyncConfig? _getSyncConfig() {
    return SyncConfigurator.provider;
  }

  /// Executa o download de dados do servidor (completo ou incremental)
  Future<void> fetchDataFromServer() async {
    final syncConfig = _getSyncConfig();

    SyncUtils.debugLog('=== INICIANDO BUSCA DE DADOS DO SERVIDOR ===',
        tag: 'SyncDownloadStrategy');

    try {
      // Determinar se deve usar sincronização incremental
      final shouldUseIncremental = await _shouldUseIncrementalSync();
      final lastSyncTimestamp = shouldUseIncremental 
          ? await syncConfig?.getLastSyncTimestamp() 
          : null;

      final syncType = shouldUseIncremental ? 'incremental' : 'completa';
      SyncUtils.debugLog('Tipo de sincronização: $syncType',
          tag: 'SyncDownloadStrategy');
      
      if (lastSyncTimestamp != null) {
        SyncUtils.debugLog('Última sincronização: $lastSyncTimestamp',
            tag: 'SyncDownloadStrategy');
      }

      // Mostrar notificação de progresso para busca de dados
      if (syncConfig?.enableNotifications == true) {
        await SyncNotificationService.instance.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: shouldUseIncremental 
              ? 'Buscando atualizações desde a última sincronização...'
              : 'Buscando dados atualizados do servidor...',
        );
      }

      // Limpar dados antigos apenas se for sincronização completa
      if (!shouldUseIncremental) {
        await _clearOldData();
      }

      // Executar todas as estratégias de download
      final results = await _executeDownloadStrategies(lastSyncTimestamp);



      // Processar resultados e extrair IDs de medias para pré-cache
      final mediaIds = _extractMediaIds(results);

      // Fazer pré-cache de imagens e limpeza de órfãs
      await _handleImageCaching(mediaIds);

      // Salvar timestamp da sincronização bem-sucedida
      await syncConfig?.saveLastSyncTimestamp(DateTime.now());

      // Cancelar notificações
      await _cancelNotifications();

      SyncUtils.debugLog('=== BUSCA DE DADOS DO SERVIDOR CONCLUÍDA ===',
          tag: 'SyncDownloadStrategy');
    } catch (e) {
      SyncUtils.debugLog('ERRO GERAL durante busca de dados do servidor: $e',
          tag: 'SyncDownloadStrategy');

      // Cancelar notificações em caso de erro
      await _cancelNotifications();

      rethrow;
    }
  }

  /// Limpa dados antigos antes da sincronização
  Future<void> _clearOldData() async {
    final syncConfig = _getSyncConfig();

    try {
      SyncUtils.debugLog('Limpando dados antigos antes da sincronização...',
          tag: 'SyncDownloadStrategy');

      if (syncConfig?.enableNotifications == true) {
        await SyncNotificationService.instance.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Limpando dados antigos...',
        );
      }

      await syncConfig!.clearLocalData();

      SyncUtils.debugLog('Dados antigos limpos com sucesso',
          tag: 'SyncDownloadStrategy');
    } catch (e) {
      SyncUtils.debugLog('ERRO ao limpar dados antigos: $e',
          tag: 'SyncDownloadStrategy');
      throw Exception('Falha ao limpar dados antigos: $e');
    }
  }

  /// Executa todas as estratégias de download registradas
  Future<List<DownloadResult>> _executeDownloadStrategies(DateTime? lastSyncTimestamp) async {
    final syncConfig = _getSyncConfig();

    try {
      SyncUtils.debugLog('Salvando dados no banco local...',
          tag: 'SyncDownloadStrategy');

      if (syncConfig?.enableNotifications == true) {
        await SyncNotificationService.instance.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Salvando dados no banco local...',
        );
      }

      final results = <DownloadResult>[];
      final isIncremental = lastSyncTimestamp != null;

      for (final strategy in GetIt.instance.get<List<IDownloadStrategy>>()) {
        SyncUtils.debugLog('Executando estratégia: ${strategy.runtimeType}',
            tag: 'SyncDownloadStrategy');
        final result = await strategy.downloadData(
          lastSyncTimestamp: lastSyncTimestamp,
          isIncremental: isIncremental,
        );
        results.add(result);

        if (!result.success) {
          SyncUtils.debugLog(
              'Estratégia ${strategy.runtimeType} falhou: ${result.message}',
              tag: 'SyncDownloadStrategy');
          throw Exception(
              'Falha na estratégia ${strategy.runtimeType}: ${result.message}');
        }

        final syncTypeLog = result.isIncremental ? 'incremental' : 'completa';
        SyncUtils.debugLog(
            'Estratégia ${strategy.runtimeType} executada com sucesso ($syncTypeLog): ${result.itemsDownloaded} itens',
            tag: 'SyncDownloadStrategy');
      }

      return results;
    } catch (e) {
      SyncUtils.debugLog('ERRO ao executar estratégias de download: $e',
          tag: 'SyncDownloadStrategy');
      throw Exception('Falha ao processar dados recebidos: $e');
    }
  }

  /// Extrai IDs de medias dos resultados para pré-cache
  Set<String> _extractMediaIds(List<DownloadResult> results) {
    final mediaIds = <String>{};

    for (final result in results) {
      if (result.metadata != null && result.metadata!.containsKey('mediaIds')) {
        final ids = result.metadata!['mediaIds'] as List<String>?;
        if (ids != null) {
          mediaIds.addAll(ids);
        }
      }
    }

    return mediaIds;
  }

  /// Gerencia pré-cache de imagens e limpeza de órfãs
  Future<void> _handleImageCaching(Set<String> mediaIds) async {
    final syncConfig = _getSyncConfig();

    try {
      SyncUtils.debugLog('Iniciando pré-cache e limpeza de imagens...',
          tag: 'SyncDownloadStrategy');

      if (syncConfig?.enableNotifications == true) {
        await SyncNotificationService.instance.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Preparando imagens para uso offline...',
        );
      }

      // TODO: Implementar serviço interno de cache de imagens no módulo sync
      // Por enquanto, apenas logamos que o processo seria executado
      if (mediaIds.isNotEmpty) {
        SyncUtils.debugLog(
            '${mediaIds.length} imagens identificadas para pré-cache',
            tag: 'SyncDownloadStrategy');
      } else {
        SyncUtils.debugLog('Nenhuma imagem para pré-carregar',
            tag: 'SyncDownloadStrategy');
      }
    } catch (e) {
      // Não interromper a sincronização se o pré-cache falhar
      SyncUtils.debugLog('Erro no pré-cache de imagens: $e',
          tag: 'SyncDownloadStrategy');
      // Continuar com a sincronização
    }
  }

  /// Cancela todas as notificações de sincronização
  Future<void> _cancelNotifications() async {
    final syncConfig = _getSyncConfig();

    try {
      SyncUtils.debugLog('Cancelando todas as notificações de sincronização...',
          tag: 'SyncDownloadStrategy');

      if (syncConfig?.enableNotifications == true) {
        await SyncNotificationService.instance.cancelAllNotifications();
      }
    } catch (e) {
      SyncUtils.debugLog('Falha ao cancelar notificações: $e',
          tag: 'SyncDownloadStrategy');
      // Não é crítico, continuar
    }
  }

  /// Determina se deve usar sincronização incremental
  Future<bool> _shouldUseIncrementalSync() async {
    final syncConfig = _getSyncConfig();
    
    // Verificar se a sincronização incremental está habilitada
    if (syncConfig?.useIncrementalSync != true) {
      SyncUtils.debugLog('Sincronização incremental desabilitada na configuração',
          tag: 'SyncDownloadStrategy');
      return false;
    }

    try {
      final lastSyncTimestamp = await syncConfig?.getLastSyncTimestamp();
      
      // Se nunca houve sincronização, fazer sincronização completa
      if (lastSyncTimestamp == null) {
        SyncUtils.debugLog('Primeira sincronização - usando sincronização completa',
            tag: 'SyncDownloadStrategy');
        return false;
      }

      // Verificar se a última sincronização não foi há muito tempo
      final now = DateTime.now();
      final timeSinceLastSync = now.difference(lastSyncTimestamp);
      final maxInterval = syncConfig?.maxIncrementalSyncInterval ?? const Duration(days: 7);

      if (timeSinceLastSync > maxInterval) {
        SyncUtils.debugLog(
            'Última sincronização há ${timeSinceLastSync.inDays} dias - usando sincronização completa',
            tag: 'SyncDownloadStrategy');
        return false;
      }

      return true;
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar timestamp da última sincronização: $e',
          tag: 'SyncDownloadStrategy');
      // Em caso de erro, usar sincronização completa por segurança
      return false;
    }
  }


}
