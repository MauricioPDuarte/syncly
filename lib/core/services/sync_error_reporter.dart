import '../entities/sync_error.dart';
import '../entities/sync_error_report_config.dart';
import '../entities/sync_error_report_result.dart';
import '../interfaces/i_sync_error_reporter.dart';
import '../../sync_config.dart';
import '../interfaces/i_logger_debug_provider.dart';
import 'sync_error_manager.dart';

/// Implementação do serviço de envio de erros para o backend
class SyncErrorReporter implements ISyncErrorReporter {
  static const String _tag = 'SyncErrorReporter';

  final ISyncErrorManager _errorManager;
  final ISyncLoggerDebugProvider? _loggerProvider;
  final SyncErrorReportConfig _config;
  final SyncConfig _syncConfig;

  SyncErrorReporter(
    this._errorManager,
    this._loggerProvider,
    this._config,
    this._syncConfig,
  );

  @override
  Future<SyncErrorReportResult> sendPendingErrors() async {
    try {
      final pendingErrors = await _errorManager.getPendingErrors();

      if (pendingErrors.isEmpty) {
        _loggerProvider?.info('No pending errors to send', category: _tag);
        return SyncErrorReportResult.empty;
      }

      return await sendErrors(pendingErrors);
    } catch (e) {
      _loggerProvider?.error('Failed to send pending errors: $e',
          category: _tag, exception: e);
      return SyncErrorReportResult.failure(
        errorIds: const [],
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<SyncErrorReportResult> sendError(SyncError error) async {
    return await sendErrors([error]);
  }

  @override
  Future<SyncErrorReportResult> sendErrors(List<SyncError> errors) async {
    if (errors.isEmpty) {
      return SyncErrorReportResult.empty;
    }

    final sentErrorIds = <String>[];
    final failedErrorIds = <String>[];

    try {
      // Verificar autenticação
      final authResult = await _checkAuthentication(errors);
      if (authResult != null) return authResult;

      // Processar erros em lotes
      await _processBatches(errors, sentErrorIds, failedErrorIds);

      // Marcar erros enviados como enviados
      await _markErrorsAsSent(sentErrorIds);

      final success = failedErrorIds.isEmpty;
      _logErrorReportingResult(
          sentErrorIds.length, failedErrorIds.length, success);

      return SyncErrorReportResult(
        success: success,
        sentCount: sentErrorIds.length,
        failedCount: failedErrorIds.length,
        sentErrorIds: sentErrorIds,
        failedErrorIds: failedErrorIds,
      );
    } catch (e) {
      _loggerProvider?.error('Failed to send errors: $e',
          category: _tag, exception: e);
      return SyncErrorReportResult.failure(
        errorIds: errors.map((e) => e.id).toList(),
        errorMessage: e.toString(),
        sentErrorIds: sentErrorIds,
      );
    }
  }

  @override
  Future<void> scheduleErrorReporting() async {
    try {
      await sendPendingErrors();
      _loggerProvider?.info('Error reporting scheduled and executed',
          category: _tag);
    } catch (e) {
      _loggerProvider?.error('Failed to schedule error reporting: $e',
          category: _tag, exception: e);
    }
  }

  // Métodos privados

  /// Verifica se o usuário está autenticado
  Future<SyncErrorReportResult?> _checkAuthentication(
      List<SyncError> errors) async {
    final isAuthenticated = await _syncConfig.isAuthenticated();
    if (!isAuthenticated) {
      _loggerProvider?.warning('Cannot send errors: user not authenticated',
          category: _tag);
      return SyncErrorReportResult.failure(
        errorIds: errors.map((e) => e.id).toList(),
        errorMessage: 'User not authenticated',
      );
    }
    return null;
  }

  /// Processa erros em lotes
  Future<void> _processBatches(
    List<SyncError> errors,
    List<String> sentErrorIds,
    List<String> failedErrorIds,
  ) async {
    final batches = _createBatches(errors, _config.batchSize);

    for (final batch in batches) {
      final result = await _sendErrorBatch(batch);
      sentErrorIds.addAll(result.sentErrorIds);
      failedErrorIds.addAll(result.failedErrorIds);
    }
  }

  /// Marca erros como enviados
  Future<void> _markErrorsAsSent(List<String> sentErrorIds) async {
    for (final errorId in sentErrorIds) {
      await _errorManager.markErrorAsSent(errorId);
    }
  }

  /// Registra o resultado do envio de erros
  void _logErrorReportingResult(int sentCount, int failedCount, bool success) {
    _loggerProvider?.info(
      'Error reporting completed: $sentCount sent, $failedCount failed',
      category: _tag,
      metadata: {
        'sentCount': sentCount,
        'failedCount': failedCount,
        'success': success,
      },
    );
  }

  /// Remove dados sensíveis do payload
  void _sanitizePayload(Map<String, dynamic> payload) {
    payload.remove('base64Content');
  }

  /// Tenta enviar o payload com retry
  Future<bool> _attemptSendWithRetry(
      Map<String, dynamic> payload, int errorCount) async {
    int retryCount = 0;

    while (retryCount <= _config.maxRetries) {
      try {
        final response =
            await _syncConfig.httpPost(_config.endpoint, data: payload);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _loggerProvider?.debug(
              'Error batch sent successfully ($errorCount errors)',
              category: _tag);
          return true;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.data}');
        }
      } catch (e) {
        retryCount++;

        if (retryCount <= _config.maxRetries) {
          _loggerProvider?.warning(
            'Error batch send failed (attempt $retryCount/${_config.maxRetries}): $e',
            category: _tag,
          );
          await Future.delayed(_config.retryDelay);
        } else {
          _loggerProvider?.error(
            'Error batch send failed after ${_config.maxRetries} retries: $e',
            category: _tag,
            exception: e,
          );
        }
      }
    }

    return false;
  }

  Future<SyncErrorReportResult> _sendErrorBatch(List<SyncError> errors) async {
    final sentErrorIds = <String>[];
    final failedErrorIds = <String>[];

    try {
      final payload = await _createErrorPayload(errors);
      _sanitizePayload(payload);

      final success = await _attemptSendWithRetry(payload, errors.length);

      if (success) {
        sentErrorIds.addAll(errors.map((e) => e.id));
      } else {
        failedErrorIds.addAll(errors.map((e) => e.id));
      }
    } catch (e) {
      _loggerProvider?.error('Failed to send error batch: $e',
          category: _tag, exception: e);
      failedErrorIds.addAll(errors.map((e) => e.id));
    }

    return SyncErrorReportResult(
      success: failedErrorIds.isEmpty,
      sentCount: sentErrorIds.length,
      failedCount: failedErrorIds.length,
      sentErrorIds: sentErrorIds,
      failedErrorIds: failedErrorIds,
    );
  }

  Future<Map<String, dynamic>> _createErrorPayload(
      List<SyncError> errors) async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'errors': errors.map(_createErrorEntry).toList(),
    };
  }

  /// Cria uma entrada de erro simplificada para mobile
  Map<String, dynamic> _createErrorEntry(SyncError error) {
    return {
      'id': error.id,
      'message': error.message,
      'timestamp': error.timestamp.toIso8601String(),
      'category': error.category,
      'entityType': error.entityType,
      'entityId': error.entityId,
    };
  }

  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }

    return batches;
  }
}
