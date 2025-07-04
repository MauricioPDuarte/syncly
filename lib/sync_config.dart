import 'core/interfaces/i_download_strategy.dart';
import 'core/theme/sync_theme.dart';
import 'core/entities/sync_http_response.dart';
import 'dart:typed_data';

/// Configuração centralizada para o sistema de sincronização
///
/// Esta classe deve ser implementada pelo usuário para fornecer todas as
/// dependências necessárias para o funcionamento do sync de forma simples e centralizada.
abstract class SyncConfig {
  // ========== CONFIGURAÇÕES BÁSICAS ==========

  /// Nome da aplicação (usado em logs e notificações)
  String get appName;

  /// Versão da aplicação
  String get appVersion;

  /// Habilitar logs de debug
  bool get enableDebugLogs => false;

  /// Habilitar sincronização em background
  bool get enableBackgroundSync => true;

  // ========== CONFIGURAÇÕES DE TEMPO ==========

  /// Intervalo entre sincronizações automáticas
  Duration get syncInterval => const Duration(minutes: 5);

  /// Intervalo para sincronização em background
  Duration get backgroundSyncInterval => const Duration(minutes: 15);

  /// Número máximo de tentativas de retry
  int get maxRetryAttempts => 3;

  /// Timeout para operações de rede
  Duration get networkTimeout => const Duration(seconds: 30);

  // ========== CONFIGURAÇÕES DE LOTE ==========

  /// Tamanho máximo de lote para dados
  int get maxDataBatchSize => 20;

  /// Tamanho máximo de lote para arquivos
  int get maxFileBatchSize => 5;

  // ========== TEMA (OPCIONAL) ==========

  /// Tema personalizado para componentes do sync
  SyncTheme? get theme => null;

  // ========== MÉTODOS OBRIGATÓRIOS - HTTP ==========

  /// Implementar requisição GET
  Future<SyncHttpResponse<T>> httpGet<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Implementar requisição POST
  Future<SyncHttpResponse<T>> httpPost<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Implementar requisição PUT
  Future<SyncHttpResponse<T>> httpPut<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Implementar requisição DELETE
  Future<SyncHttpResponse<T>> httpDelete<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Implementar requisição PATCH
  Future<SyncHttpResponse<T>> httpPatch<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Implementar download de arquivos
  Future<SyncHttpResponse<Uint8List>> httpDownloadBytes(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
    Duration? timeout,
  });

  /// Implementar upload de arquivos
  Future<SyncHttpResponse<T>> httpUploadFile<T>(
    String url,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
  });

  // ========== MÉTODOS OBRIGATÓRIOS - AUTENTICAÇÃO ==========

  /// Verificar se o usuário está autenticado
  Future<bool> isAuthenticated();

  /// Obter ID do usuário atual
  Future<String?> getCurrentUserId();

  // ========== CONFIGURAÇÕES DE NOTIFICAÇÕES ==========

  /// Habilitar notificações do sistema de sincronização
  ///
  /// Quando habilitado, o Syncly mostrará notificações sobre o progresso
  /// da sincronização, erros e status de conectividade usando seu serviço interno.
  bool get enableNotifications => true;

  // ========== MÉTODOS OBRIGATÓRIOS - ESTRATÉGIAS DE DOWNLOAD ==========
  // REMOVIDO: downloadStrategies agora são passadas diretamente no SyncInitializer.initialize()

  // ========== MÉTODOS OBRIGATÓRIOS - LIMPEZA DE DADOS ==========

  /// Limpar dados locais antes da sincronização
  /// Este método deve ser implementado para limpar os dados do banco de dados local
  /// conforme a necessidade da aplicação
  Future<void> clearLocalData();

  // ========== MÉTODOS OPCIONAIS - CALLBACKS ==========

  /// Callback quando sincronização inicia
  Future<void> onSyncStarted() async {}

  /// Callback quando sincronização termina com sucesso
  Future<void> onSyncCompleted() async {}

  /// Callback quando sincronização falha
  Future<void> onSyncFailed(String error) async {}

  /// Callback quando entra em modo offline
  Future<void> onOfflineMode() async {}

  /// Callback quando volta a ficar online
  Future<void> onOnlineMode() async {}

  // ========== MÉTODOS OPCIONAIS - CONFIGURAÇÕES AVANÇADAS ==========

  /// URL base para endpoints de sincronização
  String? get baseUrl => null;

  /// Endpoint para sincronização de dados
  String get dataSyncEndpoint => '/sync/batch';

  /// Endpoint para sincronização de arquivos
  String get fileSyncEndpoint => '/sync/files';

  /// Headers padrão para todas as requisições
  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Configurações específicas do WorkManager para background sync
  Map<String, dynamic> get backgroundSyncConfig => {
        'requiresCharging': false,
        'requiresDeviceIdle': false,
        'requiresBatteryNotLow': false,
        'requiresStorageNotLow': false,
      };

  /// Cria o adapter interno para as interfaces do sync
}
