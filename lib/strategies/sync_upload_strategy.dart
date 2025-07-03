import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/interfaces/i_logger_provider.dart';
import '../core/entities/sync_log.dart';
import '../core/entities/sync_http_response.dart';
import '../core/services/sync_error_manager.dart';
import '../core/enums/sync_batch_type.dart';
import '../core/utils/sync_utils.dart';
import '../sync_configurator.dart';
import '../sync_config.dart';

/// Estratégia para upload de dados para o servidor
///
/// Esta classe é responsável por:
/// - Processar logs de sincronização pendentes
/// - Separar arquivos de dados regulares
/// - Enviar dados em lotes para o servidor
/// - Gerenciar retry e logs de erro
/// - Processar uploads de arquivos com FormData
class SyncUploadStrategy {
  final ILoggerProvider _syncLogger;
  final ISyncErrorManager _errorManager;

  SyncUploadStrategy(
    this._syncLogger,
    this._errorManager,
  );

  /// Obtém o SyncConfig via SyncConfigurator
  SyncConfig? _getSyncConfig() {
    return SyncConfigurator.provider;
  }

  /// Executa o upload de dados para o servidor
  Future<void> syncUploadData() async {
    try {
      // Obter todos os logs pendentes ordenados por data de criação
      final allPendingLogs = await _syncLogger.getPendingLogs();

      if (allPendingLogs.isEmpty) {
        SyncUtils.debugLog('Nenhum dado pendente para upload',
            tag: 'SyncUploadStrategy');
        return;
      }

      SyncUtils.debugLog(
          'Enviando ${allPendingLogs.length} itens pendentes para o servidor',
          tag: 'SyncUploadStrategy');

      // Separar arquivos dos dados
      final fileLogs =
          allPendingLogs.where((log) => log.isFileToUpload).toList();
      final dataLogs =
          allPendingLogs.where((log) => !log.isFileToUpload).toList();

      // Debug: verificar tipos de entidades nos logs de arquivo
      final mediaLogs =
          fileLogs.where((log) => log.entityType == 'MEDIA').toList();
      SyncUtils.debugLog('📁 Total de logs de arquivo: ${fileLogs.length}',
          tag: 'SyncUploadStrategy');
      SyncUtils.debugLog('🖼️ Logs de media encontrados: ${mediaLogs.length}',
          tag: 'SyncUploadStrategy');
      for (final mediaLog in mediaLogs) {
        SyncUtils.debugLog(
            '   - Media ID: ${mediaLog.entityId}, Operation: ${mediaLog.operation.value}',
            tag: 'SyncUploadStrategy');
      }

      // Ordenar dados por data de criação
      dataLogs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      SyncUtils.debugLog('Arquivos para upload: ${fileLogs.length}',
          tag: 'SyncUploadStrategy');
      SyncUtils.debugLog('Dados para upload: ${dataLogs.length}',
          tag: 'SyncUploadStrategy');

      // FASE 1: Processar arquivos em lotes
      if (fileLogs.isNotEmpty) {
        SyncUtils.debugLog('=== INICIANDO UPLOAD DE ARQUIVOS ===',
            tag: 'SyncUploadStrategy');
        await _processBatches(fileLogs, SyncBatchType.files);
        SyncUtils.debugLog('=== UPLOAD DE ARQUIVOS CONCLUÍDO ===',
            tag: 'SyncUploadStrategy');
      }

      // FASE 2: Processar dados em lotes (ordenados por data de criação)
      if (dataLogs.isNotEmpty) {
        SyncUtils.debugLog('=== INICIANDO UPLOAD DE DADOS ===',
            tag: 'SyncUploadStrategy');
        await _processBatches(dataLogs, SyncBatchType.data);
        SyncUtils.debugLog('=== UPLOAD DE DADOS CONCLUÍDO ===',
            tag: 'SyncUploadStrategy');
      }

      SyncUtils.debugLog('Todos os lotes foram processados com sucesso',
          tag: 'SyncUploadStrategy');
    } catch (e) {
      SyncUtils.debugLog('Erro geral no upload de dados: $e',
          tag: 'SyncUploadStrategy');
      rethrow;
    }
  }

