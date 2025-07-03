import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../rest_client.dart';

/// Implementação do RestClient usando Dio
class DioRestClient extends RestClient {
  late final Dio _dio;

  DioRestClient({
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: timeout ?? this.timeout,
      receiveTimeout: timeout ?? this.timeout,
      sendTimeout: timeout ?? this.timeout,
      headers: {...this.defaultHeaders, ...?defaultHeaders},
    ));

    configureInterceptors();
  }

  @override
  void configureInterceptors() {
    // Interceptador para logs (apenas em debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[DioRestClient] $obj'),
    ));

    // Interceptador para tratamento de erros
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        // Aqui você pode adicionar lógica personalizada de tratamento de erro
        debugPrint('[DioRestClient] Erro: ${error.message}');
        handler.next(error);
      },
    ));
  }

  @override
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: data,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> downloadBytes(
    String url, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
    Duration? timeout,
  }) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        onReceiveProgress: onProgress,
      );

      return {
        'data': response.data as Uint8List,
        'statusCode': response.statusCode ?? 200,
        'headers': response.headers.map,
        'success': (response.statusCode ?? 0) >= 200 &&
            (response.statusCode ?? 0) < 300,
      };
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String url,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? fields,
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
    Duration? timeout,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?fields,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: headers,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        onSendProgress: onProgress,
      );

      return _buildResponse(response);
    } catch (e) {
      return _buildErrorResponse(e);
    }
  }

  @override
  Future<void> clearCache() async {
    // Limpa o cache do Dio se necessário
    // Implementação específica pode variar dependendo das necessidades
  }

  /// Constrói resposta padronizada a partir da Response do Dio
  Map<String, dynamic> _buildResponse(Response response) {
    return {
      'data': response.data,
      'statusCode': response.statusCode ?? 200,
      'headers': response.headers.map,
      'success':
          (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300,
    };
  }

  /// Constrói resposta de erro padronizada
  Map<String, dynamic> _buildErrorResponse(dynamic error) {
    int statusCode = 500;
    String message = error.toString();

    if (error is DioException) {
      statusCode = error.response?.statusCode ?? 500;
      message = error.message ?? 'Erro desconhecido';
    }

    return {
      'data': null,
      'statusCode': statusCode,
      'headers': <String, dynamic>{},
      'success': false,
      'error': message,
    };
  }
}
