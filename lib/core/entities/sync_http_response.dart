/// Resposta HTTP para o sistema de sincronização
class SyncHttpResponse<T> {
  final T? data;
  final int statusCode;
  final Map<String, dynamic> headers;
  final String? statusMessage;

  const SyncHttpResponse({
    this.data,
    required this.statusCode,
    required this.headers,
    this.statusMessage,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
}
