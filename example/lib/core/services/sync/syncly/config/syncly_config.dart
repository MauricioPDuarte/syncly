import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';

import 'package:syncly_example/core/services/sync/syncly/downloaders/todo_downloader.dart';
import 'package:syncly_example/core/services/rest_client/rest_client.dart';

/// Provider de sincronização personalizado para o Syncly Example
///
/// Centraliza todas as configurações e dependências do sistema de sync,
/// migrando do sistema antigo de adapters para o novo sistema unificado.
class SynclyConfig extends SyncConfig {
  // Adapters reutilizados do sistema antigo
  late final List<IDownloadStrategy> _downloadStrategies;
  RestClient? _restClient;

  SynclyConfig() {
    _initializeProviders();
  }

  void _initializeProviders() {
    // Inicializa as estratégias de download
    _downloadStrategies = [TodoDownloader()];
  }

  /// Obtém o RestClient de forma lazy
  RestClient get restClient {
    _restClient ??= Modular.get<RestClient>();
    return _restClient!;
  }

  /// Método simplificado para inicializar o sistema de sincronização
  /// Usa o novo SyncConfig centralizado
  static Future<void> initializeSync() async {
    final provider = Modular.get<SynclyConfig>();
    await SyncInitializer.initialize(provider);
  }

  // ========== CONFIGURAÇÕES BÁSICAS ==========

  @override
  String get appName => 'Syncly Example';

  @override
  String get appVersion => '1.0.0';

  @override
  bool get enableDebugLogs => true;

  @override
  bool get enableBackgroundSync => true;

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
  List<IDownloadStrategy> get downloadStrategies => _downloadStrategies;

  // ========== TEMA ==========

  @override
  SyncTheme? get theme => null; // Usa o tema padrão

  // ========== CONFIGURAÇÕES DE ROTAS ==========
  /// Endpoint para envio de logs de sincronização
  @override
  String get dataSyncEndpoint => '/api/sync/logs';

  /// Endpoint para envio de logs de erro
  String get errorLogsEndpoint => '/api/sync/error-logs';

  /// Endpoint para sincronização de arquivos
  @override
  String get fileSyncEndpoint => '/api/sync/files';
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
        timeout: timeout,
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
        timeout: timeout,
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
        timeout: timeout,
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
        timeout: timeout,
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
        timeout: timeout,
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
        timeout: timeout,
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
        timeout: timeout,
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

  @override
  Future<String?> getCurrentUserId() async {
    // Implementação simplificada para exemplo
    return 'example_user_123';
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

    // TODO: Implementar lógica real de limpeza conforme necessidade da aplicação
    // Exemplo:
    // await database.delete('todos');
    // await database.delete('sync_logs');
  }

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
