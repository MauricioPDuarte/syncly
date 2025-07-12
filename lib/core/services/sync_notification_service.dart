import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  
  // Canais de notificação
  static const String _syncStatusChannelId = 'sync_status';
  static const String _syncErrorsChannelId = 'sync_errors';
  static const String _connectivityChannelId = 'connectivity';
  static const String _progressChannelId = 'progress';

  /// Inicializa o serviço de notificações
  Future<void> initialize({required bool enabled}) async {
    _isEnabled = enabled;
    
    if (_isEnabled) {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      // Configurações para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configurações para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      
      // Criar canais de notificação para Android
      await _createNotificationChannels();
      
      debugPrint('[Syncly] Serviço de notificações inicializado com flutter_local_notifications');
    }
    
    _isInitialized = true;
  }

  /// Cria os canais de notificação para Android
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        _syncStatusChannelId,
        'Status da Sincronização',
        description: 'Notificações sobre o status da sincronização de dados',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _syncErrorsChannelId,
        'Erros de Sincronização',
        description: 'Notificações sobre erros durante a sincronização',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _connectivityChannelId,
        'Conectividade',
        description: 'Notificações sobre mudanças na conectividade',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _progressChannelId,
        'Progresso',
        description: 'Notificações de progresso de download e upload',
        importance: Importance.low,
        showBadge: false,
      ),
    ];
    
    for (final channel in channels) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
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
    final channel = channelId ?? _syncStatusChannelId;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _syncStatusChannelId,
        'Status da Sincronização',
        channelDescription: 'Notificações sobre o status da sincronização de dados',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        platformChannelSpecifics,
      );
      
      debugPrint('[Syncly] Notificação exibida: $title - $message');
    } catch (e) {
      debugPrint('[Syncly] Erro ao exibir notificação: $e');
      // Fallback para debug print
      if (kDebugMode) {
        debugPrint('🔔 [$title] $message');
      }
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

    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _progressChannelId,
        'Progresso',
        channelDescription: 'Notificações de progresso de download e upload',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        onlyAlertOnce: true,
        showWhen: false,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        '$message ($percentage%)',
        platformChannelSpecifics,
      );
      
      debugPrint('[Syncly] Notificação de progresso: $title - $percentage%');
    } catch (e) {
      debugPrint('[Syncly] Erro ao exibir notificação de progresso: $e');
      // Fallback para debug print
      if (kDebugMode) {
        final progressBar = _generateProgressBar(progress, maxProgress);
        debugPrint('📊 [$title] $progressBar $percentage% - $message');
      }
    }
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(int notificationId) async {
    if (!isEnabled) return;

    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      _activeNotifications.remove(notificationId);
      debugPrint('[Syncly] Notificação $notificationId cancelada');
    } catch (e) {
      debugPrint('[Syncly] Erro ao cancelar notificação $notificationId: $e');
    }
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    if (!isEnabled) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      final count = _activeNotifications.length;
      _activeNotifications.clear();
      debugPrint('[Syncly] $count notificações canceladas');
    } catch (e) {
      debugPrint('[Syncly] Erro ao cancelar todas as notificações: $e');
    }
  }

  /// Mostra notificação de início de sincronização
  Future<void> showSyncStartedNotification() async {
    await showNotification(
      title: 'Sincronização',
      message: 'Iniciando sincronização de dados...',
      channelId: _syncStatusChannelId,
    );
  }

  /// Mostra notificação de sincronização concluída
  Future<void> showSyncCompletedNotification() async {
    await showNotification(
      title: 'Sincronização',
      message: 'Sincronização concluída com sucesso',
      channelId: _syncStatusChannelId,
    );
  }

  /// Mostra notificação de erro na sincronização
  Future<void> showSyncErrorNotification(String error) async {
    await _showErrorNotification(
      title: 'Erro na Sincronização',
      message: 'Falha ao sincronizar: $error',
    );
  }

  /// Mostra notificação de modo offline
  Future<void> showOfflineModeNotification() async {
    await _showConnectivityNotification(
      title: 'Modo Offline',
      message: 'Aplicativo em modo offline. Dados serão sincronizados quando a conexão for restabelecida.',
    );
  }

  /// Mostra notificação de volta ao modo online
  Future<void> showOnlineModeNotification() async {
    await _showConnectivityNotification(
      title: 'Conectado',
      message: 'Conexão restabelecida. Iniciando sincronização...',
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

  /// Mostra notificação de erro com canal específico
  Future<void> _showErrorNotification({
    required String title,
    required String message,
    int? notificationId,
  }) async {
    if (!isEnabled) return;

    final id = notificationId ?? _generateNotificationId();
    _activeNotifications[id] = title;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _syncErrorsChannelId,
        'Erros de Sincronização',
        channelDescription: 'Notificações sobre erros durante a sincronização',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        platformChannelSpecifics,
      );
      
      debugPrint('[Syncly] Notificação de erro exibida: $title - $message');
    } catch (e) {
      debugPrint('[Syncly] Erro ao exibir notificação de erro: $e');
      if (kDebugMode) {
        debugPrint('❌ [$title] $message');
      }
    }
  }

  /// Mostra notificação de conectividade com canal específico
  Future<void> _showConnectivityNotification({
    required String title,
    required String message,
    int? notificationId,
  }) async {
    if (!isEnabled) return;

    final id = notificationId ?? _generateNotificationId();
    _activeNotifications[id] = title;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        _connectivityChannelId,
        'Conectividade',
        channelDescription: 'Notificações sobre mudanças na conectividade',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        message,
        platformChannelSpecifics,
      );
      
      debugPrint('[Syncly] Notificação de conectividade exibida: $title - $message');
    } catch (e) {
      debugPrint('[Syncly] Erro ao exibir notificação de conectividade: $e');
      if (kDebugMode) {
        debugPrint('🌐 [$title] $message');
      }
    }
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
    if (_isEnabled && _isInitialized) {
      cancelAllNotifications();
    }
    _activeNotifications.clear();
    _isInitialized = false;
    _notificationIdCounter = 1000;
  }
}
