/// Resultado do envio de erros
class SyncErrorReportResult {
  final bool success;
  final int sentCount;
  final int failedCount;
  final List<String> sentErrorIds;
  final List<String> failedErrorIds;
  final String? errorMessage;

  const SyncErrorReportResult({
    required this.success,
    required this.sentCount,
    required this.failedCount,
    required this.sentErrorIds,
    required this.failedErrorIds,
    this.errorMessage,
  });

  /// Cria um resultado de sucesso vazio
  static const SyncErrorReportResult empty = SyncErrorReportResult(
    success: true,
    sentCount: 0,
    failedCount: 0,
    sentErrorIds: [],
    failedErrorIds: [],
  );

  /// Cria um resultado de falha com base em uma lista de erros
  factory SyncErrorReportResult.failure({
    required List<String> errorIds,
    required String errorMessage,
    List<String> sentErrorIds = const [],
  }) {
    return SyncErrorReportResult(
      success: false,
      sentCount: sentErrorIds.length,
      failedCount: errorIds.length - sentErrorIds.length,
      sentErrorIds: sentErrorIds,
      failedErrorIds: errorIds.where((id) => !sentErrorIds.contains(id)).toList(),
      errorMessage: errorMessage,
    );
  }
}