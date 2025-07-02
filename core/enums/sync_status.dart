/// Status de sincronização do sistema
///
/// Estados possíveis:
/// - [idle]: Sistema inativo, aguardando próxima sincronização
/// - [syncing]: Sincronização em andamento
/// - [success]: Última sincronização foi bem-sucedida
/// - [error]: Erro na sincronização, aguardando retry
/// - [offline]: Sem conexão com internet
/// - [degraded]: Funcionando com limitações (modo offline)
/// - [recovery]: Tentando recuperar de erro automaticamente
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
  degraded,
  recovery,
}