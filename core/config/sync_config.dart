/// Configurações centralizadas para o serviço de sincronização
///
/// Este arquivo contém todas as configurações relacionadas ao comportamento
/// do sistema de sincronização, incluindo timeouts, intervalos, limites de retry
/// e outras constantes importantes.
class SyncConfig {
  // ========== CONFIGURAÇÕES DE RETRY E FALHAS ==========
  
  /// Número máximo de tentativas de retry por operação individual
  static const int maxRetryAttempts = 3;
  
  /// Número máximo de falhas consecutivas antes de entrar em modo recovery
  static const int maxAbsoluteFailures = 10;
  
  /// Delay base para retry em segundos (usado no cálculo de backoff exponencial)
  static const int baseRetryDelaySeconds = 30;
  
  /// Delay máximo para retry em segundos (8 minutos)
  static const int maxRetryDelaySeconds = 480;
  
  // ========== CONFIGURAÇÕES DE INTERVALOS ==========
  
  /// Intervalo entre sincronizações automáticas
  static const Duration syncInterval = Duration(minutes: 5);
  
  /// Delay inicial antes da primeira sincronização após inicialização
  static const Duration initialSyncDelay = Duration(seconds: 3);
  
  /// Timeout para operações de recovery automático
  static const Duration recoveryTimeout = Duration(minutes: 10);
  
  /// Timeout para modo offline (após este período, dados podem ser limpos)
  static const Duration offlineTimeout = Duration(days: 7);
  
  // ========== CONFIGURAÇÕES DE BACKGROUND SYNC ==========
  
  /// Intervalo mínimo entre execuções de background sync
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  
  /// Frequência de execução do background sync
  static const Duration backgroundSyncFrequency = Duration(hours: 1);
  
  // ========== CONFIGURAÇÕES DE TIMEOUT DE REDE ==========
  
  /// Timeout para operações de download de dados do servidor
  static const Duration downloadTimeout = Duration(seconds: 30);

  /// Timeout para operações de upload de dados para o servidor
  static const Duration uploadTimeout = Duration(minutes: 1);

  /// Timeout para operações de upload de arquivos
  static const Duration fileUploadTimeout = Duration(minutes: 2);
  
  // ========== CONFIGURAÇÕES DE LOTE (BATCH) ==========
  
  /// Tamanho máximo de lote para sincronização de dados regulares
  static const int maxDataBatchSize = 20;

  /// Tamanho máximo de lote para sincronização de arquivos
  static const int maxFileBatchSize = 5;
  
  // ========== CONFIGURAÇÕES DE NOTIFICAÇÃO ==========
  
  /// ID do canal de notificação para sincronização
  static const String notificationChannelId = 'sync_channel';
  
  /// Nome do canal de notificação
  static const String notificationChannelName = 'Sincronização';
  
  /// Descrição do canal de notificação
  static const String notificationChannelDescription = 'Notificações de sincronização de dados';
  
  /// ID da notificação de sincronização
  static const int syncNotificationId = 1001;
  
  /// ID da notificação de progresso
  static const int progressNotificationId = 1002;
  
  /// Duração para auto-remover notificações de sucesso
  static const Duration successNotificationDuration = Duration(seconds: 3);
  
  // ========== CONFIGURAÇÕES DE ENDPOINTS ==========
  
  /// Endpoint para sincronização de dados regulares
  static const String dataSyncEndpoint = '/sync/batch';
  
  /// Endpoint para sincronização de arquivos
  static const String fileSyncEndpoint = '/sync/files';
  
  /// Endpoint para download de dados do servidor
  static const String downloadEndpoint = '/service-order/mobile';
  
  // ========== CONFIGURAÇÕES DE STORAGE ==========
  
  /// Chave para armazenar preferência de background sync
  static const String backgroundSyncPreferenceKey = 'background_sync_enabled';
  
  /// Valor padrão para background sync (ativado por padrão)
  static const bool defaultBackgroundSyncEnabled = true;
  
  // ========== CONFIGURAÇÕES DE WORKMANAGER ==========
  
  /// Nome da tarefa de background sync
  static const String backgroundSyncTaskName = 'background_sync_task';
  
  // ========== MÉTODOS UTILITÁRIOS ==========
  
  /// Calcula o delay de retry usando backoff exponencial
  /// 
  /// [attemptNumber]: Número da tentativa atual (começando em 1)
  /// Retorna o delay em segundos
  static int calculateRetryDelay(int attemptNumber) {
    if (attemptNumber <= 0) return baseRetryDelaySeconds;
    
    // Backoff exponencial: baseDelay * 2^(attempt-1)
    final exponentialDelay = baseRetryDelaySeconds * (1 << (attemptNumber - 1));
    
    // Limitar ao delay máximo
    return exponentialDelay > maxRetryDelaySeconds 
        ? maxRetryDelaySeconds 
        : exponentialDelay;
  }
  
  /// Verifica se o número de falhas consecutivas excede o limite
  static bool shouldEnterRecoveryMode(int consecutiveFailures) {
    return consecutiveFailures >= maxAbsoluteFailures;
  }
  
  /// Verifica se deve fazer retry baseado no número de tentativas
  static bool shouldRetry(int attemptCount) {
    return attemptCount < maxRetryAttempts;
  }
  
  /// Retorna o timeout apropriado baseado no tipo de operação
  static Duration getTimeoutForOperation(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'download':
        return downloadTimeout;
      case 'upload':
        return uploadTimeout;
      case 'file_upload':
        return fileUploadTimeout;
      default:
        return uploadTimeout; // Default para operações de upload
    }
  }
}