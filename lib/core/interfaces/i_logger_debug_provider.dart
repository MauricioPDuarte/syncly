import '../entities/sync_log_debug.dart';
import '../entities/sync_logger_debug_config.dart';
import '../enums/sync_log_debug_level.dart';

/// Níveis de log do sistema de sincronização

/// Entrada de log do sistema de sincronização

/// Interface para provedor de logging do sistema de sincronização
abstract class ISyncLoggerDebugProvider {
  /// Inicializa o sistema de logging
  Future<void> initialize(SyncLoggerDebugConfig config);

  /// Verifica se o logger está inicializado
  bool get isInitialized;

  /// Configura o nível mínimo de log
  void setMinLevel(SyncLogDebugLevel level);

  /// Obtém o nível mínimo de log atual
  SyncLogDebugLevel get minLevel;

  /// Registra um log de debug
  void debug(
    String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  /// Registra um log de informação
  void info(
    String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  /// Registra um log de aviso
  void warning(
    String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
  });

  /// Registra um log de erro
  void error(
    String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    Object? exception,
  });

  /// Registra um log fatal
  void fatal(
    String message, {
    String? category,
    String? tag,
    Map<String, dynamic>? metadata,
    String? stackTrace,
    Object? exception,
  });

  /// Registra uma entrada de log personalizada
  void log(SyncLogDebug entry);

  /// Obtém logs por nível
  Future<List<SyncLogDebug>> getLogsByLevel(
    SyncLogDebugLevel level, {
    int? limit,
    DateTime? since,
  });

  /// Obtém logs por categoria
  Future<List<SyncLogDebug>> getLogsByCategory(
    String category, {
    int? limit,
    DateTime? since,
  });

  /// Obtém logs por tag
  Future<List<SyncLogDebug>> getLogsByTag(
    String tag, {
    int? limit,
    DateTime? since,
  });

  /// Obtém todos os logs
  Future<List<SyncLogDebug>> getAllLogs({
    int? limit,
    DateTime? since,
    SyncLogDebugLevel? minLevel,
  });

  /// Limpa logs antigos
  Future<void> clearOldLogs({
    Duration? olderThan,
    int? keepLast,
  });

  /// Limpa todos os logs
  Future<void> clearAllLogs();

  /// Exporta logs para arquivo
  Future<String> exportLogs({
    String? filePath,
    DateTime? since,
    SyncLogDebugLevel? minLevel,
  });

  /// Envia logs para servidor remoto
  Future<bool> uploadLogs({
    DateTime? since,
    SyncLogDebugLevel? minLevel,
  });

  /// Obtém estatísticas dos logs
  Future<Map<String, dynamic>> getLogStatistics();

  /// Stream para monitorar novos logs
  Stream<SyncLogDebug> get logStream;

  /// Configura filtros de dados sensíveis
  void setSensitiveFields(List<String> fields);

  /// Sanitiza dados removendo informações sensíveis
  Map<String, dynamic> sanitizeData(Map<String, dynamic> data);

  /// Fecha o sistema de logging
  Future<void> close();
}
