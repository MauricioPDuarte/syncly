import 'core/interfaces/i_download_strategy.dart';
import 'core/theme/sync_theme.dart';
import 'core/entities/sync_http_response.dart';
import 'dart:typed_data';

// Imports necessários para o exemplo de implementação
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Habilitar notificações
  bool get enableNotifications => true;

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

  /// Obter token de autenticação atual
  Future<String?> getAuthToken();

  /// Obter headers de autenticação
  Future<Map<String, String>> getAuthHeaders();

  /// Obter ID do usuário atual
  Future<String?> getCurrentUserId();

  /// Obter informações da sessão atual
  Future<Map<String, dynamic>?> getCurrentSession();

  /// Callback quando token expira ou é inválido
  Future<void> onAuthenticationFailed();

  // ========== MÉTODOS OBRIGATÓRIOS - NOTIFICAÇÕES ==========

  /// Inicializar sistema de notificações
  Future<void> initializeNotifications();

  /// Verificar se notificações estão habilitadas
  Future<bool> areNotificationsEnabled();

  /// Mostrar notificação simples
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? notificationId,
  });

  /// Mostrar notificação de progresso
  Future<void> showProgressNotification({
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    int? notificationId,
  });

  /// Cancelar notificação
  Future<void> cancelNotification(int notificationId);

  /// Cancelar todas as notificações
  Future<void> cancelAllNotifications();

  // ========== MÉTODOS OBRIGATÓRIOS - ESTRATÉGIAS DE DOWNLOAD ==========

  /// Lista de estratégias de download personalizadas
  /// Cada estratégia define como baixar dados específicos do servidor
  List<IDownloadStrategy> get downloadStrategies;

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

  /// Endpoint para download de dados
  String get downloadEndpoint => '/sync/download';

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

// ========== EXEMPLO DE IMPLEMENTAÇÃO ==========

/// Exemplo de implementação completa do SyncConfig
/// 
/// Esta classe mostra como implementar todos os métodos obrigatórios
/// do SyncConfig usando Dio para HTTP e SharedPreferences para autenticação.
class ExampleSyncConfig extends SyncConfig {
  late final Dio _dio;
  
