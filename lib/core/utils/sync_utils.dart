import 'dart:convert';
import '../services/sync_error_manager.dart';
import '../config/sync_constants.dart';
import 'package:flutter/foundation.dart';

/// Utilitários para o serviço de sincronização
///
/// Esta classe contém funções auxiliares e utilitárias que podem ser
/// reutilizadas em diferentes partes do sistema de sincronização.
class SyncUtils {
  /// Verifica se o erro é relacionado à conectividade/rede
  ///
  /// [error] O erro a ser analisado
  /// Returns true se o erro for relacionado à rede
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('dio') ||
        errorString.contains('socket') ||
        errorString.contains('host') ||
        errorString.contains('internet');
  }

  /// Calcula o delay para próxima tentativa baseado no número de falhas
  ///
  /// [consecutiveFailures] Número de falhas consecutivas
  /// Returns o delay em segundos
  static int calculateRetryDelay(int consecutiveFailures) {
    return SyncConstants.calculateRetryDelay(consecutiveFailures);
  }

  /// Salva um log de erro global usando o gerenciador de erros interno
  ///
  /// [error] O erro ocorrido
  /// [context] Contexto adicional do erro
  /// [errorManager] Gerenciador de erros interno do sync
  static Future<void> saveGlobalErrorLog({
    required dynamic error,
    required Map<String, dynamic> context,
    required ISyncErrorManager errorManager,
  }) async {
    try {
      await errorManager.logError(
        message: error.toString(),
        stackTrace: error is Exception ? error.toString() : null,
        metadata: {
          'context': context,
          'timestamp': DateTime.now().toIso8601String(),
        },
        category: 'SyncUtils',
        entityType: 'ERROR',
        entityId: 'global',
      );

      debugPrint('Log de erro global salvo: $error');
    } catch (e) {
      debugPrint('Falha ao salvar log de erro global: $e');
    }
  }

  /// Verifica se o sistema pode continuar funcionando sem sincronização
  ///
  /// Returns true se o app pode funcionar offline
  static Future<bool> canContinueWithoutSync() async {
    // O usuário sempre pode continuar usando o app
    // mesmo sem sincronização
    return true;
  }

  /// Determina se deve entrar em modo de recuperação baseado no número de falhas
  ///
  /// [consecutiveFailures] Número de falhas consecutivas
  /// [isNetworkError] Se o erro é relacionado à rede
  /// Returns true se deve entrar em modo de recuperação
  static bool shouldEnterRecoveryMode(
      int consecutiveFailures, bool isNetworkError) {
    if (isNetworkError) {
      // Para erros de rede, ser mais tolerante
      return consecutiveFailures >= (SyncConstants.maxRetryAttempts + 2);
    } else {
      // Para outros erros, entrar em recovery mais cedo
      return consecutiveFailures >= SyncConstants.maxRetryAttempts;
    }
  }

  /// Verifica se atingiu o limite absoluto de falhas
  ///
  /// [consecutiveFailures] Número de falhas consecutivas
  /// Returns true se atingiu o limite absoluto
  static bool hasReachedAbsoluteFailureLimit(int consecutiveFailures) {
    return consecutiveFailures >= SyncConstants.maxAbsoluteFailures;
  }

  /// Gera uma mensagem de status baseada no número de falhas
  ///
  /// [consecutiveFailures] Número de falhas consecutivas
  /// [maxFailures] Número máximo de falhas permitidas
  /// Returns a mensagem de status
  static String generateStatusMessage(
      int consecutiveFailures, int maxFailures) {
    return 'Problemas na sincronização. Tentativa $consecutiveFailures de $maxFailures.';
  }

  /// Valida se os dados de sincronização são válidos
  ///
  /// [data] Dados a serem validados
  /// Returns true se os dados são válidos
  static bool validateSyncData(Map<String, dynamic> data) {
    if (data.isEmpty) return false;

    // Verificações básicas de integridade
    try {
      jsonEncode(data); // Testa se pode ser serializado
      return true;
    } catch (e) {
      debugPrint('Dados de sincronização inválidos: $e');
      return false;
    }
  }

  /// Cria um contexto padrão para logs de erro
  ///
  /// [operation] Operação sendo executada
  /// [additionalContext] Contexto adicional opcional
  /// Returns o contexto formatado
  static Map<String, dynamic> createErrorContext(
    String operation, {
    Map<String, dynamic>? additionalContext,
  }) {
    final context = <String, dynamic>{
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    return context;
  }

  /// Formata uma duração em uma string legível
  ///
  /// [duration] Duração a ser formatada
  /// Returns a duração formatada
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Verifica se uma data está dentro do período de timeout offline
  ///
  /// [date] Data a ser verificada
  /// Returns true se está dentro do timeout
  static bool isWithinOfflineTimeout(DateTime date) {
    final cutoffDate = DateTime.now().subtract(SyncConstants.offlineTimeout);
    return date.isAfter(cutoffDate);
  }

  /// Sanitiza dados sensíveis para logging
  ///
  /// [data] Dados a serem sanitizados
  /// Returns os dados sanitizados
  static Map<String, dynamic> sanitizeDataForLogging(
      Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Lista de campos sensíveis que devem ser mascarados
    const sensitiveFields = [
      'password',
      'token',
      'secret',
      'key',
      'authorization',
      'credential',
      'auth',
    ];

    void sanitizeRecursive(Map<String, dynamic> map) {
      map.forEach((key, value) {
        final lowerKey = key.toLowerCase();

        if (sensitiveFields.any((field) => lowerKey.contains(field))) {
          map[key] = '***MASKED***';
        } else if (value is Map<String, dynamic>) {
          sanitizeRecursive(value);
        } else if (value is List) {
          for (int i = 0; i < value.length; i++) {
            if (value[i] is Map<String, dynamic>) {
              sanitizeRecursive(value[i]);
            }
          }
        }
      });
    }

    sanitizeRecursive(sanitized);
    return sanitized;
  }
}