  /// Processa lotes de logs de sincronização
  Future<void> _processBatches(List<SyncLog> logs, SyncBatchType type) async {
    const int batchSize = 10; // Reduzido para lotes menores
    final int totalBatches = (logs.length / batchSize).ceil();

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final int startIndex = batchIndex * batchSize;
      final int endIndex = (startIndex + batchSize < logs.length)
          ? startIndex + batchSize
          : logs.length;

      final List<SyncLog> batch = logs.sublist(startIndex, endIndex);

      SyncUtils.debugLog(
          'Processando lote de ${type.displayName} ${batchIndex + 1}/$totalBatches com ${batch.length} itens',
          tag: 'SyncUploadStrategy');

      try {
        // Enviar lote completo para o backend
        await _sendBatchToBackend(batch, type);

        // Excluir todos os logs do lote após sincronização bem-sucedida
        for (final log in batch) {
          await _syncLogger.removeLog(log.syncId);
          SyncUtils.debugLog(
              'Log excluído após sincronização: ${log.entityType}/${log.operation}',
              tag: 'SyncUploadStrategy');
        }

        // Yield para permitir que outras operações sejam executadas
        await Future.delayed(Duration.zero);

        SyncUtils.debugLog(
            'Lote de ${type.displayName} ${batchIndex + 1}/$totalBatches processado com sucesso',
            tag: 'SyncUploadStrategy');
      } catch (e) {
        // Se algum item do lote falhar, registrar erro e parar o processo
        SyncUtils.debugLog(
            'Erro no lote de ${type.displayName} ${batchIndex + 1}/$totalBatches: $e',
            tag: 'SyncUploadStrategy');

        // Registrar erro para todos os logs do lote atual
        for (final log in batch) {
          await _registerErrorLog(
            log: log,
            error: e,
            context: {
              'batchType': type.displayName,
              'batchIndex': batchIndex + 1,
              'totalBatches': totalBatches,
              'batchSize': batch.length,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        // Parar o processo - não processar próximos lotes
        throw Exception(
            'Falha no lote de ${type.displayName} ${batchIndex + 1}: $e');
      }
    }
  }

  /// Envia um lote de logs para o backend
  ///
  /// Faz a chamada real para a API de sincronização
  Future<void> _sendBatchToBackend(
      List<SyncLog> batch, SyncBatchType type) async {
    try {
      SyncUtils.debugLog(
          '📤 Enviando lote de ${type.displayName} com ${batch.length} itens para o backend',
          tag: 'SyncUploadStrategy');

      SyncHttpResponse response;

      if (type == SyncBatchType.files) {
        // Para arquivos, usar FormData
        response = await _sendFileBatch(batch);
      } else {
        // Para dados regulares, usar JSON
        response = await _sendDataBatch(batch, type);
      }

      if (response.statusCode != 200) {
        throw Exception(
            'Erro no servidor: ${response.statusCode} - ${response.data}');
      }

      SyncUtils.debugLog('✅ Lote de ${type.displayName} enviado com sucesso',
          tag: 'SyncUploadStrategy');
    } catch (e) {
      SyncUtils.debugLog('❌ Erro ao enviar lote de ${type.displayName}: $e',
          tag: 'SyncUploadStrategy');
      rethrow;
    }
  }

  /// Envia lote de arquivos usando FormData
  Future<SyncHttpResponse> _sendFileBatch(List<SyncLog> batch) async {
    final formData = FormData();
    final fileIds = <String>[];

    // Processar cada arquivo do lote
    for (int i = 0; i < batch.length; i++) {
      final log = batch[i];
      final media = jsonDecode(log.dataJson) as Map<String, dynamic>;

      // Extrair base64Content do campo Media
      var base64Data = media['base64Content'] as String;

      if (base64Data.isNotEmpty) {
        // Remover prefixo data:image/jpeg;base64, se existir
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }

        try {
          // Converter base64 para bytes
          final bytes = base64Decode(base64Data);

          // Determinar extensão do arquivo e contentType baseado no tipo de mídia
          String extension = 'jpg';
          String contentType = 'image/jpeg';
          if (media.containsKey('mimeType')) {
            final mimeType = media['mimeType'] as String;
            if (mimeType.contains('png')) {
              extension = 'png';
              contentType = 'image/png';
            } else if (mimeType.contains('pdf')) {
              extension = 'pdf';
              contentType = 'application/pdf';
            } else if (mimeType.contains('mp4')) {
              extension = 'mp4';
              contentType = 'video/mp4';
            } else if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
              extension = 'jpg';
              contentType = 'image/jpeg';
            } else {
              // Usar o mimeType original se disponível
              contentType = mimeType;
            }
          }

          // Criar nome do arquivo
          final fileName = 'file_${log.entityId}_$i.$extension';

          // Adicionar arquivo ao FormData com contentType correto
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(
              bytes,
              filename: fileName,
              contentType: DioMediaType.parse(contentType),
            ),
          ));

          // Adicionar ID do arquivo na ordem correta
          fileIds.add(log.entityId);

          SyncUtils.debugLog(
              '📎 Arquivo adicionado: $fileName (${bytes.length} bytes)',
              tag: 'SyncUploadStrategy');
        } catch (e) {
          SyncUtils.debugLog(
              '❌ Erro ao processar base64 do arquivo ${log.entityId}: $e',
              tag: 'SyncUploadStrategy');
          throw Exception('Erro ao processar arquivo ${log.entityId}: $e');
        }
      } else {
        SyncUtils.debugLog(
            '⚠️ Arquivo ${log.entityId} não contém dados base64 válidos',
            tag: 'SyncUploadStrategy');
        throw Exception(
            'Arquivo ${log.entityId} não contém dados base64 válidos');
      }
    }

    // Adicionar array de IDs dos arquivos na ordem correta
    formData.fields.add(MapEntry('fileIds', jsonEncode(fileIds)));

    // Adicionar informações dos logs (sem o conteúdo base64)
    final logsMetadata = batch.map((log) {
      final media = jsonDecode(log.dataJson) as Map<String, dynamic>;
      // Remover campo base64Content para evitar duplicação
      media.remove('base64Content');

      return {
        'entityType': log.entityType,
        'operation': log.operation.value,
        'data': media,
        'createdAt': log.createdAt.toIso8601String(),
      };
    }).toList();

    formData.fields.add(MapEntry('logs', jsonEncode(logsMetadata)));

    SyncUtils.debugLog(
        '📤 Enviando FormData com ${formData.files.length} arquivos e ${fileIds.length} IDs',
        tag: 'SyncUploadStrategy');

    // Obter URL do endpoint de arquivos do provider
    final provider = _getSyncConfig();
    if (provider == null) {
      throw Exception('SyncConfig não está disponível');
    }

    final fileSyncUrl = provider.fileSyncEndpoint;

    return await provider.httpPost(fileSyncUrl, data: formData);
  }

  /// Envia lote de dados regulares usando JSON
  Future<SyncHttpResponse> _sendDataBatch(
      List<SyncLog> batch, SyncBatchType type) async {
    final syncConfig = _getSyncConfig();

    final batchData = {
      'type': type.displayName,
      'logs': batch
          .map((log) => {
                'syncId': log.syncId,
                'entityType': log.entityType,
                'entityId': log.entityId,
                'operation': log.operation.value,
                'data': log.dataJson,
                'createdAt': log.createdAt.toIso8601String(),
              })
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (syncConfig == null) {
      throw Exception('SyncConfig não está disponível');
    }

    // Obter URL do endpoint de dados do provider
    final dataSyncUrl = syncConfig.dataSyncEndpoint;

    return await syncConfig.httpPost(dataSyncUrl, data: batchData);
  }

  /// Registra um log de erro para um log de sincronização específico
  Future<void> _registerErrorLog({
    required SyncLog log,
    required dynamic error,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Usar o SyncErrorManager para registrar o erro
      await _errorManager.logError(
        message: error.toString(),
        stackTrace: error is Exception ? error.toString() : null,
        metadata: {
          'syncLogId': log.syncId,
          'originalData': log.dataJson,
          'context': context,
        },
        category: 'SyncUploadStrategy',
        entityType: log.entityType,
        entityId: log.entityId,
      );

      // Incrementar contador de tentativas e definir último erro
      await _syncLogger.incrementRetryCount(log.syncId);
      await _syncLogger.setLastError(log.syncId, error.toString());

      SyncUtils.debugLog('Erro registrado para log ${log.syncId}: $error',
          tag: 'SyncUploadStrategy');
    } catch (e) {
      SyncUtils.debugLog('❌ Erro ao registrar log de erro: $e',
          tag: 'SyncUploadStrategy');
    }
  }
}
