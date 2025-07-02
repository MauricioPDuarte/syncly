import '../entities/sync_error.dart';
import '../../sync_config.dart';
import '../interfaces/i_logger_debug_provider.dart';
import 'sync_error_manager.dart';

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
}

/// Interface para envio de erros para o backend
abstract class ISyncErrorReporter {
  Future<SyncErrorReportResult> sendPendingErrors();
  Future<SyncErrorReportResult> sendError(SyncError error);
  Future<SyncErrorReportResult> sendErrors(List<SyncError> errors);
  Future<void> scheduleErrorReporting();
}

/// Implementação do serviço de envio de erros para o backend
class SyncErrorReporter implements ISyncErrorReporter {
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
        _loggerProvider?.info(
          'No pending errors to send',
          category: 'SyncErrorReporter',
        );
        return const SyncErrorReportResult(
          success: true,
          sentCount: 0,
          failedCount: 0,
          sentErrorIds: [],
          failedErrorIds: [],
        );
      }

      return await sendErrors(pendingErrors);
    } catch (e) {
      _loggerProvider?.error(
        'Failed to send pending errors: $e',
        category: 'SyncErrorReporter',
        exception: e,
      );

      return SyncErrorReportResult(
        success: false,
        sentCount: 0,
        failedCount: 0,
        sentErrorIds: const [],
        failedErrorIds: const [],
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
      return const SyncErrorReportResult(
        success: true,
        sentCount: 0,
        failedCount: 0,
        sentErrorIds: [],
        failedErrorIds: [],
      );
    }

    final sentErrorIds = <String>[];
    final failedErrorIds = <String>[];

    try {
      // Verificar autenticação
      final isAuthenticated = await _syncConfig.isAuthenticated();
      if (!isAuthenticated) {
        _loggerProvider?.warning(
          'Cannot send errors: user not authenticated',
          category: 'SyncErrorReporter',
        );

        return SyncErrorReportResult(
          success: false,
          sentCount: 0,
          failedCount: errors.length,
          sentErrorIds: const [],
          failedErrorIds: errors.map((e) => e.id).toList(),
          errorMessage: 'User not authenticated',
        );
      }

      // Processar erros em lotes
      final batches = _createBatches(errors, _config.batchSize);

      for (final batch in batches) {
        final result = await _sendErrorBatch(batch);
        sentErrorIds.addAll(result.sentErrorIds);
        failedErrorIds.addAll(result.failedErrorIds);
      }

      // Marcar erros enviados como enviados
      for (final errorId in sentErrorIds) {
        await _errorManager.markErrorAsSent(errorId);
      }

      final success = failedErrorIds.isEmpty;

      _loggerProvider?.info(
        'Error reporting completed: ${sentErrorIds.length} sent, ${failedErrorIds.length} failed',
        category: 'SyncErrorReporter',
        metadata: {
          'sentCount': sentErrorIds.length,
          'failedCount': failedErrorIds.length,
          'success': success,
        },
      );

      return SyncErrorReportResult(
        success: success,
        sentCount: sentErrorIds.length,
        failedCount: failedErrorIds.length,
        sentErrorIds: sentErrorIds,
        failedErrorIds: failedErrorIds,
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to send errors: $e',
        category: 'SyncErrorReporter',
        exception: e,
      );

      return SyncErrorReportResult(
        success: false,
        sentCount: sentErrorIds.length,
        failedCount: errors.length - sentErrorIds.length,
        sentErrorIds: sentErrorIds,
        failedErrorIds: errors
            .map((e) => e.id)
            .where((id) => !sentErrorIds.contains(id))
            .toList(),
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> scheduleErrorReporting() async {
    try {
      // Implementação simples - em uma implementação real, isso poderia usar um timer ou scheduler
      await sendPendingErrors();

      _loggerProvider?.info(
        'Error reporting scheduled and executed',
        category: 'SyncErrorReporter',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to schedule error reporting: $e',
        category: 'SyncErrorReporter',
        exception: e,
      );
    }
  }

  // Métodos privados

  Future<SyncErrorReportResult> _sendErrorBatch(List<SyncError> errors) async {
    final sentErrorIds = <String>[];
    final failedErrorIds = <String>[];

    try {
      final payload = await _createErrorPayload(errors);

      int retryCount = 0;
      bool success = false;

      while (retryCount <= _config.maxRetries && !success) {
        try {
          final response = await _syncConfig.httpPost(
            _config.endpoint,
            data: payload,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            success = true;
            sentErrorIds.addAll(errors.map((e) => e.id));

            _loggerProvider?.debug(
              'Error batch sent successfully (${errors.length} errors)',
              category: 'SyncErrorReporter',
            );
          } else {
            throw Exception('HTTP ${response.statusCode}: ${response.data}');
          }
        } catch (e) {
          retryCount++;

          if (retryCount <= _config.maxRetries) {
            _loggerProvider?.warning(
              'Error batch send failed (attempt $retryCount/${_config.maxRetries}): $e',
              category: 'SyncErrorReporter',
            );

            await Future.delayed(_config.retryDelay);
          } else {
            _loggerProvider?.error(
              'Error batch send failed after ${_config.maxRetries} retries: $e',
              category: 'SyncErrorReporter',
              exception: e,
            );

            failedErrorIds.addAll(errors.map((e) => e.id));
          }
        }
      }
    } catch (e) {
      _loggerProvider?.error(
        'Failed to send error batch: $e',
        category: 'SyncErrorReporter',
        exception: e,
      );

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
    final userId = await _syncConfig.getCurrentUserId();

    return {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'errors': errors
          .map((error) => {
                'id': error.id,
                'message': error.message,
                if (_config.includeStackTrace && error.stackTrace != null)
                  'stackTrace': error.stackTrace,
                if (_config.includeMetadata && error.metadata != null)
                  'metadata': error.metadata,
                'timestamp': error.timestamp.toIso8601String(),
                'category': error.category,
                'entityType': error.entityType,
                'entityId': error.entityId,
              })
          .toList(),
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
