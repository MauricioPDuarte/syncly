import '../enums/sync_log_debug_level.dart';

/// Configuração do logger
class SyncLoggerDebugConfig {
  final SyncLogDebugLevel minLevel;
  final bool enableConsoleOutput;
  final bool enableFileOutput;
  final bool enableRemoteLogging;
  final int maxLogEntries;
  final Duration logRetentionPeriod;
  final List<String> sensitiveFields;
  final bool enableStackTrace;
  final String? logFilePath;
  final String? remoteEndpoint;

  const SyncLoggerDebugConfig({
    this.minLevel = SyncLogDebugLevel.info,
    this.enableConsoleOutput = true,
    this.enableFileOutput = false,
    this.enableRemoteLogging = false,
    this.maxLogEntries = 1000,
    this.logRetentionPeriod = const Duration(days: 7),
    this.sensitiveFields = const ['password', 'token', 'secret', 'key'],
    this.enableStackTrace = false,
    this.logFilePath,
    this.remoteEndpoint,
  });
}
