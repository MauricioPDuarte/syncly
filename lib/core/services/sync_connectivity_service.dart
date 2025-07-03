import 'dart:async';
import 'dart:io';
import '../entities/sync_connectivity_status.dart';
import '../enums/sync_connectivity_type.dart';
import '../utils/sync_utils.dart';

abstract class ISyncConnectivityService {
  Future<bool> isConnected();
  Future<SyncConnectivityStatus> getConnectivityStatus();
  Stream<SyncConnectivityStatus> get connectivityStream;
  Stream<bool> get isConnectedStream;
  Future<bool> isSuitableForSync();
  Future<bool> isWifiConnected();
  Future<bool> isMobileConnected();
  Future<bool> testInternetConnectivity({
    String? testUrl,
    Duration? timeout,
  });
  Future<Map<String, dynamic>> getNetworkInfo();
  void setTestUrls(List<String> urls);
  void setWifiOnlyMode(bool wifiOnly);
  bool get isWifiOnlyMode;
}

/// Implementação simples de conectividade para o sistema de sincronização
/// Não depende de serviços externos
class SyncConnectivityService implements ISyncConnectivityService {
  final StreamController<SyncConnectivityStatus> _statusController =
      StreamController<SyncConnectivityStatus>.broadcast();
  final StreamController<bool> _isConnectedController =
      StreamController<bool>.broadcast();

