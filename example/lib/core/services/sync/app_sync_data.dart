/// Status de sincronização da aplicação
///
/// Estados possíveis:
/// - [idle]: Sistema inativo, aguardando próxima sincronização
/// - [syncing]: Sincronização em andamento
/// - [success]: Última sincronização foi bem-sucedida
/// - [error]: Erro na sincronização, aguardando retry
/// - [offline]: Sem conexão com internet
/// - [degraded]: Funcionando com limitações (modo offline)
/// - [recovery]: Tentando recuperar de erro automaticamente
enum AppSyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
  degraded,
  recovery,
}

/// Dados de sincronização da aplicação
///
/// Contém informações sobre:
/// - Status atual da sincronização
/// - Mensagem descritiva do estado
/// - Timestamp da última sincronização bem-sucedida
/// - Número de itens pendentes para sincronização
class AppSyncData {
  final AppSyncStatus status;
  final String? message;
  final DateTime? lastSync;
  final int? pendingItems;

  const AppSyncData({
    required this.status,
    this.message,
    this.lastSync,
    this.pendingItems,
  });

  /// Cria uma nova instância com os valores alterados
  AppSyncData copyWith({
    AppSyncStatus? status,
    String? message,
    DateTime? lastSync,
    int? pendingItems,
  }) {
    return AppSyncData(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSync: lastSync ?? this.lastSync,
      pendingItems: pendingItems ?? this.pendingItems,
    );
  }

  @override
  String toString() {
    return 'AppSyncData(status: $status, message: $message, lastSync: $lastSync, pendingItems: $pendingItems)';
  }
}