import '../enums/sync_status.dart';

/// Dados de sincronização que representam o estado atual do sistema
///
/// Contém informações sobre:
/// - Status atual da sincronização
/// - Mensagem descritiva do estado
/// - Timestamp da última sincronização bem-sucedida
/// - Número de itens pendentes para sincronização
class SyncData {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSync;
  final int? pendingItems;

  const SyncData({
    required this.status,
    this.message,
    this.lastSync,
    this.pendingItems,
  });

  /// Cria uma nova instância com os valores alterados
  SyncData copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSync,
    int? pendingItems,
  }) {
    return SyncData(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSync: lastSync ?? this.lastSync,
      pendingItems: pendingItems ?? this.pendingItems,
    );
  }

  @override
  String toString() {
    return 'SyncData(status: $status, message: $message, lastSync: $lastSync, pendingItems: $pendingItems)';
  }
}
