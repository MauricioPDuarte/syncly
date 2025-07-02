import 'dart:convert';
import '../entities/sync_error.dart';
import 'package:uuid/uuid.dart';
import '../interfaces/i_storage_provider.dart';
import '../interfaces/i_logger_debug_provider.dart';

/// Interface para gerenciamento de erros de sincronização
abstract class ISyncErrorManager {
  Future<void> logError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    String? category,
    String? entityType,
    String? entityId,
  });

  Future<List<SyncError>> getPendingErrors();
  Future<List<SyncError>> getAllErrors();
  Future<void> markErrorAsSent(String errorId);
  Future<void> clearSentErrors();
  Future<void> clearAllErrors();
  Future<void> removeError(String errorId);
}

/// Implementação interna do gerenciador de erros de sincronização
class SyncErrorManager implements ISyncErrorManager {
  static const String _errorsKey = 'sync_errors';
  static const String _errorPrefix = 'sync_error_';

  final IStorageProvider _storageProvider;
  final ISyncLoggerDebugProvider? _loggerProvider;
  final Uuid _uuid = const Uuid();

  SyncErrorManager(this._storageProvider, this._loggerProvider);

  @override
  Future<void> logError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    String? category,
    String? entityType,
    String? entityId,
  }) async {
    try {
      final error = SyncError(
        id: _uuid.v4(),
        message: message,
        stackTrace: stackTrace,
        metadata: metadata,
        timestamp: DateTime.now(),
        category: category,
        entityType: entityType,
        entityId: entityId,
      );

      await _saveError(error);

      _loggerProvider?.error(
        'Error logged: $message',
        category: category ?? 'SyncErrorManager',
        metadata: metadata,
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to log error: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
  }

  @override
  Future<List<SyncError>> getPendingErrors() async {
    try {
      final allErrors = await getAllErrors();
      return allErrors.where((error) => !error.isSent).toList();
    } catch (e) {
      _loggerProvider?.error(
        'Failed to get pending errors: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
      return [];
    }
  }

  @override
  Future<List<SyncError>> getAllErrors() async {
    try {
      final errorIds = await _getErrorIds();
      final errors = <SyncError>[];

      for (final errorId in errorIds) {
        final error = await _getError(errorId);
        if (error != null) {
          errors.add(error);
        }
      }

      // Ordenar por timestamp (mais recentes primeiro)
      errors.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return errors;
    } catch (e) {
      _loggerProvider?.error(
        'Failed to get all errors: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
      return [];
    }
  }

  @override
  Future<void> markErrorAsSent(String errorId) async {
    try {
      final error = await _getError(errorId);
      if (error != null) {
        final updatedError = error.copyWith(isSent: true);
        await _saveError(updatedError);

        _loggerProvider?.info(
          'Error marked as sent: $errorId',
          category: 'SyncErrorManager',
        );
      }
    } catch (e) {
      _loggerProvider?.error(
        'Failed to mark error as sent: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
  }

  @override
  Future<void> clearSentErrors() async {
    try {
      final allErrors = await getAllErrors();
      final sentErrors = allErrors.where((error) => error.isSent);

      for (final error in sentErrors) {
        await removeError(error.id);
      }

      _loggerProvider?.info(
        'Cleared ${sentErrors.length} sent errors',
        category: 'SyncErrorManager',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear sent errors: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
  }

  @override
  Future<void> clearAllErrors() async {
    try {
      final errorIds = await _getErrorIds();

      for (final errorId in errorIds) {
        await _storageProvider.remove('$_errorPrefix$errorId');
      }

      await _storageProvider.remove(_errorsKey);

      _loggerProvider?.info(
        'Cleared all errors (${errorIds.length} errors)',
        category: 'SyncErrorManager',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to clear all errors: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
  }

  @override
  Future<void> removeError(String errorId) async {
    try {
      await _storageProvider.remove('$_errorPrefix$errorId');

      // Remover da lista de IDs
      final errorIds = await _getErrorIds();
      errorIds.remove(errorId);
      await _saveErrorIds(errorIds);

      _loggerProvider?.info(
        'Error removed: $errorId',
        category: 'SyncErrorManager',
      );
    } catch (e) {
      _loggerProvider?.error(
        'Failed to remove error: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
  }

  // Métodos privados para gerenciamento de storage

  Future<void> _saveError(SyncError error) async {
    await _storageProvider.store(
        '$_errorPrefix${error.id}', jsonEncode(error.toJson()));

    // Adicionar à lista de IDs se não existir
    final errorIds = await _getErrorIds();
    if (!errorIds.contains(error.id)) {
      errorIds.add(error.id);
      await _saveErrorIds(errorIds);
    }
  }

  Future<SyncError?> _getError(String errorId) async {
    try {
      final errorData =
          await _storageProvider.retrieve('$_errorPrefix$errorId');
      if (errorData != null) {
        return SyncError.fromJson(jsonDecode(errorData));
      }
    } catch (e) {
      _loggerProvider?.error(
        'Failed to get error $errorId: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
    return null;
  }

  Future<List<String>> _getErrorIds() async {
    try {
      final idsData = await _storageProvider.retrieve(_errorsKey);
      if (idsData != null) {
        final List<dynamic> idsList = jsonDecode(idsData);
        return idsList.cast<String>();
      }
    } catch (e) {
      _loggerProvider?.error(
        'Failed to get error IDs: $e',
        category: 'SyncErrorManager',
        exception: e,
      );
    }
    return [];
  }

  Future<void> _saveErrorIds(List<String> errorIds) async {
    await _storageProvider.store(_errorsKey, jsonEncode(errorIds));
  }
}