  ExampleSyncConfig() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl ?? '';
    _dio.options.connectTimeout = networkTimeout;
    _dio.options.receiveTimeout = networkTimeout;
  }

  // ========== CONFIGURAÇÕES BÁSICAS ==========
  @override
  String get appName => 'Meu App';

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

  // ========== CONFIGURAÇÕES DE LOTE ==========
  @override
  int get maxDataBatchSize => 20;

  @override
  int get maxFileBatchSize => 5;

  // ========== CONFIGURAÇÕES DE ENDPOINTS ==========
  @override
  String? get baseUrl => 'https://api.meuapp.com';

  @override
  String get dataSyncEndpoint => '/api/sync/data';

  @override
  String get fileSyncEndpoint => '/api/sync/files';

  @override
  String get downloadEndpoint => '/api/sync/download';

  @override
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-App-Version': appVersion,
  };

  // ========== MÉTODOS HTTP ==========
  @override
  Future<SyncHttpResponse<T>> httpGet<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final authHeaders = await getAuthHeaders();
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
      );
      
      return SyncHttpResponse<T>(
        data: response.data,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await onAuthenticationFailed();
      }
      return SyncHttpResponse<T>(
        data: null,
        statusCode: e.response?.statusCode ?? 0,
        headers: e.response?.headers.map ?? {},
        statusMessage: e.message ?? 'Erro na requisição',
      );
    } catch (e) {
      return SyncHttpResponse<T>(
        data: null,
        statusCode: 0,
        headers: {},
        statusMessage: e.toString(),
      );
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
      final authHeaders = await getAuthHeaders();
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
      );
      
      return SyncHttpResponse<T>(
         data: response.data,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await onAuthenticationFailed();
      }
      return SyncHttpResponse<T>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro na requisição',
       );
    } catch (e) {
      return SyncHttpResponse<T>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
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
      final authHeaders = await getAuthHeaders();
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
      );
      
      return SyncHttpResponse<T>(
         data: response.data,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         await onAuthenticationFailed();
       }
       return SyncHttpResponse<T>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro na requisição',
       );
     } catch (e) {
       return SyncHttpResponse<T>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
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
      final authHeaders = await getAuthHeaders();
      final response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
      );
      
      return SyncHttpResponse<T>(
         data: response.data,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         await onAuthenticationFailed();
       }
       return SyncHttpResponse<T>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro na requisição',
       );
     } catch (e) {
       return SyncHttpResponse<T>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
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
      final authHeaders = await getAuthHeaders();
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
      );
      
      return SyncHttpResponse<T>(
         data: response.data,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         await onAuthenticationFailed();
       }
       return SyncHttpResponse<T>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro na requisição',
       );
     } catch (e) {
       return SyncHttpResponse<T>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
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
      final authHeaders = await getAuthHeaders();
      final response = await _dio.get<List<int>>(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: {...defaultHeaders, ...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onProgress,
      );
      
      return SyncHttpResponse<Uint8List>(
         data: response.data != null ? Uint8List.fromList(response.data!) : null,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         await onAuthenticationFailed();
       }
       return SyncHttpResponse<Uint8List>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro no download',
       );
     } catch (e) {
       return SyncHttpResponse<Uint8List>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
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
      final authHeaders = await getAuthHeaders();
      final formData = FormData();
      
      // Adicionar arquivo
      formData.files.add(MapEntry(
        'file',
        await MultipartFile.fromFile(
          filePath,
          filename: fileName ?? filePath.split('/').last,
        ),
      ));
      
      // Adicionar campos extras
      if (fields != null) {
        for (final entry in fields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
      }
      
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {...authHeaders, ...?headers},
          receiveTimeout: timeout ?? networkTimeout,
        ),
        onSendProgress: onProgress,
      );
      
      return SyncHttpResponse<T>(
         data: response.data,
         statusCode: response.statusCode ?? 0,
         headers: response.headers.map,
       );
     } on DioException catch (e) {
       if (e.response?.statusCode == 401) {
         await onAuthenticationFailed();
       }
       return SyncHttpResponse<T>(
         data: null,
         statusCode: e.response?.statusCode ?? 0,
         headers: e.response?.headers.map ?? {},
         statusMessage: e.message ?? 'Erro no upload',
       );
     } catch (e) {
       return SyncHttpResponse<T>(
         data: null,
         statusCode: 0,
         headers: {},
         statusMessage: e.toString(),
       );
    }
  }

  // ========== MÉTODOS DE AUTENTICAÇÃO ==========
  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getAuthToken() async {
    // Implementar usando SharedPreferences ou secure storage
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao obter token: $e');
      }
      return null;
    }
  }

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAuthToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
      };
    }
    return {};
  }

  @override
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao obter user ID: $e');
      }
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentSession() async {
    final userId = await getCurrentUserId();
    final token = await getAuthToken();
    
    if (userId != null && token != null) {
      return {
        'userId': userId,
        'token': token,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'appVersion': appVersion,
      };
    }
    return null;
  }

  @override
  Future<void> onAuthenticationFailed() async {
    try {
      // Limpar dados de autenticação
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      
      if (enableDebugLogs) {
        print('Autenticação falhou - dados limpos');
      }
      
      // Aqui você pode implementar navegação para tela de login
      // ou mostrar uma notificação para o usuário
      
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao limpar dados de autenticação: $e');
      }
    }
  }

  // ========== MÉTODOS DE NOTIFICAÇÕES ==========
  @override
  Future<void> initializeNotifications() async {
    if (!enableNotifications) return;
    
    try {
      // Implementar inicialização usando flutter_local_notifications
      // ou outro plugin de notificações
      
      if (enableDebugLogs) {
        print('Sistema de notificações inicializado');
      }
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao inicializar notificações: $e');
      }
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return enableNotifications;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? notificationId,
  }) async {
    if (!await areNotificationsEnabled()) return;
    
    try {
      // Implementar exibição de notificação
      if (enableDebugLogs) {
        print('Notificação: $title - $message');
      }
      
      // Exemplo de implementação:
      // await flutterLocalNotificationsPlugin.show(
      //   notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      //   title,
      //   message,
      //   NotificationDetails(...),
      // );
      
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao mostrar notificação: $e');
      }
    }
  }

  @override
  Future<void> showProgressNotification({
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    int? notificationId,
  }) async {
    if (!await areNotificationsEnabled()) return;
    
    try {
      final percentage = (progress / maxProgress * 100).round();
      
      if (enableDebugLogs) {
        print('Progresso: $title - $message ($percentage%)');
      }
      
      // Implementar notificação de progresso
      // await flutterLocalNotificationsPlugin.show(
      //   notificationId ?? 1,
      //   title,
      //   '$message ($percentage%)',
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'progress_channel',
      //       'Progress Notifications',
      //       showProgress: true,
      //       maxProgress: maxProgress,
      //       progress: progress,
      //     ),
      //   ),
      // );
      
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao mostrar notificação de progresso: $e');
      }
    }
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
    try {
      // Implementar cancelamento de notificação específica
      // await flutterLocalNotificationsPlugin.cancel(notificationId);
      
      if (enableDebugLogs) {
        print('Notificação $notificationId cancelada');
      }
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao cancelar notificação: $e');
      }
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      // Implementar cancelamento de todas as notificações
      // await flutterLocalNotificationsPlugin.cancelAll();
      
      if (enableDebugLogs) {
        print('Todas as notificações canceladas');
      }
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao cancelar todas as notificações: $e');
      }
    }
  }

  // ========== ESTRATÉGIAS DE DOWNLOAD ==========
  @override
  List<IDownloadStrategy> get downloadStrategies => [
    // Implementar suas estratégias personalizadas aqui
    // Exemplo:
    // UserDownloadStrategy(),
    // ProductDownloadStrategy(),
    // OrderDownloadStrategy(),
  ];

  // ========== LIMPEZA DE DADOS ==========
  @override
  Future<void> clearLocalData() async {
    try {
      // Implementar limpeza dos dados locais
      // Exemplo usando banco de dados:
      
      // final database = await DatabaseHelper.instance.database;
      // await database.delete('users');
      // await database.delete('products');
      // await database.delete('orders');
      // await database.delete('sync_logs');
      
      if (enableDebugLogs) {
        print('Dados locais limpos com sucesso');
      }
    } catch (e) {
      if (enableDebugLogs) {
        print('Erro ao limpar dados locais: $e');
      }
      rethrow;
    }
  }

  // ========== CALLBACKS OPCIONAIS ==========
  @override
  Future<void> onSyncStarted() async {
    if (enableDebugLogs) {
      print('Sincronização iniciada');
    }
    
    await showNotification(
      title: appName,
      message: 'Sincronização iniciada',
      notificationId: 100,
    );
  }

  @override
  Future<void> onSyncCompleted() async {
    if (enableDebugLogs) {
      print('Sincronização concluída com sucesso');
    }
    
    await cancelNotification(100); // Cancelar notificação de progresso
    
    await showNotification(
      title: appName,
      message: 'Sincronização concluída',
      notificationId: 101,
    );
  }

  @override
  Future<void> onSyncFailed(String error) async {
    if (enableDebugLogs) {
      print('Sincronização falhou: $error');
    }
    
    await cancelNotification(100); // Cancelar notificação de progresso
    
    await showNotification(
      title: appName,
      message: 'Erro na sincronização: $error',
      notificationId: 102,
    );
  }

  @override
  Future<void> onOfflineMode() async {
    if (enableDebugLogs) {
      print('Aplicação entrou em modo offline');
    }
  }

  @override
  Future<void> onOnlineMode() async {
    if (enableDebugLogs) {
      print('Aplicação voltou ao modo online');
    }
  }
}
