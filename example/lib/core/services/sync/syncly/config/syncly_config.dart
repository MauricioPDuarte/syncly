import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncly_example/core/services/rest_client/rest_client.dart';
import 'package:syncly_example/modules/todo/data/sync/todo_downloader.dart';

/// Provider de sincronização personalizado para o Syncly Example
///
/// Centraliza todas as configurações e dependências do sistema de sync,
/// migrando do sistema antigo de adapters para o novo sistema unificado.
class SynclyConfig extends SyncConfig {
  // Adapters reutilizados do sistema antigo
  RestClient? _restClient;

  /// Obtém o RestClient de forma lazy
  RestClient get restClient {
    _restClient ??= Modular.get<RestClient>();
    return _restClient!;
  }

  // ========== CONFIGURAÇÕES BÁSICAS ==========

  @override
  String get appName => 'Syncly Example';

  @override
  String get appVersion => '1.0.0';

  @override
  bool get enableDebugLogs => true;

  @override
  bool get enableBackgroundSync => true; // Ativada por padrão - pode ser desabilitada

  @override
  bool get enableNotifications => true;

  // ========== CONFIGURAÇÕES DE TEMPO ==========

  @override
  Duration get syncInterval => const Duration(minutes: 5);

  @override
  Duration get backgroundSyncInterval => const Duration(minutes: 15);

  @override
  int get maxRetryAttempts => 3;

  @override
  Duration get networkTimeout => const Duration(seconds: 30);

  // ========== ESTRATÉGIAS DE DOWNLOAD ==========

  @override
  List<IDownloadStrategy> get downloadStrategies => [
        // Estratégias de download configuradas
        Modular.get<TodoDownloader>(),
      ];

  @override
  SyncTheme? get theme => null; // Usa o tema padrão

  // ========== CONFIGURAÇÕES DE ROTAS ==========
  /// Endpoint para envio de logs de sincronização
  @override
  String get dataSyncEndpoint => '/api/sync/logs';

  /// Endpoint para sincronização de arquivos
  @override
  String get fileSyncEndpoint => '/api/sync/files';

  /// Endpoint para envio de erros
  @override
  String get errorReportingEndpoint => '/api/sync/errors';
  // ========== IMPLEMENTAÇÃO HTTP ==========

  @override
  Future<SyncHttpResponse<T>> httpGet<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.get(
        url,
        queryParameters: queryParameters,
        headers: headers?.cast<String, String>(),
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  @override
  Future<SyncHttpResponse<T>> httpPost<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.post(
        url,
        data as Map<String, dynamic>? ?? {},
        headers: headers?.cast<String, String>(),
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  @override
  Future<SyncHttpResponse<T>> httpPut<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.put(
        url,
        data as Map<String, dynamic>? ?? {},
        headers: headers?.cast<String, String>(),
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  @override
  Future<SyncHttpResponse<T>> httpDelete<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.delete(
        url,
        headers: headers?.cast<String, String>(),
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  @override
  Future<SyncHttpResponse<T>> httpPatch<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.patch(
        url,
        data as Map<String, dynamic>? ?? {},
        headers: headers?.cast<String, String>(),
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  @override
  Future<SyncHttpResponse<Uint8List>> httpDownloadBytes(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.downloadBytes(
        url,
        headers: headers?.cast<String, String>(),
        onProgress: onProgress,
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<Uint8List>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<Uint8List>(e);
    }
  }

  @override
  Future<SyncHttpResponse<T>> httpUploadFile<T>(
    String url,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
  }) async {
    try {
      final response = await restClient.uploadFile(
        url,
        filePath,
        fileName: fileName,
        fields: fields,
        headers: headers?.cast<String, String>(),
        onProgress: onProgress,
        timeout: timeout ?? networkTimeout,
      );

      return _buildSyncHttpResponse<T>(response);
    } catch (e) {
      return _buildErrorSyncHttpResponse<T>(e);
    }
  }

  // ========== IMPLEMENTAÇÃO DE AUTENTICAÇÃO ==========

  @override
  Future<bool> isAuthenticated() async {
    // Implementação simplificada para exemplo - sempre autenticado
    return true;
  }

  // ========== NOTIFICAÇÕES GERENCIADAS INTERNAMENTE ==========
  // O Syncly agora possui seu próprio serviço de notificações interno
  // Não é necessário implementar métodos de notificação aqui

  // ========== IMPLEMENTAÇÃO DE LIMPEZA DE DADOS ==========

  @override
  Future<void> clearLocalData() async {
    // Implementação personalizada para limpeza de dados locais
    // Aqui você deve implementar a lógica específica da sua aplicação
    // para limpar os dados do banco de dados local antes da sincronização

    // Exemplo: limpar tabelas específicas, resetar contadores, etc.
    debugPrint('Limpando dados locais antes da sincronização...');
  }

  // ========== IMPLEMENTAÇÃO DE SINCRONIZAÇÃO INCREMENTAL ==========

  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_sync_timestamp');

      if (timestamp != null) {
        final dateTime = DateTime.parse(timestamp);
        debugPrint('Timestamp da última sincronização obtido: $dateTime');
        return dateTime;
      }

      debugPrint(
          'Nenhum timestamp de sincronização encontrado - primeira sincronização');
      return null;
    } catch (e) {
      debugPrint('Erro ao obter timestamp da última sincronização: $e');
      return null;
    }
  }

  @override
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_timestamp', timestamp.toIso8601String());
      debugPrint('Timestamp da última sincronização salvo: $timestamp');
    } catch (e) {
      debugPrint('Erro ao salvar timestamp da última sincronização: $e');
    }
  }

  @override
  bool get useIncrementalSync => true; // Habilitar sincronização incremental

  @override
  Duration get maxIncrementalSyncInterval =>
      const Duration(days: 3); // Sincronização completa a cada 3 dias

  // ========== CALLBACKS DE SINCRONIZAÇÃO ==========

  @override
  Future<void> onSyncStarted() async {
    // Implementar lógica personalizada quando sync inicia
  }

  @override
  Future<void> onSyncCompleted() async {
    // Implementar lógica personalizada quando sync completa
  }

  @override
  Future<void> onSyncFailed(String error) async {
    // Implementar lógica personalizada quando sync falha
  }

  // ========== MÉTODOS AUXILIARES ==========

  /// Constrói uma SyncHttpResponse a partir da resposta do RestClient
  SyncHttpResponse<T> _buildSyncHttpResponse<T>(Map<String, dynamic> response) {
    return SyncHttpResponse<T>(
      data: response['data'] as T?,
      statusCode: response['statusCode'] as int,
      headers: response['headers'] as Map<String, dynamic>,
      statusMessage: response['success'] == true ? 'Success' : 'Error',
    );
  }

  /// Constrói uma SyncHttpResponse de erro
  SyncHttpResponse<T> _buildErrorSyncHttpResponse<T>(dynamic error) {
    return SyncHttpResponse<T>(
      data: null,
      statusCode: 500,
      headers: {},
      statusMessage: error.toString(),
    );
  }
}
