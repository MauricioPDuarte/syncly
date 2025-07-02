/// Interface para estratégias de download de dados
///
/// Define o contrato que todas as estratégias de download devem implementar
abstract class IDownloadStrategy {
  /// Executa o download de dados específicos do servidor
  ///
  /// Cada implementação deve ser responsável por:
  /// - Buscar dados específicos do servidor
  /// - Processar e salvar os dados no banco local
  /// - Retornar informações sobre os dados baixados
  Future<DownloadResult> downloadData();
}

/// Resultado do download de dados
class DownloadResult {
  final bool success;
  final String message;
  final int itemsDownloaded;
  final Map<String, dynamic>? metadata;

  const DownloadResult({
    required this.success,
    required this.message,
    this.itemsDownloaded = 0,
    this.metadata,
  });

  factory DownloadResult.success({
    required String message,
    int itemsDownloaded = 0,
    Map<String, dynamic>? metadata,
  }) {
    return DownloadResult(
      success: true,
      message: message,
      itemsDownloaded: itemsDownloaded,
      metadata: metadata,
    );
  }

  factory DownloadResult.failure(String message) {
    return DownloadResult(
      success: false,
      message: message,
    );
  }
}