import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/interfaces/i_logger_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import '../core/entities/sync_log.dart';
import '../core/entities/sync_http_response.dart';
import '../core/services/sync_error_manager.dart';
import '../core/enums/sync_batch_type.dart';
import '../core/config/sync_config.dart';
import '../sync_configurator.dart';
import '../sync_provider.dart';


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

  /// Obtém o SyncProvider via SyncConfigurator
  SyncProvider? _getSyncProvider() {
    return SyncConfigurator.provider;
  }

  /// Função utilitária para logs de debug condicionais
  void _debugLog(String message) {
    final syncProvider = _getSyncProvider();
    if (syncProvider?.enableDebugLogs == true) {
      debugPrint('[SyncUploadStrategy] $message');
    }
  }

  /// Executa o upload de dados para o servidor
  Future<void> syncUploadData() async {
    final syncProvider = _getSyncProvider();

    try {
      // Obter todos os logs pendentes ordenados por data de criação
      final allPendingLogs = await _syncLogger.getPendingLogs();

      if (allPendingLogs.isEmpty) {
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint('[SyncUploadStrategy] Nenhum dado pendente para upload');
        }
        return;
      }

      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncUploadStrategy] Enviando ${allPendingLogs.length} itens pendentes para o servidor');
      }

      // Separar arquivos dos dados
      final fileLogs =
          allPendingLogs.where((log) => log.isFileToUpload).toList();
      final dataLogs =
          allPendingLogs.where((log) => !log.isFileToUpload).toList();

      // Debug: verificar tipos de entidades nos logs de arquivo
      if (syncProvider?.enableDebugLogs == true) {
        final mediaLogs =
            fileLogs.where((log) => log.entityType == 'MEDIA').toList();
        debugPrint(
            '[SyncUploadStrategy] 📁 Total de logs de arquivo: ${fileLogs.length}');
        debugPrint(
            '[SyncUploadStrategy] 🖼️ Logs de media encontrados: ${mediaLogs.length}');
        for (final mediaLog in mediaLogs) {
          debugPrint(
              '[SyncUploadStrategy]    - Media ID: ${mediaLog.entityId}, Operation: ${mediaLog.operation.value}');
        }
      }

      // Ordenar dados por data de criação
      dataLogs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncUploadStrategy] Arquivos para upload: ${fileLogs.length}');
        debugPrint(
            '[SyncUploadStrategy] Dados para upload: ${dataLogs.length}');
      }

      // FASE 1: Processar arquivos em lotes
      if (fileLogs.isNotEmpty) {
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint(
              '[SyncUploadStrategy] === INICIANDO UPLOAD DE ARQUIVOS ===');
        }
        await _processBatches(fileLogs, SyncBatchType.files);
        if (syncProvider?.enableDebugLogs == true) {
          debugPrint(
              '[SyncUploadStrategy] === UPLOAD DE ARQUIVOS CONCLUÍDO ===');
        }
      }

      // FASE 2: Processar dados em lotes (ordenados por data de criação)
      if (dataLogs.isNotEmpty) {
        _debugLog('=== INICIANDO UPLOAD DE DADOS ===');
        await _processBatches(dataLogs, SyncBatchType.data);
        _debugLog('=== UPLOAD DE DADOS CONCLUÍDO ===');
      }

      if (syncProvider?.enableDebugLogs == true) {
        debugPrint(
            '[SyncUploadStrategy] Todos os lotes foram processados com sucesso');
      }
    } catch (e) {
      _debugLog('Erro geral no upload de dados: $e');
      rethrow;
    }
  }

  /// Processa lotes de logs de sincronização
  Future<void> _processBatches(List<SyncLog> logs, SyncBatchType type) async {
    final syncProvider = _getSyncProvider();

    const int batchSize = 10; // Reduzido para lotes menores
    final int totalBatches = (logs.length / batchSize).ceil();

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final int startIndex = batchIndex * batchSize;
      final int endIndex = (startIndex + batchSize < logs.length)
          ? startIndex + batchSize
          : logs.length;

      final List<SyncLog> batch = logs.sublist(startIndex, endIndex);

      _debugLog(
          'Processando lote de ${type.displayName} ${batchIndex + 1}/$totalBatches com ${batch.length} itens');

      try {
        // Enviar lote completo para o backend
        await _sendBatchToBackend(batch, type);

        // Excluir todos os logs do lote após sincronização bem-sucedida
        for (final log in batch) {
          await _syncLogger.removeLog(log.syncId);
          if (syncProvider?.enableDebugLogs == true) {
            debugPrint(
                '[SyncUploadStrategy] Log excluído após sincronização: ${log.entityType}/${log.operation}');
          }
        }

        // Yield para permitir que outras operações sejam executadas
        await Future.delayed(Duration.zero);

        _debugLog(
            'Lote de ${type.displayName} ${batchIndex + 1}/$totalBatches processado com sucesso');
      } catch (e) {
        // Se algum item do lote falhar, registrar erro e parar o processo
        _debugLog(
            'Erro no lote de ${type.displayName} ${batchIndex + 1}/$totalBatches: $e');

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
    final syncProvider = _getSyncProvider();

    try {
      _debugLog(
          '📤 Enviando lote de ${type.displayName} com ${batch.length} itens para o backend');

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

      _debugLog('✅ Lote de ${type.displayName} enviado com sucesso');
    } catch (e) {
      _debugLog('❌ Erro ao enviar lote de ${type.displayName}: $e');
      rethrow;
    }
  }

  /// Envia lote de arquivos usando FormData
  Future<SyncHttpResponse> _sendFileBatch(List<SyncLog> batch) async {
    final syncProvider = _getSyncProvider();
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

          _debugLog('📎 Arquivo adicionado: $fileName (${bytes.length} bytes)');
        } catch (e) {
          _debugLog(
              '❌ Erro ao processar base64 do arquivo ${log.entityId}: $e');
          throw Exception('Erro ao processar arquivo ${log.entityId}: $e');
        }
      } else {
        _debugLog('⚠️ Arquivo ${log.entityId} não contém dados base64 válidos');
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

    _debugLog(
        '📤 Enviando FormData com ${formData.files.length} arquivos e ${fileIds.length} IDs');

    // Obter URL do endpoint de arquivos do provider
    final provider = _getSyncProvider();
    if (provider == null) {
      throw Exception('SyncProvider não está disponível');
    }
    
    final fileSyncUrl =
        provider.fileSyncEndpoint ?? SyncConfig.fileSyncEndpoint;

    return await provider.httpPost(fileSyncUrl, data: formData);
  }

  /// Envia lote de dados regulares usando JSON
  Future<SyncHttpResponse> _sendDataBatch(
      List<SyncLog> batch, SyncBatchType type) async {
    final syncProvider = _getSyncProvider();

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

    if (syncProvider == null) {
      throw Exception('SyncProvider não está disponível');
    }
    
    // Obter URL do endpoint de dados do provider
    final dataSyncUrl =
        syncProvider.dataSyncEndpoint ?? SyncConfig.dataSyncEndpoint;

    return await syncProvider.httpPost(dataSyncUrl, data: batchData);
  }

  /// Registra um log de erro para um log de sincronização específico
  Future<void> _registerErrorLog({
    required SyncLog log,
    required dynamic error,
    required Map<String, dynamic> context,
  }) async {
    final syncProvider = _getSyncProvider();

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

      _debugLog('Erro registrado para log ${log.syncId}: $error');
    } catch (e) {
      _debugLog('❌ Erro ao registrar log de erro: $e');
    }
  }
}
