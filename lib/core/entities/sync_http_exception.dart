import '../enums/sync_http_exception_type.dart';

class SyncHttpException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;
  final SyncHttpExceptionType type;

  const SyncHttpException({
    required this.message,
    this.statusCode,
    this.response,
    required this.type,
  });

  @override
  String toString() => 'SyncHttpException: $message (Status: $statusCode)';
}
