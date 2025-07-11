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
  ///
  /// [lastSyncTimestamp] - Data da última sincronização para sincronização incremental.
  /// Se null, fará sincronização completa.
  Future<DownloadResult> downloadData({DateTime? lastSyncTimestamp});
}

/// Resultado do download de dados
class DownloadResult {
  final bool success;
  final String message;
  final int itemsDownloaded;
  final Map<String, dynamic>? metadata;
  
  /// Lista de IDs de entidades que foram excluídas no servidor
  /// e devem ser removidas localmente
  final Map<String, List<String>>? deletedEntities;
  
  /// Indica se foi uma sincronização incremental
  final bool isIncremental;

  const DownloadResult({
    required this.success,
    required this.message,
    this.itemsDownloaded = 0,
    this.metadata,
    this.deletedEntities,
    this.isIncremental = false,
  });

  factory DownloadResult.success({
    required String message,
    int itemsDownloaded = 0,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? deletedEntities,
    bool isIncremental = false,
  }) {
    return DownloadResult(
      success: true,
      message: message,
      itemsDownloaded: itemsDownloaded,
      metadata: metadata,
      deletedEntities: deletedEntities,
      isIncremental: isIncremental,
    );
  }

  factory DownloadResult.failure(String message) {
    return DownloadResult(
      success: false,
      message: message,
    );
  }
}