import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/services/sync_data_cleanup_service.dart';
import '../core/interfaces/i_download_strategy.dart';
import '../sync_provider.dart';

import '../sync_configurator.dart';

/// Orquestrador principal para download de dados do servidor
///
/// Esta classe é responsável por:
/// - Coordenar todas as estratégias de download
/// - Limpar dados antigos antes da sincronização
/// - Fazer pré-cache de imagens para uso offline
/// - Gerenciar notificações de progresso
/// - Executar limpeza pós-sincronização
class SyncDownloadStrategy {
  final ISyncDataCleanupService _dataCleanupService;

  SyncDownloadStrategy(
    this._dataCleanupService,
  );

  // Helper para obter o sync provider
  /// Obtém o SyncProvider via SyncConfigurator
  SyncProvider? _getSyncProvider() {
    return SyncConfigurator.provider;
  }

  /// Executa o download completo de dados do servidor
  Future<void> fetchDataFromServer() async {
    final syncProvider = _getSyncProvider();

    if (syncProvider?.enableDebugLogs == true) {
      debugPrint(
          '[SyncDownloadStrategy] === INICIANDO BUSCA DE DADOS DO SERVIDOR ===');
    }

    try {
      // Mostrar notificação de progresso para busca de dados
      if (syncProvider?.enableNotifications == true) {
        await syncProvider!.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Buscando dados atualizados do servidor...',
        );
      }

      // Limpar dados antigos
      await _clearOldData();

      // Executar todas as estratégias de download
      final results = await _executeDownloadStrategies();

      // Processar resultados e extrair IDs de medias para pré-cache
      final mediaIds = _extractMediaIds(results);

      // Fazer pré-cache de imagens e limpeza de órfãs
      await _handleImageCaching(mediaIds);

      // Cancelar notificações
      await _cancelNotifications();

      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] === BUSCA DE DADOS DO SERVIDOR CONCLUÍDA ===');
      }
    } catch (e) {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] ERRO GERAL durante busca de dados do servidor: $e');
      }

      // Cancelar notificações em caso de erro
      await _cancelNotifications();

      rethrow;
    }
  }

  /// Limpa dados antigos antes da sincronização
  Future<void> _clearOldData() async {
    final syncProvider = _getSyncProvider();

    try {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] Limpando dados antigos antes da sincronização...');
      }

      if (syncProvider?.enableNotifications == true) {
        await syncProvider!.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Limpando dados antigos...',
        );
      }

      await _dataCleanupService.clearSyncData();

      if (syncProvider?.enableDebugLogs == true) {
        debugPrint('[SyncDownloadStrategy] Dados antigos limpos com sucesso');
      }
    } catch (e) {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint('[SyncDownloadStrategy] ERRO ao limpar dados antigos: $e');
      }
      throw Exception('Falha ao limpar dados antigos: $e');
    }
  }

  /// Executa todas as estratégias de download registradas
  Future<List<DownloadResult>> _executeDownloadStrategies() async {
    final syncProvider = _getSyncProvider();

    try {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint('[SyncDownloadStrategy] Salvando dados no banco local...');
      }

      if (syncProvider?.enableNotifications == true) {
        await syncProvider!.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Salvando dados no banco local...',
        );
      }

      final results = <DownloadResult>[];

      for (final strategy in syncProvider?.downloadStrategies ?? []) {
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint(
              '[SyncDownloadStrategy] Executando estratégia: ${strategy.runtimeType}');
        }
        final result = await strategy.downloadData();
        results.add(result);

        if (!result.success) {
          if (syncProvider?.enableDebugLogs == true) {
            debugPrint(
                '[SyncDownloadStrategy] Estratégia ${strategy.runtimeType} falhou: ${result.message}');
          }
          throw Exception(
              'Falha na estratégia ${strategy.runtimeType}: ${result.message}');
        }

        if (syncProvider?.enableDebugLogs == true) {
          debugPrint(
              '[SyncDownloadStrategy] Estratégia ${strategy.runtimeType} executada com sucesso: ${result.itemsDownloaded} itens');
        }
      }

      return results;
    } catch (e) {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] ERRO ao executar estratégias de download: $e');
      }
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
    final syncProvider = _getSyncProvider();

    try {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] Iniciando pré-cache e limpeza de imagens...');
      }

      if (syncProvider?.enableNotifications == true) {
        await syncProvider!.showProgressNotification(
          title: 'Sincronizando',
          progress: 0,
          maxProgress: 100,
          message: 'Preparando imagens para uso offline...',
        );
      }

      // TODO: Implementar serviço interno de cache de imagens no módulo sync
      // Por enquanto, apenas logamos que o processo seria executado
      if (mediaIds.isNotEmpty) {
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint(
              '[SyncDownloadStrategy] ${mediaIds.length} imagens identificadas para pré-cache');
        }
      } else {
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint('[SyncDownloadStrategy] Nenhuma imagem para pré-carregar');
        }
      }
    } catch (e) {
      // Não interromper a sincronização se o pré-cache falhar
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint('[SyncDownloadStrategy] Erro no pré-cache de imagens: $e');
      }
      // Continuar com a sincronização
    }
  }

  /// Cancela todas as notificações de sincronização
  Future<void> _cancelNotifications() async {
    final syncProvider = _getSyncProvider();

    try {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncDownloadStrategy] Cancelando todas as notificações de sincronização...');
      }

      if (syncProvider?.enableNotifications == true) {
        await syncProvider!.cancelAllNotifications();
      }
    } catch (e) {
      if (syncProvider?.enableDebugLogs == true) {
        debugPrint('[SyncDownloadStrategy] Falha ao cancelar notificações: $e');
      }
      // Não é crítico, continuar
    }
  }
}
