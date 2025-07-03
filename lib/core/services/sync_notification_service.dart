import 'package:flutter/foundation.dart';

/// Serviço interno de notificações do Syncly
///
/// Este serviço gerencia todas as notificações relacionadas à sincronização
/// de forma independente, sem depender de implementações externas.
class SyncNotificationService {
  static SyncNotificationService? _instance;
  static SyncNotificationService get instance {
    _instance ??= SyncNotificationService._internal();
    return _instance!;
  }

  SyncNotificationService._internal();

  bool _isEnabled = true;
  bool _isInitialized = false;
  final Map<int, String> _activeNotifications = {};
  int _notificationIdCounter = 1000;

  /// Inicializa o serviço de notificações
  Future<void> initialize({required bool enabled}) async {
    _isEnabled = enabled;
    _isInitialized = true;

    if (_isEnabled) {
      debugPrint('[Syncly] Serviço de notificações inicializado');
    }
  }

  /// Verifica se as notificações estão habilitadas
  bool get isEnabled => _isEnabled && _isInitialized;

  /// Mostra uma notificação simples
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? notificationId,
  }) async {
    if (!isEnabled) return;

    final id = notificationId ?? _generateNotificationId();
    _activeNotifications[id] = title;

    // Para desenvolvimento, apenas log no console
    // Em produção, aqui seria integrado com flutter_local_notifications
    debugPrint('[Syncly Notification] $title: $message');

    // Simular notificação visual no debug
    if (kDebugMode) {
      debugPrint('🔔 [$title] $message');
    }
  }

  /// Mostra uma notificação de progresso
  Future<void> showProgressNotification({
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    int? notificationId,
  }) async {
    if (!isEnabled) return;

    final id = notificationId ?? _generateNotificationId();
    _activeNotifications[id] = title;

    final percentage = ((progress / maxProgress) * 100).round();

    // Para desenvolvimento, apenas log no console
    debugPrint('[Syncly Progress] $title: $message ($percentage%)');

    // Simular notificação de progresso no debug
    if (kDebugMode) {
      final progressBar = _generateProgressBar(progress, maxProgress);
      debugPrint('📊 [$title] $progressBar $percentage% - $message');
    }
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(int notificationId) async {
    if (!isEnabled) return;

    _activeNotifications.remove(notificationId);
    debugPrint('[Syncly] Notificação $notificationId cancelada');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    if (!isEnabled) return;

    final count = _activeNotifications.length;
    _activeNotifications.clear();
    debugPrint('[Syncly] $count notificações canceladas');
  }

  /// Mostra notificação de início de sincronização
  Future<void> showSyncStartedNotification() async {
    await showNotification(
      title: 'Sincronização',
      message: 'Iniciando sincronização de dados...',
      channelId: 'sync_status',
    );
  }

  /// Mostra notificação de sincronização concluída
  Future<void> showSyncCompletedNotification() async {
    await showNotification(
      title: 'Sincronização',
      message: 'Sincronização concluída com sucesso',
      channelId: 'sync_status',
    );
  }

  /// Mostra notificação de erro na sincronização
  Future<void> showSyncErrorNotification(String error) async {
    await showNotification(
      title: 'Erro na Sincronização',
      message: 'Falha ao sincronizar: $error',
      channelId: 'sync_errors',
    );
  }

  /// Mostra notificação de modo offline
  Future<void> showOfflineModeNotification() async {
    await showNotification(
      title: 'Modo Offline',
      message:
          'Aplicativo em modo offline. Dados serão sincronizados quando a conexão for restabelecida.',
      channelId: 'connectivity',
    );
  }

  /// Mostra notificação de volta ao modo online
  Future<void> showOnlineModeNotification() async {
    await showNotification(
      title: 'Conectado',
      message: 'Conexão restabelecida. Iniciando sincronização...',
      channelId: 'connectivity',
    );
  }

  /// Mostra notificação de progresso de download
  Future<void> showDownloadProgressNotification({
    required String fileName,
    required int progress,
    required int total,
    int? notificationId,
  }) async {
    await showProgressNotification(
      title: 'Download',
      message: 'Baixando $fileName...',
      progress: progress,
      maxProgress: total,
      notificationId: notificationId,
    );
  }

  /// Mostra notificação de progresso de upload
  Future<void> showUploadProgressNotification({
    required String fileName,
    required int progress,
    required int total,
    int? notificationId,
  }) async {
    await showProgressNotification(
      title: 'Upload',
      message: 'Enviando $fileName...',
      progress: progress,
      maxProgress: total,
      notificationId: notificationId,
    );
  }

  /// Gera um ID único para notificação
  int _generateNotificationId() {
    return _notificationIdCounter++;
  }

  /// Gera uma barra de progresso visual para debug
  String _generateProgressBar(int progress, int maxProgress,
      {int barLength = 20}) {
    final percentage = progress / maxProgress;
    final filledLength = (percentage * barLength).round();
    final emptyLength = barLength - filledLength;

    return '[${'█' * filledLength}${'░' * emptyLength}]';
  }

  /// Obtém o número de notificações ativas
  int get activeNotificationsCount => _activeNotifications.length;

  /// Obtém a lista de notificações ativas
  Map<int, String> get activeNotifications =>
      Map.unmodifiable(_activeNotifications);

  /// Limpa o serviço (usado para testes)
  void dispose() {
    _activeNotifications.clear();
    _isInitialized = false;
    _notificationIdCounter = 1000;
  }
}
