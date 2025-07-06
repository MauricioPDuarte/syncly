/// Configuração para envio de erros
class SyncErrorReportConfig {
  final String endpoint;
  final int maxRetries;
  final Duration retryDelay;
  final int batchSize;
  final bool includeStackTrace;
  final bool includeMetadata;

  const SyncErrorReportConfig({
    required this.endpoint,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.batchSize = 10,
    this.includeStackTrace = true,
    this.includeMetadata = true,
  });
}