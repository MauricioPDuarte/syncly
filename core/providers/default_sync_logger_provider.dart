import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../entities/sync_log_debug.dart';
import '../entities/sync_logger_debug_config.dart';
import '../enums/sync_log_debug_level.dart';
import '../interfaces/i_logger_debug_provider.dart';

/// Implementação padrão do logger que sempre está disponível
class DefaultSyncLoggerProvider implements ISyncLoggerDebugProvider {
  static final DefaultSyncLoggerProvider _instance =
      DefaultSyncLoggerProvider._internal();
  factory DefaultSyncLoggerProvider() => _instance;
  DefaultSyncLoggerProvider._internal();

  bool _isInitialized = false;
  SyncLogDebugLevel _minLevel = SyncLogDebugLevel.info;
  final List<SyncLogDebug> _logs = [];
  final StreamController<SyncLogDebug> _logStreamController =
      StreamController<SyncLogDebug>.broadcast();
  List<String> _sensitiveFields = ['password', 'token', 'secret', 'key'];
  int _maxLogEntries = 1000;

  @override
  Future<void> initialize(SyncLoggerDebugConfig config) async {
    _minLevel = config.minLevel;
    _sensitiveFields = config.sensitiveFields;
    _maxLogEntries = config.maxLogEntries;
    _isInitialized = true;

    info('DefaultSyncLoggerProvider inicializado', category: 'Logger');
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  void setMinLevel(SyncLogDebugLevel level) {
    _minLevel = level;
  }

  @override
  SyncLogDebugLevel get minLevel => _minLevel;

  @override
  void debug(String message,
      {String? category, String? tag, Map<String, dynamic>? metadata}) {
    _log(SyncLogDebugLevel.debug, message,
        category: category, tag: tag, metadata: metadata);
  }

  @override
  void info(String message,
      {String? category, String? tag, Map<String, dynamic>? metadata}) {
    _log(SyncLogDebugLevel.info, message,
        category: category, tag: tag, metadata: metadata);
  }

  @override
  void warning(String message,
      {String? category, String? tag, Map<String, dynamic>? metadata}) {
    _log(SyncLogDebugLevel.warning, message,
        category: category, tag: tag, metadata: metadata);
  }

  @override
  void error(String message,
      {String? category,
      String? tag,
      Map<String, dynamic>? metadata,
      String? stackTrace,
      Object? exception}) {
    _log(SyncLogDebugLevel.error, message,
        category: category,
        tag: tag,
        metadata: metadata,
        stackTrace: stackTrace);
  }

  @override
  void fatal(String message,
      {String? category,
      String? tag,
      Map<String, dynamic>? metadata,
      String? stackTrace,
      Object? exception}) {
    _log(SyncLogDebugLevel.fatal, message,
        category: category,
        tag: tag,
        metadata: metadata,
        stackTrace: stackTrace);
  }

  @override
  void log(SyncLogDebug entry) {
    if (entry.level.index >= _minLevel.index) {
      _logs.add(entry);
      _logStreamController.add(entry);

      // Limita o número de logs em memória
      if (_logs.length > _maxLogEntries) {
        _logs.removeAt(0);
      }

      // Output para console em modo debug
      if (kDebugMode) {
        debugPrint('[SYNC] ${entry.toString()}');
      }
    }
  }

  void _log(SyncLogDebugLevel level, String message,
      {String? category,
      String? tag,
      Map<String, dynamic>? metadata,
      String? stackTrace}) {
    final entry = SyncLogDebug(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: category,
      tag: tag,
      metadata: metadata != null ? sanitizeData(metadata) : null,
      stackTrace: stackTrace,
    );

    log(entry);
  }

  @override
  Future<List<SyncLogDebug>> getLogsByLevel(SyncLogDebugLevel level,
      {int? limit, DateTime? since}) async {
    var filtered = _logs.where((log) => log.level == level);

    if (since != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(since));
    }

    var result = filtered.toList();
    if (limit != null && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<List<SyncLogDebug>> getLogsByCategory(String category,
      {int? limit, DateTime? since}) async {
    var filtered = _logs.where((log) => log.category == category);

    if (since != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(since));
    }

    var result = filtered.toList();
    if (limit != null && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<List<SyncLogDebug>> getLogsByTag(String tag,
      {int? limit, DateTime? since}) async {
    var filtered = _logs.where((log) => log.tag == tag);

    if (since != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(since));
    }

    var result = filtered.toList();
    if (limit != null && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<List<SyncLogDebug>> getAllLogs(
      {int? limit, DateTime? since, SyncLogDebugLevel? minLevel}) async {
    var filtered = _logs.where((log) => true);

    if (since != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(since));
    }

    if (minLevel != null) {
      filtered = filtered.where((log) => log.level.index >= minLevel.index);
    }

    var result = filtered.toList();
    if (limit != null && result.length > limit) {
      result = result.take(limit).toList();
    }

    return result;
  }

  @override
  Future<void> clearOldLogs({Duration? olderThan, int? keepLast}) async {
    if (olderThan != null) {
      final cutoff = DateTime.now().subtract(olderThan);
      _logs.removeWhere((log) => log.timestamp.isBefore(cutoff));
    }

    if (keepLast != null && _logs.length > keepLast) {
      final toRemove = _logs.length - keepLast;
      _logs.removeRange(0, toRemove);
    }
  }

  @override
  Future<void> clearAllLogs() async {
    _logs.clear();
  }

  @override
  Future<String> exportLogs(
      {String? filePath, DateTime? since, SyncLogDebugLevel? minLevel}) async {
    final logs = await getAllLogs(since: since, minLevel: minLevel);
    final jsonLogs = logs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonLogs);
  }

  @override
  Future<bool> uploadLogs(
      {DateTime? since, SyncLogDebugLevel? minLevel}) async {
    // Implementação básica - sempre retorna false pois não há endpoint configurado
    warning('Upload de logs não implementado no DefaultSyncLoggerProvider',
        category: 'Logger');
    return false;
  }

  @override
  Future<Map<String, dynamic>> getLogStatistics() async {
    final stats = <String, int>{};
    for (final level in SyncLogDebugLevel.values) {
      stats[level.name] = _logs.where((log) => log.level == level).length;
    }

    return {
      'totalLogs': _logs.length,
      'byLevel': stats,
      'oldestLog':
          _logs.isNotEmpty ? _logs.first.timestamp.toIso8601String() : null,
      'newestLog':
          _logs.isNotEmpty ? _logs.last.timestamp.toIso8601String() : null,
    };
  }

  @override
  Stream<SyncLogDebug> get logStream => _logStreamController.stream;

  @override
  void setSensitiveFields(List<String> fields) {
    _sensitiveFields = fields;
  }

  @override
  Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      if (_sensitiveFields.any(
          (field) => entry.key.toLowerCase().contains(field.toLowerCase()))) {
        sanitized[entry.key] = '***REDACTED***';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  @override
  Future<void> close() async {
    await _logStreamController.close();
    _logs.clear();
    _isInitialized = false;
  }
}