  bool _wifiOnlyMode = false;
  List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    'https://1.1.1.1',
  ];

  Timer? _connectivityTimer;
  SyncConnectivityStatus? _lastStatus;

  SyncConnectivityService() {
    _startConnectivityMonitoring();
  }

  void _startConnectivityMonitoring() {
    // Monitora conectividade a cada 30 segundos
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkAndUpdateConnectivity();
    });

    // Verifica conectividade inicial
    _checkAndUpdateConnectivity();
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final status = await getConnectivityStatus();

      // Só emite se o status mudou
      if (_lastStatus == null || _lastStatus != status) {
        _lastStatus = status;
        _statusController.add(status);
        _isConnectedController.add(status.isConnected);
      }
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar conectividade: $e',
          tag: 'SyncConnectivityService');
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      return await testInternetConnectivity(
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar conectividade: $e',
          tag: 'SyncConnectivityService');
      return false;
    }
  }

  @override
  Future<SyncConnectivityStatus> getConnectivityStatus() async {
    try {
      final isConnected = await this.isConnected();

      if (!isConnected) {
        return const SyncConnectivityStatus(
          isConnected: false,
          type: SyncConnectivityType.none,
        );
      }

      final type = _detectConnectionType();

      return SyncConnectivityStatus(
        isConnected: true,
        type: type,
        networkName: _getNetworkName(type),
        signalStrength: _getSignalStrength(type),
      );
    } catch (e) {
      SyncUtils.debugLog('Erro ao obter status de conectividade: $e',
          tag: 'SyncConnectivityService');
      return const SyncConnectivityStatus(
        isConnected: false,
        type: SyncConnectivityType.none,
      );
    }
  }

  SyncConnectivityType _detectConnectionType() {
    try {
      // Implementação básica baseada na plataforma
      if (Platform.isAndroid || Platform.isIOS) {
        // Em dispositivos móveis, assume conexão móvel por padrão
        // Pode ser refinado com connectivity_plus se necessário
        return SyncConnectivityType.mobile;
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return SyncConnectivityType.ethernet;
      }
      return SyncConnectivityType.other;
    } catch (e) {
      SyncUtils.debugLog('Erro ao detectar tipo de conexão: $e',
          tag: 'SyncConnectivityService');
      return SyncConnectivityType.other;
    }
  }

  String? _getNetworkName(SyncConnectivityType type) {
    switch (type) {
      case SyncConnectivityType.wifi:
        return 'Wi-Fi Network';
      case SyncConnectivityType.mobile:
        return 'Mobile Data';
      case SyncConnectivityType.ethernet:
        return 'Ethernet';
      default:
        return null;
    }
  }

  double? _getSignalStrength(SyncConnectivityType type) {
    // Implementação básica - retorna força simulada
    // Pode ser melhorada com plugins específicos para obter força real do sinal
    switch (type) {
      case SyncConnectivityType.wifi:
      case SyncConnectivityType.ethernet:
        return 0.8; // Assume boa conexão para Wi-Fi/Ethernet
      case SyncConnectivityType.mobile:
        return 0.6; // Assume conexão moderada para dados móveis
      default:
        return null;
    }
  }

  @override
  Stream<SyncConnectivityStatus> get connectivityStream =>
      _statusController.stream;

  @override
  Stream<bool> get isConnectedStream => _isConnectedController.stream;

  @override
  Future<bool> isSuitableForSync() async {
    try {
      final status = await getConnectivityStatus();

      if (!status.isConnected) {
        return false;
      }

      // Se está no modo apenas Wi-Fi, verifica se é Wi-Fi
      if (_wifiOnlyMode && !status.isWifi) {
        return false;
      }

      // Verifica força do sinal se disponível
      if (status.signalStrength != null && status.signalStrength! < 0.3) {
        return false;
      }

      return true;
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar adequação para sync: $e',
          tag: 'SyncConnectivityService');
      return false;
    }
  }

  @override
  Future<bool> isWifiConnected() async {
    try {
      final status = await getConnectivityStatus();
      return status.isWifi;
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar conexão Wi-Fi: $e',
          tag: 'SyncConnectivityService');
      return false;
    }
  }

  @override
  Future<bool> isMobileConnected() async {
    try {
      final status = await getConnectivityStatus();
      return status.isMobile;
    } catch (e) {
      SyncUtils.debugLog('Erro ao verificar conexão móvel: $e',
          tag: 'SyncConnectivityService');
      return false;
    }
  }

  @override
  Future<bool> testInternetConnectivity({
    String? testUrl,
    Duration? timeout,
  }) async {
    try {
      final url = testUrl ?? _testUrls.first;
      final timeoutDuration = timeout ?? const Duration(seconds: 10);

      final client = HttpClient();
      client.connectionTimeout = timeoutDuration;

      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(timeoutDuration);

        final hasInternet = response.statusCode == 200;
        client.close();

        return hasInternet;
      } catch (e) {
        client.close();
        return false;
      }
    } catch (e) {
      SyncUtils.debugLog('Erro ao testar conectividade com internet: $e',
          tag: 'SyncConnectivityService');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final status = await getConnectivityStatus();

      return {
        'isConnected': status.isConnected,
        'type': status.type.name,
        'networkName': status.networkName,
        'signalStrength': status.signalStrength,
        'wifiOnlyMode': _wifiOnlyMode,
        'testUrls': _testUrls,
        'isSuitableForSync': await isSuitableForSync(),
      };
    } catch (e) {
      SyncUtils.debugLog('Erro ao obter informações da rede: $e',
          tag: 'SyncConnectivityService');
      return {
        'isConnected': false,
        'type': 'none',
        'error': e.toString(),
      };
    }
  }

  @override
  void setTestUrls(List<String> urls) {
    _testUrls = List<String>.from(urls);
  }

  @override
  void setWifiOnlyMode(bool wifiOnly) {
    _wifiOnlyMode = wifiOnly;
  }

  @override
  bool get isWifiOnlyMode => _wifiOnlyMode;

  /// Dispõe dos recursos do provider
  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
    _isConnectedController.close();
  }

  /// Força uma verificação imediata de conectividade
  Future<void> forceConnectivityCheck() async {
    await _checkAndUpdateConnectivity();
  }

  /// Configura o intervalo de monitoramento de conectividade
  void setMonitoringInterval(Duration interval) {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(interval, (_) async {
      await _checkAndUpdateConnectivity();
    });
  }
}
