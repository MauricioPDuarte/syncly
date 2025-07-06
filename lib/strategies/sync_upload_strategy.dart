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
  static const String _tag = 'SyncUploadStrategy';
  
  final ILoggerProvider _syncLogger;
  final ISyncErrorManager _errorManager;

  SyncUploadStrategy(
    this._syncLogger,
    this._errorManager,
  );

  /// Obtém o SyncConfig via SyncConfigurator
  SyncConfig _getSyncConfig() {
    final config = SyncConfigurator.provider;
    if (config == null) {
      throw Exception('SyncConfig não está disponível');
    }
    return config;
  }

  /// Executa o upload de dados para o servidor
  Future<void> syncUploadData() async {
    try {
      final allPendingLogs = await _syncLogger.getPendingLogs();

      if (allPendingLogs.isEmpty) {
        SyncUtils.debugLog('Nenhum dado pendente para upload', tag: _tag);
        return;
      }

      SyncUtils.debugLog(
          'Iniciando upload de ${allPendingLogs.length} itens pendentes',
          tag: _tag);

      final (fileLogs, dataLogs) = _separateLogsByType(allPendingLogs);

      // Processar arquivos primeiro, depois dados
      if (fileLogs.isNotEmpty) {
        await _processBatches(fileLogs, SyncBatchType.files);
      }

      if (dataLogs.isNotEmpty) {
        await _processBatches(dataLogs, SyncBatchType.data);
      }

      SyncUtils.debugLog('Upload concluído com sucesso', tag: _tag);
    } catch (e) {
      SyncUtils.debugLog('Erro no upload: $e', tag: _tag);
      rethrow;
    }
  }

  /// Separa logs por tipo (arquivos vs dados) e ordena dados por data
  (List<SyncLog>, List<SyncLog>) _separateLogsByType(List<SyncLog> logs) {
    final fileLogs = logs.where((log) => log.isFileToUpload).toList();
    final dataLogs = logs.where((log) => !log.isFileToUpload).toList();
    
    // Ordenar dados por data de criação
    dataLogs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return (fileLogs, dataLogs);
  }

  /// Processa lotes de logs de sincronização
  Future<void> _processBatches(List<SyncLog> logs, SyncBatchType type) async {
    final syncConfig = _getSyncConfig();
    final batchSize = type == SyncBatchType.files
        ? syncConfig.maxFileBatchSize
        : syncConfig.maxDataBatchSize;
    final totalBatches = (logs.length / batchSize).ceil();

    for (int batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      final batch = _createBatch(logs, batchIndex, batchSize);

      try {
        await _sendBatchToBackend(batch, type);
        await _removeBatchLogs(batch);
        await Future.delayed(Duration.zero); // Yield para outras operações
      } catch (e) {
        await _handleBatchError(batch, e, type, batchIndex + 1, totalBatches);
        throw Exception('Falha no lote de ${type.displayName} ${batchIndex + 1}: $e');
      }
    }
  }

  /// Cria um lote de logs baseado no índice e tamanho
  List<SyncLog> _createBatch(List<SyncLog> logs, int batchIndex, int batchSize) {
    final startIndex = batchIndex * batchSize;
    final endIndex = (startIndex + batchSize < logs.length)
        ? startIndex + batchSize
        : logs.length;
    return logs.sublist(startIndex, endIndex);
  }

  /// Remove todos os logs de um lote após sucesso
  Future<void> _removeBatchLogs(List<SyncLog> batch) async {
    for (final log in batch) {
      await _syncLogger.removeLog(log.syncId);
    }
  }

  /// Trata erros de lote registrando para todos os logs
  Future<void> _handleBatchError(
    List<SyncLog> batch,
    dynamic error,
    SyncBatchType type,
    int batchNumber,
    int totalBatches,
  ) async {
    SyncUtils.debugLog(
        'Erro no lote ${type.displayName} $batchNumber/$totalBatches: $error',
        tag: _tag);

    for (final log in batch) {
      await _registerErrorLog(
        log: log,
        error: error,
        context: {
          'batchType': type.displayName,
          'batchIndex': batchNumber,
          'totalBatches': totalBatches,
          'batchSize': batch.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Envia um lote de logs para o backend
  Future<void> _sendBatchToBackend(
      List<SyncLog> batch, SyncBatchType type) async {
    final response = type == SyncBatchType.files
        ? await _sendFileBatch(batch)
        : await _sendDataBatch(batch, type);

    if (response.statusCode != 200) {
      throw Exception(
          'Erro no servidor: ${response.statusCode} - ${response.data}');
    }
  }

  /// Parse seguro de JSON de um log
  Map<String, dynamic> _parseLogData(SyncLog log) {
    if (log.dataJson.isEmpty) {
      throw Exception('dataJson está vazio para log ${log.syncId}');
    }
    
    try {
      return jsonDecode(log.dataJson) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erro ao processar dados do log ${log.syncId}: $e');
    }
  }

  /// Determina extensão e tipo de conteúdo baseado no mimeType
  (String, String) _getFileTypeInfo(Map<String, dynamic> media) {
    if (!media.containsKey('mimeType') || media['mimeType'] == null) {
      return ('jpg', 'image/jpeg');
    }
    
    final mimeType = media['mimeType'].toString();
    if (mimeType.contains('png')) return ('png', 'image/png');
    if (mimeType.contains('pdf')) return ('pdf', 'application/pdf');
    if (mimeType.contains('mp4')) return ('mp4', 'video/mp4');
    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return ('jpg', 'image/jpeg');
    
    return ('jpg', mimeType); // Usar mimeType original como fallback
  }

  /// Processa base64 e cria MultipartFile
  MultipartFile _createMultipartFile(
    String base64Data,
    String fileName,
    String contentType,
  ) {
    // Remover prefixo data:image/jpeg;base64, se existir
    if (base64Data.contains(',')) {
      base64Data = base64Data.split(',').last;
    }
    
    final bytes = base64Decode(base64Data);
    return MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType.parse(contentType),
    );
  }

  /// Envia lote de arquivos usando FormData
  Future<SyncHttpResponse> _sendFileBatch(List<SyncLog> batch) async {
    final formData = FormData();
    final fileIds = <String>[];

    // Processar cada arquivo do lote
    for (int i = 0; i < batch.length; i++) {
      final log = batch[i];
      final media = _parseLogData(log);

      // Extrair e validar base64Content
      final base64Data = media['base64Content']?.toString();
      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('Campo base64Content não encontrado para ${log.entityId}');
      }

      final (extension, contentType) = _getFileTypeInfo(media);
      final fileName = 'file_${log.entityId}_$i.$extension';
      
      try {
        final multipartFile = _createMultipartFile(base64Data, fileName, contentType);
        formData.files.add(MapEntry('files', multipartFile));
        fileIds.add(log.entityId);
      } catch (e) {
        throw Exception('Erro ao processar arquivo ${log.entityId}: $e');
      }
    }

    // Adicionar metadados ao FormData
    formData.fields.add(MapEntry('fileIds', jsonEncode(fileIds)));
    formData.fields.add(MapEntry('logs', jsonEncode(_createLogsMetadata(batch))));

    final syncConfig = _getSyncConfig();
    return await syncConfig.httpPost(syncConfig.fileSyncEndpoint, data: formData);
  }

  /// Cria metadados dos logs sem base64Content
  List<Map<String, dynamic>> _createLogsMetadata(List<SyncLog> batch) {
    return batch.map((log) {
      Map<String, dynamic> media;
      try {
        media = log.dataJson.isEmpty ? {} : _parseLogData(log);
      } catch (e) {
        media = {}; // Usar mapa vazio em caso de erro
      }

      // Remover base64Content para evitar duplicação
      media.remove('base64Content');

      return {
        'entityType': log.entityType,
        'operation': log.operation.value,
        'data': media,
        'createdAt': log.createdAt.toIso8601String(),
      };
    }).toList();
  }

  /// Envia lote de dados regulares usando JSON
  Future<SyncHttpResponse> _sendDataBatch(
      List<SyncLog> batch, SyncBatchType type) async {
    final syncConfig = _getSyncConfig();

    final batchData = {
      'type': type.displayName,
      'logs': batch.map((log) => _createDataLogEntry(log)).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await syncConfig.httpPost(syncConfig.dataSyncEndpoint, data: batchData);
  }

  /// Cria entrada de log para envio de dados
  Map<String, dynamic> _createDataLogEntry(SyncLog log) {
    dynamic data;
    try {
      if (log.dataJson.isEmpty) {
        data = {};
      } else {
        data = _parseLogData(log);
        // Remover base64Content para evitar envio desnecessário
        if (data is Map<String, dynamic>) {
          data.remove('base64Content');
        }
      }
    } catch (e) {
      data = {}; // Usar objeto vazio em caso de erro
    }

    return {
      'syncId': log.syncId,
      'entityType': log.entityType,
      'entityId': log.entityId,
      'operation': log.operation.value,
      'data': data,
      'createdAt': log.createdAt.toIso8601String(),
    };
  }

  /// Registra um log de erro para um log de sincronização específico
  Future<void> _registerErrorLog({
    required SyncLog log,
    required dynamic error,
    required Map<String, dynamic> context,
  }) async {
    try {
      final sanitizedDataJson = _sanitizeDataForError(log.dataJson);

      await _errorManager.logError(
        message: error.toString(),
        stackTrace: error is Exception ? error.toString() : null,
        metadata: {
          'syncLogId': log.syncId,
          'originalData': sanitizedDataJson,
          'context': context,
        },
        category: _tag,
        entityType: log.entityType,
        entityId: log.entityId,
      );

      await _syncLogger.incrementRetryCount(log.syncId);
      await _syncLogger.setLastError(log.syncId, error.toString());
    } catch (e) {
      SyncUtils.debugLog('Erro ao registrar log de erro: $e', tag: _tag);
    }
  }

  /// Sanitiza dados removendo base64Content para logs de erro
  String _sanitizeDataForError(String dataJson) {
    if (dataJson.isEmpty) return '{}';
    
    try {
      final data = jsonDecode(dataJson) as Map<String, dynamic>;
      data.remove('base64Content');
      return jsonEncode(data);
    } catch (e) {
      return '{"error": "Dados não puderam ser processados"}';
    }
  }
}
