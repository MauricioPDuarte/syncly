
/// Interface abstrata para cliente REST
abstract class RestClient {
  /// Timeout padrão para requisições
  Duration get timeout => const Duration(seconds: 30);
  
  /// Headers padrão para todas as requisições
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Realiza uma requisição GET
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Realiza uma requisição POST
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Realiza uma requisição PUT
  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Realiza uma requisição DELETE
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Realiza uma requisição PATCH
  Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Download de bytes
  Future<Map<String, dynamic>> downloadBytes(
    String url, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
    Duration? timeout,
  });

  /// Upload de arquivo
  Future<Map<String, dynamic>> uploadFile(
    String url,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? fields,
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
  });

  /// Configura interceptadores (se suportado pela implementação)
  void configureInterceptors();

  /// Limpa cache/cookies (se suportado pela implementação)
  Future<void> clearCache();
}